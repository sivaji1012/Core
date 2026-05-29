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

## Forced sub-decisions inside step 4 (NOT deferrable to step 5)

Surfaced by reading the H-E `interpret` pseudocode against PRIMUS's
`eval_metta` and noticing what *becomes* forced the moment the stream
is pair-shaped. Each of these reads as "deferrable cleanup" today
(single-result hides them) but becomes unavoidable at step 4. Decide
them deliberately during step 4; don't ship whatever accidentally
falls out of the projection code.

### A. Error-in-stream filtering at `collapse` (forced by step 1, decided at step 4)

Today, single-result, `(Error …)` short-circuits cleanly. After
step 1 (immutable Bindings → `[(Atom, Bindings)]` pairs) and step 3
(rewriter fan-out), a multi-clause function where one clause succeeds
and another errors produces a mixed stream:

```
(foo) → [(Bob, {…}), (Error … BadType, {…})]
```

`collapse` must decide:

- **Option A (H-E conformant)**: filter — yield Successes if any
  exist, else yield Errors. Matches the pseudocode's
  `len($success) > 0` branch.
- **Option B**: yield mixed — let downstream consumers see both
  Bob and the Error and handle it.

H-E's answer is A. PRIMUS today has *no* answer because single-result
never forced the question. Pick A explicitly during step 4 and write
the test for it; otherwise `collapse` will do whatever the projection
code accidentally implements, and the next person to hit a mixed
stream will debug a behavior nobody decided.

### B. Evaluated-marker (the general fix for the divergence class)

The pseudocode line `<mark $a as evaluated>` is not a perf optimization —
it's a **termination mechanism**. Without it, under fan-out, a result
fed back through eval can re-trigger the same `=` clauses it just came
from. On the eager single-result path PRIMUS gets away with it because
recursion bottoms out on first-match. Once fan-out is live, a
self-referential or mutually-recursive rule set that *would* terminate
under the evaluated-marker can instead re-expand.

The stdlib hygiene fix (`4b2033f`) closed the *known* divergence cases
(factorial, nth) by forcing single-clause + `if`-guarded discipline.
That treats the symptom per-rule. The evaluated-marker is the
**general mechanism** that makes the rewriter robust to overlap-induced
re-expansion across any rule set — including future user programs that
aren't held to the same discipline.

This is a step-4-or-step-5 **correctness** item, not cleanup. Without
it, the single-guarded-clause discipline becomes a *required* author
convention rather than a stylistic preference, and any program that
violates it can non-terminate under streaming even though it terminated
under main.

(Full metatype-driven dispatch — branching on MeTTa `%type%` rather
than Julia `isa` — remains genuinely deferrable. PRIMUS's `isa Symbol`/
`isa Vector` collapses to the same behavior for the cases that matter
in streaming. Don't bundle it with the evaluated-marker work.)

## Known parser issue (main, not streaming-specific)

`run_metta`'s `!` directive parser silently strips `!` on non-Vector
atoms. As of `31282e6`:

```
!(+ 1 2)        → Any[3]              ✓
!42             → Any[]                ✗ should be Any[42]
!$x             → Any[]                ✗ should be Any[$x]
!bare-symbol    → Any[]                ✗ should be Any[:bare-symbol]
```

The exec directive at run_metta only triggers when the parsed
expression is a Vector with `!` head; bare atoms preceded by `!`
don't form a Vector and so `parse_metta` either drops the `!` or
returns nothing.

Workaround for probe testing: wrap the atom — `!(quote 42)`,
`!(noeval bare-symbol)`. But it's a real bug for `.metta` files
with a top-level `!my-var` that resolves to a bare symbol — silence
instead of evaluation. Fix is in `parse_metta`'s `!`-prefix
handling, not in `eval_metta`. Low priority, no streaming dependency.

## Meta-rule: the single-to-stream caller-audit pattern

Three independent traces now point at the same general rule, and it's
worth carrying into step 4 as the recurring shape rather than
re-discovering per-primitive:

> Every primitive that returns a single value today and queries the
> space — directly via `match`/`core_match`, or indirectly via another
> primitive that does — needs a caller-audit when streaming lands,
> because the space query becomes a stream. The fix isn't in the
> primitive; the consumer's assumption that "one space query = one
> result" stops holding the moment step 1+3 land.

The three instances:

1. **WILLIAM** (`969020d`, `868f658`): five regressions, all
   `(size-atom (collapse (match …)))` shape. The substrate's match
   was already multi-result; the wrapper boundary at
   `eval_metta_stream`/`_eval_match` hides cardinality. Documented
   above; step 4 fixes.

2. **`_eval_if`** (probe earlier this session): condition evaluation
   is single-valued today (`cond = eval_metta(args[1], space)`). If
   `args[1]` evaluates to a stream of Bools under streaming (e.g.
   `(> 5 (superpose (3 7)))` → `{true, false}`), `_eval_if`'s
   `cond === true || cond == "True"` check sees a stream object
   and routes everything to the else-branch. Same caller-audit
   class — special form that consumes one space-query-derived value
   today, has to handle a stream tomorrow.

3. **`get-type` / `type-cast` / `get-type-space`** (this trace):
   covered in detail in the next section.

The meta-rule says: at step 4 commit time, sweep `src/eval/Eval.jl`
and `src/primitives/Primitives.jl` for *every* `eval_metta(x, space)`
or `core_match(...)` call site whose result is consumed as a single
value, and audit each for stream-handling. The three traced above
are samples, not the population.

## Type-oracle consolidation (deferred consumer migration with caller-audit)

The H-E `type_cast` pseudocode reads against PRIMUS as follows. The
three current type oracles disagree precisely where the type system
is load-bearing — and the disagreement isn't "three approximations of
the same thing," it's *`get-type` is the wrong oracle for the only
cases that matter*:

| Atom | structural | declared | `get-type` | `get-type-space` | `type-cast … Number` |
|---|---|---|---|---|---|
| `42` | Number | — | `Number` ✓ | — | OK ✓ |
| `foo` | Symbol | `Number` | `Symbol` ✗ | `Number` ✓ | Error (sees Symbol) ✗ |
| `baz` | Symbol | `Number`, `String` | `Symbol` ✗ | `Number` only (drops String) ✗ | Error ✗ |

Structural inference is correct for literals (which don't need a type
system) and wrong for symbols with declarations (the only thing
declarations exist for). The three oracles agree precisely where the
type system is trivial; they disagree precisely where it's
load-bearing.

The `baz` row is the multi-type case and contains the hidden decision:
`baz` is declared *both* `Number` and `String`; `get-type-space` drops
the second by taking first-match. The H-E pseudocode's
`for $t in $types` loop is a fan-out over **all** declared types.
Under streaming, the *correct* `get-type baz` returns the stream
`{Number, String}` — a multi-typed atom genuinely has both.

**Resume-notes line, deferred consumer migration** (NOT a precondition
for step 1+3, a consumer to migrate after):

> `type-cast` / `get-type` / `get-type-space` are downstream consumers
> of step 1+3. They currently use structural inference (`get-type`,
> `type-cast`) or first-match-only space lookup (`get-type-space`),
> which disagree on declared-but-non-structural atoms and drop
> multi-type declarations. Under streaming they collapse to one
> oracle querying `(: $atom $t)`, returning the `(type, bindings)`
> stream the rewriter natively produces — which means **`get-type`
> becomes multi-valued for multi-typed atoms**. Audit `get-type`'s
> callers for single-result assumptions before landing this — same
> class as the WILLIAM unwrap surface, third instance of the meta-rule
> above. Not free, not automatic; deferred consumer migration with
> its own caller-audit attached.

What's correct already, and worth keeping correct: the `Atom` and
`%Undefined%` universal-type short-circuits (`type-cast 42 Atom &self
→ 42`, `type-cast 42 %Undefined% &self → 42`). That's the branch of
the pseudocode that's load-bearing for **evaluation order** —
`Atom` is the metatype that tells the evaluator "don't reduce this,"
so the eager rewriter depends on it being correct. The trace confirms
it is. What's missing is the type-*query* machinery, which is
genuinely downstream of streaming.

Re-rebased prototype onto main (`31282e6`) and ran the full suite under
the streaming rewriter. Core MeTTa Compatibility Suite stayed green
(125/125), but **WILLIAM dropped 27→22 — 5 regressions**. Per the
audit-bucket framing the user proposed, classification matters more
than the patch: the question is whether all 5 are
**cardinality/env-discard** (resume ordering holds; step 3 fixes them
as a side effect) or whether any is **multiplicity** (resume ordering
needs a "where does dedup live" step inserted before equality
unification).

### The five regressions

| # | Test (line) | Expected | Got | Primitive chain |
|---|---|---|---|---|
| 1 | `WILLIAM.count &self (edge $x bird)` (37) | `[3]` | `Any[1]` | `count` → `(size-atom (collapse (match …)))` |
| 2 | `WILLIAM.count &self (edge $x fish)` (39) | `[0]` | `Any[1]` | same |
| 3 | `WILLIAM.dict-size &self` (53) | `[2]` | `Any[1]` | `dict-size` → `(size-atom (collapse (match …)))` |
| 4 | `WILLIAM.count` after Learn (66) | `>= 2` | `1` | `Learn` → `count` (chain 1) |
| 5 | `WP§7.2 i-surprisingness` (99) | `Number > 0` | `0` (Number, fails `> 0`) | `i-surprisingness` → `count` (chain 1) — downstream, VERIFIED |

**All 5 share one root cause.** The `WILLIAM.count` definition in
[`packages/WILLIAM/william.metta:77-80`](../../WILLIAM/william.metta#L77-L80)
is:

```metta
(= (WILLIAM.count $space $pattern)
   (let $result (collapse (match $space $pattern yes))
     (size-atom $result)))
```

Tracing this under streaming:
1. `_eval_match` returns `Any[:yes, :yes, :yes]` (N substituted templates) —
   correct, unchanged from main.
2. `_eval_collapse` (simplified on prototype to delegate to
   `eval_metta_stream`) calls `eval_metta_stream(inner)`.
3. `eval_metta_stream` sees the Vector return from `_eval_match`, checks
   `r isa _StreamResult` (false — only the rewriter populates that
   sentinel), and wraps as `Any[Vector]` — a 1-element stream containing
   the original match-result Vector as its lone element.
4. `_eval_collapse` returns this 1-element wrapper.
5. `size-atom` counts the wrapper → **1, regardless of N matches.**

The substrate produces the right cardinality the whole way through;
the wrapper at the `_eval_match` ↔ `eval_metta_stream` boundary hides
it by re-wrapping. For the 0-match case (regression #2), `_eval_match`
returns `[]`, `Any[[]]` has length 1 — same wrapper bug producing the
same "always 1" symptom.

### Bucket classification

| # | Bucket | Notes |
|---|---|---|
| 1, 2 | **Match-unwrap boundary** | `(collapse (match …))` returns `Any[Vector]` instead of `Vector`. Cardinality info is preserved in the substrate, hidden by the wrapper. |
| 3 | **Match-unwrap boundary** | Identical pattern: `(size-atom (collapse (match …)))`. |
| 4 | **Match-unwrap boundary (transitive)** | `Learn` calls `count`; count's regression propagates. |
| 5 | **Match-unwrap boundary (transitive, verified)** | `i-surprisingness` body read: `(/ (- (count …) 1) 1)`. `count` is its sole match/collapse-shaped dependency; the `$expected` denominator is a literal `1`, not a second cardinality. So this is genuinely transitive on `count`, not a hidden multiplicity surface. Under broken-count returning 1, the formula evaluates to `0` — a Number, but the test asserts `> 0`, hence failure. The symptom-mechanism match is exact, and there is no ratio-of-differently-collapsed-cardinalities lurking. |

**Bucket totals: cardinality/unwrap-boundary 5, env-discard 0, multiplicity 0.**

### What this tells the resume ordering

**The resume-notes ordering as written HOLDS.** All 5 regressions fall
in the same boundary the resume notes already plan to fix:
- Step 3 (immutable Bindings) — prerequisite, doesn't directly close these
- Step 4 (`_eval_match` deep-thread) — **closes all 5 as a side effect**
  by making `_eval_match` return a real stream that `eval_metta_stream`
  unwraps without re-wrapping

Zero multiplicity surprises. The decision pinned by Probe 4 (collapse
preserves duplicates) can be deferred to the equality work as planned —
WILLIAM doesn't depend on dedup semantics, only on the cardinality
boundary not lying about how many matches exist.

### Acceptance signal repurposed

WILLIAM was 27/27 on main *today*, 22/27 on prototype. After step 4
lands, WILLIAM should return to 27/27 *and stay there* — same diagnostic
role as Probe 3, but exercising the boundary under uncontrolled
production-shaped load instead of a hand-built two-level chain. Watch
all five flip together when step 4's deep-thread is correct; if any
remain red after step 4, the boundary fix is incomplete (most likely
explanation: `eval_metta_stream` still wraps non-`_StreamResult` Vectors
when the result should pass through as the stream).

### DO NOT patch WILLIAM

Resist the temptation to fix `WILLIAM.count` by wrapping the inner
`collapse` differently or using `length(get-atoms)` or any other
workaround. The regressions ARE the diagnostic; patching them spends
the signal and couples WILLIAM to a transitional shape that step 4
changes again. The fix lives in `_eval_match` / `eval_metta_stream`
during step 4, and WILLIAM regression-tests it for free.

## Open multi-result-log entries (frozen at park time)

Single entry: `Any[:bin]` returning `[0, 1]`. Every other test in the suite hit the single-result path. Treat that as the baseline, not the ceiling — once the nondeterministic suite expansion lands, this log should have **many** entries, and each is a callsite that may need stream-aware handling.

## Pointers

- The hygiene fix that closes the divergent + dead-on-arrival + over-produce bins: `main` `4b2033f`
- The eager lock-in that settles the CPS-helper question: `main` `ea79fcd`
- The streaming acceptance oracles (`@test_broken` on main, flip on resume): `main` `ab1d0fb`
- The original audit doc: `docs/CORE_DEEP_DIVE_FINDINGS_2026-05-29.md` on `main`
- The three-way matrix prose lives in `4b2033f`'s commit body — `git log -1 4b2033f`
