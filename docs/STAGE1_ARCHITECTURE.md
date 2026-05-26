# Stage 1: Multi-space on a shared MORK trie (single-node)

**Status**: Shipped 2026-05-26. Ships with the architecture **in place but
dormant** — `bind!` records prefix metadata but every `CoreSpace` still
gets its own MORK trie (the canonical isolation that PeTTa /
hyperon-experimental / CeTTa / MORK all use). Stage 2 flips the polarity.

This document captures the model so the next session knows what's wired,
what's recorded, and what's deferred.

---

## The whitepaper view (Hyperon WP §9, Figure 4)

A node hosts **one common atomspace** for shared cross-domain knowledge
and **per-app atomspaces** for domain data:

```
                 ┌───────────────┐
                 │   common:/    │  ← shared knowledge (PLN, ECAN, …)
                 ├───────────────┤
                 │ app/games:/   │  ← per-app domain data
                 │ app/social:/  │
                 │ app/bio:/     │
                 │ app/math:/    │
                 └───────────────┘
              (one node, one trie, byte-prefix regions)
```

The whitepaper does not say "one MORK.Space per atomspace." It says
"one atomspace per role." Stage 1 implements that as byte-prefix regions
in a single trie.

## What Stage 1 actually ships

### Data model

`CoreSpace` now carries a prefix:

```julia
mutable struct CoreSpace
    inner            :: Space            # the shared trie (or its own, in C-mode)
    prefix           :: Vector{UInt8}    # byte-region scope; empty = root
    rule_cache       :: Dict{Symbol, Vector{Tuple{Vector{Any}, Any}}}
    named_spaces     :: Dict{Symbol, CoreSpace}
    use_supercompiler:: Bool
end
```

- `new_core_space()` → `(fresh Space, empty prefix)` — canonical isolation.
  Existing callers see no change.
- `new_core_space(shared::Space, prefix::Vector{UInt8})` → `(shared trie,
  scoped prefix)`. Atoms operations route through `prefix ++ atom_bytes`.

### Node-level registries

Both are process-globals, lazy-initialized:

| Registry           | Type                                     | Purpose                                          |
| ------------------ | ---------------------------------------- | ------------------------------------------------ |
| `NODE_SHARED`      | `Ref{Union{Space, Nothing}}`             | The one MORK trie for all named-and-bound spaces |
| `PREFIX_REGISTRY`  | `Dict{Symbol, Vector{UInt8}}`            | `:&common → b"common:/"`, etc.                   |
| `NODE_STATUS_MAP`  | `Ref{Any}` (lazy `StatusMap`)            | Per-prefix read/write permits for concurrency    |

`derive_prefix_from_name(:&app/games)` → `b"app/games:/"`. The trailing `:/`
guarantees `prefix_compare` returns `DISJOINT` for any two distinct
sibling names — including the `app:/` vs `app/games:/` case.

### Atom operations under a prefix

All six space ops respect `s.prefix`:

| Operation          | Empty-prefix (root)                  | Non-empty-prefix                                                  |
| ------------------ | ------------------------------------ | ----------------------------------------------------------------- |
| `core_add!`        | `space_add_all_sexpr!` (fast path)   | `set_val_at!(btm, prefix ++ atom_bytes, UNIT_VAL)`                |
| `core_remove!`     | `remove_val_at!(btm, atom_bytes)`    | `remove_val_at!(btm, prefix ++ atom_bytes)`                       |
| `core_match`       | trie-walk + `_shape_match` filter    | `read_zipper_at_path` + filter (paths relative to anchor)         |
| `core_rules`       | trie-walk + head-shape filter        | `read_zipper_at_path` + filter                                    |
| `core_atoms`       | `space_dump_all_sexpr` (fast path)   | `read_zipper_at_path` + serialize                                 |
| `core_calculus!`   | `space_metta_calculus!`              | **Errors** — needs upstream `space_metta_calculus_in_prefix!`     |

### Concurrency: StatusMap permits

`with_read_permit(s)` and `with_write_permit(s)` wrap each space op.
Empty-prefix is a no-op (root has no isolation). Non-empty prefixes acquire
permits from `NODE_STATUS_MAP` — two CoreSpaces whose prefixes are
`DISJOINT` per `prefix_compare` run concurrently; overlapping prefixes
serialize.

Stage 1 single-threaded use never trips the permit denial path. The
machinery is there for Stage 2 + future MPI / Distributed.jl workers.

### `.act` lifecycle (single-node durability)

`CoreSpaceActIO.jl` implements:

```julia
set_act_dir!(dir)
snapshot_space_to_act!(s, name)  →  Bool  (writes <dir>/<name>.act)
load_act_source(name)            →  (ACTSource, mmaps cache)
act_exists(name)                 →  Bool
open_node!(act_dir=…, common_name="common")    # startup convenience
close_node!(s; name="common")                  # shutdown convenience
```

Implementation note that bit me once and is documented in the file:
`act_from_zipper(m, …)` takes a **PathMap**, not a ReadZipper. The save
path materializes a temp PathMap from the prefix region first
(`read_zipper_at_path` + `set_val_at!`), then hands it to `act_from_zipper`.

## What ships **dormant** (Stage 2 work)

### `(bind! &name (new-space))` — C-mode semantics

Today: registers `:&name → derived_prefix` in `PREFIX_REGISTRY` as
**metadata** and stores the bound `CoreSpace` in `space.named_spaces`. The
bound CoreSpace keeps its own MORK trie (canonical PeTTa / hyperon-experimental
behavior). The byte-prefix machinery does not fire from user-facing MeTTa.

Why dormant: `rebind_to_shared_prefix(src, prefix)` is wired but not
invoked from `_eval_bind!`. Initial SMOKE testing surfaced a `pz_path`
relative-vs-absolute question in MORK's `space_query_multi_at`, and
the conservative ship was "infrastructure-in-place, polarity-off."

### `core_calculus!` on prefixed spaces

Needs `space_metta_calculus_in_prefix!` in upstream `sivaji1012/MORK` —
exists in our local `packages/MORK/` but not in the published repo. The
function composes `space_prefix ++ _EXEC_PREFIX` internally (keeping
`_EXEC_PREFIX` private).

### Stage 2 = three flips

1. Land `space_metta_calculus_in_prefix!` + `space_query_multi_at` in
   `sivaji1012/MORK`.
2. Decide on `pz_path` semantics for the prefix-scoped ProductZipper case
   (relative vs absolute), update `_walk_atoms` if needed.
3. Uncomment the `rebind_to_shared_prefix` call in `_eval_bind!`.

After step 3, `(bind! &common (new-space))` materializes a shared-trie
prefix region. The 5 prefix tests (testset 27-31) already exercise the
direct constructor path — they'll keep passing.

## Where this came from (cross-check)

| Runtime               | Multi-space model                                              |
| --------------------- | -------------------------------------------------------------- |
| PeTTa                 | One namespace, atomspaces are explicit list values             |
| hyperon-experimental  | `&self` per module + parent-chain; new spaces are own storage  |
| CeTTa                 | Heterogeneous `SpaceKind` (Stack/Queue/Hash/PathMap)            |
| MORK                  | One `Space` per process; bring-your-own-API for partitioning   |
| **Core (Stage 1)**    | **Shared trie + byte-prefix; mirrors Hyperon WP §9 Figure 4**  |

The "shared trie + byte-prefix" approach is novel relative to the others.
Closest precedent is CeTTa's `SpaceKind` heterogeneity, but byte-prefix
co-residence in one trie is the actual whitepaper-faithful model.

## Acceptance criteria (all met)

- 94/94 pre-Stage-1 tests still pass (no regression on user-facing
  MeTTa semantics, including the SMOKE-1 fix to `core_match` /
  `core_rules`).
- 22 new Stage 1 assertions covering disjoint prefixes, cross-prefix
  match isolation, `with-space` save-and-restore, `.act` round-trip,
  read-your-writes — testsets 27-31, **116/116** total.
- Stage 1 ships dormant: no behavioral change for any existing caller
  that goes through `new_core_space()` + `bind!`.
- Stage 2 is one polarity flip + three upstream MORK exports away.

## Companion docs

- `SEMANTIC_DELTA.md` — Core vs PRIMUS_Core MeTTa semantic differences
- `ATOM_TYPING_TRADEOFF.md` — Why `Vector{Any}` is deferred until structural
  trie matching lands in upstream MORK
