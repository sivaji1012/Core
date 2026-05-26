# Atom representation: `Vector{Any}` today, BNF-typed `Atom` later

**Status**: Deferred. Captured 2026-05-26. Do not act without revisiting the
trade-off below — premature switch will churn the eval kernel.

## The concern

Hot paths in Core use `Vector{Any}` for expressions:

| Location                                        | Hot?   | Cost                                       |
| ----------------------------------------------- | ------ | ------------------------------------------ |
| `Eval.jl:399` `Any[_apply_bindings(e,b) for …]` | YES    | Allocates `Vector{Any}` per rule step.     |
| `CoreSpace.jl:126` `rule_cache` head args       | warm   | Loaded once per head; `Vector{Any}` inner. |
| `CoreSpace.jl:71` `from_sexpr` parse output     | cold   | One-off; not steady-state.                 |
| `Eval.jl:178, 832, 856` result aggregators      | warm   | Not in tight loops.                        |

`Vector{Any}` is intrinsic to the heterogeneous atom representation. Julia's
type inferencer can't specialize through it; every element access goes
through boxed dispatch.

## Why "type only the hot kernel" doesn't work in isolation

The original proposed quick fix — type only `rule_cache` and `_apply_bindings`
without changing the wider data model — needs a conversion at every
trie/eval boundary. The conversion cost typically eats the inference win,
unless the conversion is amortized over many rule applications per call.

In practice, that means: type the data model or don't bother.

## What the user's instinct says (MeTTa BNF grammar)

```
METTA      ::= { [ '!', [ DELIM ] ], ATOM, [ DELIM ] };
ATOM       ::= SYMBOL | VARIABLE | GROUNDED | EXPRESSION;
SYMBOL     ::= WORD;
VARIABLE   ::= '$', WORD;
GROUNDED   ::= NUMBER | STRING | BOOL | ...;
EXPRESSION ::= '(', { ATOM }, ')';
```

This grammar maps cleanly to a Julia abstract-type hierarchy with 4
concrete subtypes. Four is the magic number — Julia's compiler still
union-splits ≤4 element types, generating tight dispatch in inner loops
instead of generic boxed access.

```julia
abstract type AtomTerm end
struct SymAtom      <: AtomTerm; sym  ::Symbol           end  # SYMBOL
struct VarAtom      <: AtomTerm; name ::Symbol           end  # VARIABLE
struct GroundedAtom <: AtomTerm; val  ::Any              end  # GROUNDED
struct ExprAtom     <: AtomTerm; items::Vector{AtomTerm} end  # EXPRESSION
```

With this, `Vector{AtomTerm}` is type-stable. `_apply_bindings` can
dispatch via concrete-method tables. The JIT can inline.

## Cost and blast radius (why this is deferred)

Implementing the typed model honestly touches:

1. `CoreSpace.jl` — `from_sexpr` / `to_sexpr` / `core_match` / `core_rules` / `core_atoms` boundaries
2. `Eval.jl` — `_apply_bindings` / `_unify` / `eval_metta` / 12 `_eval_*` special-form handlers
3. `Primitives.jl` + `AtomOps.jl` — grounded callbacks now receive `AtomTerm` not `Any`
4. Downstream callers — anything that pattern-matches on `Vector{Any}` or `Symbol`

Estimate: 2–3 focused sessions with the existing 94-test suite as the gate.
Net win expected: 2–5× on rule-heavy hot loops, less on grounded-heavy
ones. Marginal on parse-cold paths.

## Why now isn't the right moment

Today (2026-05-26): `(count 1000)` recursive runs in **36 ms warm** —
36 µs/call including rule lookup + unify + binding-apply + 2 grounded
primitives. That's competitive with canonical MeTTa runtimes.

A bigger known cost exists in `core_rules`: post-SMOKE-1 fix it walks every
atom in `s.prefix` on cache miss (O(N) in trie size). At stdlib N≈150 this
is invisible; at N≈10k it would dominate. The structural-trie-matching
primitive in MORK (a future `space_match_atoms` API at the byte-trie level)
fixes both `core_rules` and `core_match` walks at once, and is a smaller
change than typing the atom model.

## Recommendation when this is revisited

Order of operations:

1. Land a structural `space_match_atoms` in upstream `sivaji1012/MORK`. This
   replaces the current Julia-side walk and gives O(matches) instead of
   O(trie-size). Bigger immediate win than typing.
2. Then introduce `AtomTerm` hierarchy in a separate branch, gated by a
   feature module so the conversion can be A/B benchmarked.
3. Measure on a workload that exercises `_apply_bindings` repeatedly
   (deep stdlib recursion, e.g. fold/map over long lists). Commit only if
   ≥2× steady-state win on that workload and 94/94 tests pass.

## What stays as-is

- `core_match` / `core_rules` still walk the trie + Julia-side filter
  (correct, ~µs per stdlib query). Documented in `CoreSpace.jl` near the
  `_walk_atoms` helper.
- `Vector{Any}` everywhere it currently is. Don't carve out partial
  typing — the conversion overhead defeats the purpose.
