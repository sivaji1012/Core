# Core vs PRIMUS_Core — MeTTa Interpreter Semantic Delta

This document tracks every observed semantic difference between
PRIMUS_Core's MeTTa interpreter (the source for the algorithm-library
ports in PRIMUS) and packages/Core's interpreter (the destination).

Each entry lists:
- **What differs** — the concrete divergence
- **Failure shape** — how it shows up in ported code
- **Detection** — what to grep for in a port-time audit
- **Fix pattern** — the canonical workaround

This is a **checklist**, not a tutorial.  Before declaring any port complete,
grep the ported surface against every entry below.  PRIMUS_Core MeTTa was
written assuming an evaluating, differently-shaped interpreter; failing to
audit against this delta means semantic mismatches that don't happen to
flip a red test in your fixtures pass silently into production.

---

## SD-1.  `match` does not evaluate templates

**What differs**.  Core's `_eval_match` substitutes variable bindings into
the template and pushes the resulting expression *unevaluated* per match.
PRIMUS_Core's `match` evaluates the template per match before pushing.

**Failure shape**.  Conditional templates `(if cond yes (empty))` and
function-call templates `(get-sti $id)` land in the result list as literal
expressions.  Counting via `size-atom` gives the *total* match count, not
the conditionally-filtered count.  `(empty)` does NOT remove the result.

**Detection**.
```
grep -E "match[^)]*\\(if " packages/Core/lib/**/*.metta
grep -E "match[^)]*\\(empty\\)" packages/Core/lib/**/*.metta
grep -E "match[^)]*\\(get-" packages/Core/lib/**/*.metta
```

**Fix pattern**.  Push raw atoms via match, then filter at iteration time
inside `foldl-atom` (whose body IS evaluated per element).

```metta
;; BROKEN — Core does not evaluate the template, every match counted.
(= (count-in-range $lo $hi)
   (size-atom (collapse (match &self (AV $id $sti $lti $vlti)
                               (if (and (>= $sti $lo) (< $sti $hi)) yes (empty))))))

;; WORKING — collect + foldl-filter (Box-wrapped per SD-2).
(= (count-in-range $lo $hi)
   (let $boxes (collapse (match &self (AV $id $sti $lti $vlti)
                                (Box (Pair $id $sti))))
        (foldl-atom $boxes 0 $acc $boxed
          (let* (((Pair $id $sti) (unbox $boxed)))
            (if (and (>= $sti $lo) (< $sti $hi)) (+ $acc 1) $acc)))))
```

---

## SD-2.  `collapse` does not unconditionally wrap single results

**What differs**.  `_eval_collapse` returns `result isa Vector ? result : [result]`.
For a single match whose template is a *Vector-shaped atom* (e.g.
`(AsymHebbianLink ...)`), the result is the atom itself, NOT `[atom]`.

**Failure shape**.
- `size-atom` on the collapsed result returns the **atom's arity** for
  1 match, not 1.  Counts pass when fixtures happen to have ≥2 matches;
  fail silently when population thins to one.
- `foldl-atom` / `map-atom` over the result iterates **over the atom's
  parts** instead of `[atom]` — wrong iteration count, wrong shape.
- `car-atom` after collapse decomposes the atom into its head.

**Detection**.
```
# Atom-shaped templates (Vector form, starts with constructor):
grep -nE "collapse \\(match[^)]*\\([A-Z][^)]*\\)\\)" packages/Core/lib/**/*.metta
```
Inspect each hit: is the template a Vector (atom) or a scalar?  Scalar
templates ($var, True, yes, numbers) work correctly; atom templates leak.

**Fix pattern**.  Either:
- **Drop the collapse** when the call site only needs the atom directly
  (e.g. `set-av!` doing remove-then-add): `(let $old (match &self ...) ...)`
  — `$old` is `()` for 0 or the atom for 1.
- **Box the result** when the call site needs a true list with correct
  counts and iteration semantics:

```metta
(= (get-hebbian-links $source)
   (collapse (match &self (AsymHebbianLink $source $t $s $c)
                    (Box (AsymHebbianLink $source $t $s $c)))))

(= (unbox (Box $x)) $x)
```

Callers iterate via `(map-atom $links $boxed (let $link (unbox $boxed) ...))`.

---

## SD-3.  `size-atom` is structural arity, not "match count"

**What differs**.  Same primitive as MeTTa stdlib; the surprise is its
*interaction* with SD-2.  On a Vector it returns length.  On an atom
that was passed through collapse as-is (per SD-2), it returns the atom's
arity.

**Failure shape**.  Counting matches gives wrong numbers for single-match
case when template is Vector-shaped.

**Detection**.  Every `size-atom` call site whose argument flows from
`collapse(match)`.  See SD-2.

**Fix pattern**.  Box (SD-2) OR scalar-template count:

```metta
(let $matches (collapse (match &self pattern yes))
     (size-atom $matches))   ;; always correct count
```

---

## SD-4.  `length` is not in Core's stdlib

**What differs**.  PRIMUS_Core has `length`; Core uses `size-atom`.

**Failure shape**.  `length $list` doesn't reduce → cascades through
arithmetic comparisons as an unreduced expression → conditionals take
unexpected branches → silent wrong behavior.

**Detection**.
```
grep -n "(length " packages/Core/lib/**/*.metta
```

**Fix pattern**.  s/`length`/`size-atom`/.

---

## SD-5.  `lambda` is not a Core form for higher-order list ops

**What differs**.  Core's `foldl-atom` / `map-atom` / `filter-atom`
require **canonical N-arg syntax**, not lambda-wrapped bodies.

| Op | PRIMUS_Core | Core |
|---|---|---|
| foldl | `(foldl-atom $l $i (lambda ($a $x) body))` | `(foldl-atom $l $i $a $x body)` |
| map | `(map-atom $l (lambda ($x) body))` | `(map-atom $l $x body)` |
| filter | `(filter-atom $l (lambda ($x) pred))` | `(filter-atom $l $x pred)` |

**Failure shape**.  `lambda` is unbound → leaks unreduced → no iteration.

**Detection**.
```
grep -nE "(foldl-atom|map-atom|filter-atom).*lambda" packages/Core/lib/**/*.metta
```

**Fix pattern**.  Mechanical syntax conversion.

---

## SD-6.  `let` does not destructure compound patterns

**What differs**.  Core's `_eval_let` only binds when the var slot is a
`$x` Symbol.  Compound patterns `(Ctor $a $b)` are not destructured.

**Failure shape**.  Inner variables (`$a`, `$b`) remain unbound; downstream
references return the literal `__var_a` symbol → arithmetic / `==` give
wrong answers (sometimes silently True via close?-style helpers).

**Detection**.
```
grep -nE "(let \\(\\([A-Z]" packages/Core/lib/**/*.metta
grep -nE "(let \\([A-Z][^$)]" packages/Core/lib/**/*.metta
```

**Fix pattern**.  `let*` with 2-pair form — bind raw, then destructure:

```metta
;; BROKEN
(let (Ctor $a $b) $val body)

;; WORKING
(let* (($r $val) ((Ctor $a $b) $r)) body)
```

---

## SD-7.  `current-time` is not registered in Core

**What differs**.  PRIMUS_Core has a Julia `current-time` primitive.
Core does not.

**Failure shape**.  Returns unreduced; arithmetic against it leaks; the
self-evolution cooldown logic silently behaves as "always allowed" or
"never allowed" depending on which branch the unreduced expr hits.

**Detection**.
```
grep -n "current-time" packages/Core/lib/**/*.metta
```

**Fix pattern**.  Substitute `(get-ecan-tick)` — the ECAN heartbeat tick
counter (Phase 1a) is deterministic and tied to the cognitive loop that
drives self-evolution.  Better invariant than wall-clock anyway.

---

## SD-8.  `random-int` is not registered in Core

**What differs**.  Stochastic selection primitive present in PRIMUS_Core,
absent in Core.

**Failure shape**.  Returns unreduced; `get-random-atom-in-af` falls back
to deterministic (last-atom) selection — the foldl returns whatever
PRIMUS_Core's original implementation degenerated to.

**Detection**.
```
grep -n "random-int" packages/Core/lib/**/*.metta
```

**Fix pattern**.  Either accept deterministic fallback (current state) or
add as a Julia grounded primitive when stochastic selection matters.
TODO: deferred for a future phase that actually depends on randomization.

---

## SD-9.  `(Importance $id $sti $lti)` vs `(AV $id $sti $lti $vlti)`

**What differs**.  PRIMUS_Core has both atom shapes (legacy and current).
Core unifies on `AV`.

**Failure shape**.  Code written against `Importance` matches no atoms;
silent.

**Detection**.
```
grep -nE "\\(Importance " packages/Core/lib/**/*.metta
```

**Fix pattern**.  Rewrite the pattern to `(AV $id $sti $lti $vlti)`.

---

## SD-N.  `match` and `core_rules` are now trie-walks (not MORK pattern queries)

**What differs**.  Pre-2026-05-26 Core wrapped single patterns in `(, pat)`
and called MORK's `space_query_multi`.  This silently short-circuited:
MORK's arity-1 fast-path returns the *pattern itself* instead of iterating
the trie, so `(match &self pat tpl)` and stdlib rule lookups via
`core_rules` were both broken — but masked by tests that asserted only
`!== nothing` (an empty `[]` satisfies that).

The fix walks the trie directly via `read_zipper_at_path` +
`zipper_to_next_val!` + a cheap `_shape_match` filter
([CoreSpace.jl:463-481](../src/space/CoreSpace.jl#L463-L481)).  Behavior
now matches user expectation: `(match &self (foo $x) $x)` against
`(foo 1)` and `(foo 2)` returns `(1 2)`; stdlib reductions like
`(id foo) → foo` and `(if True 1 2) → 1` work end-to-end.

**Failure shape (pre-fix)**.  Single-pattern matches always returned `()`.
Any rule-based reduction in stdlib silently failed (e.g. `(id foo)` returned
itself unchanged).  Because special forms `if` / `let` / `case` bypass
`core_rules` entirely, simple eval workloads happened to work — masking
the bug for the lifetime of Core's `match` wrapper.

**Detection**.  In any port that depends on stdlib reductions like `id`,
`length`, `append`, `reverse`, `sort`, `member`, write a test that asserts
the *result* not just `!== nothing`:

```julia
@test eval_metta([:id, :hello], s) === :hello   # not @test r !== nothing
```

**Cost note**.  The walk is O(N) in `s.prefix` trie size on cache miss
(rule_cache amortizes per-head).  Acceptable at stdlib N≈150; will
need a proper structural-trie-matching primitive in upstream MORK before
N≥10k workloads.  Tracked in
[ATOM_TYPING_TRADEOFF.md](ATOM_TYPING_TRADEOFF.md).

---

## How to use this checklist

1. **At port time**: grep each entry against the file being ported BEFORE
   running tests.  Most green-on-first-run ports came from this discipline.

2. **At audit time** (after Phase 1b, after Phase 1c, before Phase 2):
   grep each entry against the *full ported surface* — including files
   that already passed tests.  Tests pass with the fixtures you wrote;
   the checklist catches mismatches the fixtures happen to mask.

3. **At spec-extension time**: when a new semantic mismatch is found, add
   an entry here with What/Failure/Detection/Fix — the next port phase
   audits against the new entry too.

**Last updated**: 2026-05-26 (Stage 1 multi-space + SMOKE-1 match fix).
