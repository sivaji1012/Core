# Streaming `=` — resume notes for this branch

> This branch is `prototype/stream-eval-and-alpha`. It is parked, **local-only**,
> and was the falsifying experiment for the streaming-`=` shape. The hygiene fix
> (`4b2033f`) and the eager-evaluator lock-in (`ea79fcd`) landed on `main` after
> this branch was parked, on the strength of what this prototype surfaced. When
> you pick streaming work back up, **rebase this branch onto current main first**.

## What this branch contains

- `src/eq/Equality.jl` — single `atom_equal` + `alpha_rename` at the bottom of the equality stack
- `src/eval/Eval.jl` — `eval_metta_stream` returning `Vector{Any}`; rule-rewriter enumerates all matching clauses; loud-logging adapter on `eval_metta`; `_canonical_var` plumbed through `_unify!` / `_apply_bindings` / `_var_name` / `_eval_let`; simplified `_eval_collapse`
- `src/primitives/Primitives.jl` — `=alpha` grounded primitive delegates to `atom_equal`
- `test/test_alpha_three_way_agreement.jl` — three-way agreement probe (54/54 green at park time, but see "Suite is blind" below)
- `test/test_collapse_nondeterminism.jl` — collapse non-determinism probe (14/16 at park time; the 2 failures were `(collapse (match …))` revealing `_eval_match`'s own unwrap is the next boundary)

The prototype falsified the shape correctly:
- `(collapse (bin))` returned `[0, 1]` instead of `[0]` — the substrate had the cardinality, the old API was hiding it
- `(factorial 5)` stack-overflowed under streaming — surfaced the divergent overlap class
- multi-result unwrap log had **one entry across 140 tests** — surfaced the suite-blindness problem

## Corrected resume order

The earlier proposed order was: rebase → verify → `_eval_match` deep-thread → immutable `Bindings` → equality unification. **Swap steps 3 and 4.** The corrected order:

1. **Rebase onto current `main`** (`502a039` → `ea79fcd`). Brings in the hygiene fix and eager lock-in. List ops become single-clause; CPS layer is gone.

2. **Fill the fourth cell of the three-way matrix: streaming + new stdlib.** Run the full `test_recursive_lists.jl` (not just factorial/nth) under this branch post-rebase. Expected: all 15 green. This is the proof that the streaming rewriter and the hygiene fix were *orthogonal* fixes to the same surfaced bug rather than overlapping patches. Run the full probe — over-produce cases too — to catch whether streaming changed any of them.

3. **Immutable `Bindings` salvage. (MOVED UP from step 4.)** Why before `_eval_match`: the moment `_eval_match` returns a real multi-result stream, each branch needs its **own** binding environment. A shared mutable `Dict{Symbol,Any}` clobbers across branches and produces what looks like a match bug but is actually the bindings substrate. Doing `_eval_match` first on mutable bindings means debugging cross-branch corruption *as if* it were a match-fan-out issue, which it isn't. **Land immutable bindings first, then fan-out is safe.**

4. **`_eval_match` deep-thread.** Remove the single-vs-multi unwrap at `_eval_match`'s boundary. Today it returns the lone result bare for length 1 and a Vector for length > 1; `_eval_collapse` then reconstructs cardinality. Under stream-everywhere, match always returns `Vector{Any}` and collapse becomes the pass-through this prototype already proved it can be.

5. **Equality unification.** The three-way alpha agreement test in this branch already passes (54/54), but see "Suite is blind" — the test pairs are too easy. Before declaring equality unified, the unification needs harder cross-encoding cases and a cross-language MORK byte-trie probe.

## Suite is blind — fix before trusting any green

The prototype's loud unwrap-adapter logged **exactly one** multi-result entry across all 140 tests: `Any[:bin] → [0, 1]`. That's not a curiosity, it's a warning. The current suite barely exercises nondeterminism, so steps 2–5 will all pass green on a suite that doesn't test the surface they're meant to fix. **Green at the end of step 5 means "didn't break the deterministic path," not "streaming works."**

Before step 5 (or in parallel with step 2), add **genuinely nondeterministic test programs**:

- Multi-clause functions that legitimately return multiple results (the canonical `(= (color) red) (= (color) green) (= (color) blue)` pattern)
- `superpose` into arithmetic — `(+ 1 (superpose (2 3 4)))` should be `[3, 4, 5]`
- Chained `match` — match results feeding into match patterns, real fan-out
- A real "ambiguous unification" case where one pattern matches in multiple ways via wildcards

Until the suite has these, the unwrap log will keep saying "1 entry" no matter how correct the streaming work is, because the suite isn't asking.

## Why this ordering matters

Each step lands on a base where the previous one is closed:
- Step 1 (rebase) → stdlib is correct under both rewriters
- Step 2 (orthogonality verify) → streaming + new stdlib confirmed clean
- Step 3 (immutable bindings) → branching environments exist before branching code is written
- Step 4 (`_eval_match` deep-thread) → fan-out is safe because step 3 made it safe
- Step 5 (equality unification) → unifies on a base where the test surface is real (per "Suite is blind")

If you do step 4 before step 3, you'll be debugging cross-branch binding corruption as a match bug. If you skip the suite expansion, you'll declare streaming done on a suite that barely tests it. Both are recoverable but expensive — pre-empting them costs less than discovering them.

## Probe 4 pins a semantic decision — not just cartesian fan-out

`test/test_streaming_acceptance.jl` Probe 4 (`ab1d0fb` on main) asserts
`sort(inner) == [10, 20, 20, 40]` for `(* (superpose (1 2)) (superpose (10 20)))`
— **two `20`s, not one**. That isn't just the cartesian product; it's
the multiplicity-preserving H-E result list. Streaming + collapse, when
they land, must NOT run through any dedup pass on this path. SET semantics
(the MorkSupercompiler's decomposition mode, CountSink-style) is
incompatible with this and must stay off the collapse-of-superpose path.

When Probe 4 flips green during resume, read that green as "multiplicity
preserved," not just "cartesian product computed." If it ever goes green
with `[10, 20, 40]` (length 3, deduped), the test is mismarked or collapse
deduped — investigate which.

This is the through-line from the CountSink / SET-semantics-decomposition
discussion: streaming collapse is multiset-shaped, the supercompiler's
SET decomposition is set-shaped, and the two paths must not cross.

## WILLIAM regression under streaming (NEW — found at first resume run)

When the prototype was re-rebased onto main (`31282e6`) and the full
`runtests.jl` was run under the streaming rewriter, the Core MeTTa
Compatibility Suite stayed green (125/125) but **WILLIAM dropped from
27/27 to 22/27 — 5 failures**. The failing testsets:

  - W1/W6 count + support (`(edge $x bird)` count expected 3, etc.)
  - Dictionary CRUD
  - W3 Learn
  - WP§7.2 i-surprisingness
  - (one more)

WILLIAM's primitives (`WILLIAM.count`, `WILLIAM.Learn`, etc.) appear
to depend on a specific cardinality/shape from `match` or rule
rewriting that streaming alters — likely the same "unwrap-single-vs-
multi" boundary that `_eval_match` exposes in Probe 3. This is a
prerequisite finding for landing streaming: either WILLIAM's
primitives need to be adapted to stream-aware match returns, or
the streaming rewriter needs a compatibility mode for grounded
primitives that call back into match.

WHERE TO LOOK FIRST:
  - `packages/AdaptiveCompression/src/.../count.jl` (or wherever
    `WILLIAM.count` is registered as a grounded primitive)
  - Anywhere a Julia primitive calls `eval_metta` / `run_metta` /
    `core_match` and assumes a specific return shape

THE TEST IS DIAGNOSTIC, NOT ASPIRATIONAL: WILLIAM was 27/27 on main
*today* and 22/27 on prototype, so the 5 failures are exact regressions,
not aspirational improvements. Fix them before declaring streaming ready
to merge.

## Open multi-result-log entries (frozen at park time)

Single entry: `Any[:bin]` returning `[0, 1]`. Every other test in the suite hit the single-result path. Treat that as the baseline, not the ceiling — once the nondeterministic suite expansion lands, this log should have **many** entries, and each is a callsite that may need stream-aware handling.

## Pointers

- The hygiene fix that closes the divergent + dead-on-arrival + over-produce bins: `main` `4b2033f`
- The eager lock-in that settles the CPS-helper question: `main` `ea79fcd`
- The streaming acceptance oracles (`@test_broken` on main, flip on resume): `main` `ab1d0fb`
- The original audit doc: `docs/CORE_DEEP_DIVE_FINDINGS_2026-05-29.md` on `main`
- The three-way matrix prose lives in `4b2033f`'s commit body — `git log -1 4b2033f`
