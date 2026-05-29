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

### C. `Empty` as "no-results-in-stream" sentinel (couples to A)

Spec says: "`Empty` — the function doesn't return any result, it is
different from the void or unit result in other languages." On main
today (single-result), PRIMUS treats `Empty` as a regular Symbol — a
function that "returns" `Empty` just returns the symbol `:Empty`.
That's missing the protocol meaning.

`Empty` only has meaning **once results are a stream**, because then
"no result" is a real shape (an empty Vector) that's distinct from
"one result that happens to be the symbol Empty." Under step 1 + 3,
when `eval_metta_stream` returns `[(Empty, $bindings)]` from a
function body, `collapse` must decide:

- Filter it the same way Errors get filtered? (i.e., `Empty` results
  don't appear in the collapsed Vector)
- Yield it as a literal `:Empty` element in the collapsed Vector?
- Filter together with Errors via the same "no-success" branch in
  the pseudocode?

This is the **same shape of question as A** (error/success
partitioning). An all-`Empty` collapse and an all-`Error` collapse
are structurally identical: a stream with no Successes. The H-E
behavior treats `Empty` as "absent from the stream" — sub-A's
filter-on-Error branch is the natural place to also drop `Empty`.
Decide together with A at step 4.

(Note: `NotReducible` does NOT couple here despite looking similar.
It's a grounded-dispatch protocol, fixable today, independent of
streaming — see the protocol audit below.)

## Evaluation-order policy: fixed-table, not type-metadata

The spec's elementary-types section says metatypes (Atom, Symbol,
Variable, Expression, Grounded) "affect the order of the expression
evaluation," with `Atom` as the special signal for "don't reduce this
argument." That's H-E's mechanism for letting **user-defined**
functions be non-strict — declare `(: my-fn (-> Atom Atom))` and the
first argument arrives unreduced.

**PRIMUS does NOT honor this mechanism.** Probed it directly:

```
(: see-raw (-> Atom Atom))
(= (see-raw $x) $x)
(see-raw (+ 1 2))    →  3       (reduced eagerly)
                        spec:    (+ 1 2)   (preserved)
```

But the accurate statement isn't "PRIMUS ignores type annotations
for evaluation order" — that overclaims. PRIMUS *does* control
evaluation order correctly: `if`, `eval`, `chain`, `unify`, `function`,
`return`, `quote`, `match` all defer argument evaluation appropriately,
because they're in the **fixed special-form dispatch table** at
[`Eval.jl:50-97`](../src/eval/Eval.jl#L50-L97), checked BEFORE
argument evaluation.

The precise statement is:

> **PRIMUS controls evaluation order via a fixed special-form table,
> not via type metadata. The `Atom` meta-type is inert as an
> evaluation-order signal.** Built-in non-strict forms (the special-
> form table) work correctly; user-extensible non-strictness via
> `(: my-fn (-> Atom ...))` silently doesn't.

The gap boundary is clear: **anything in the special-form table is
non-strict and conformant; anything that would need a *user-declared*
non-strict function isn't.** Importers of H-E `.metta` programs:
the programs that break are the ones that define their own non-strict
functions via type annotations; the programs that use the built-in
non-strict forms work fine.

Connects to the eager-evaluator decision (`ea79fcd`): this is the
*spec-level* description of the same choice. The eager decision is
recorded as "stdlib uses single-guarded-clause + `if` discipline";
the deeper version is "user-extensible non-strictness via metatypes
isn't available in PRIMUS." Both true, the second one tells
H-E-program-importers exactly what fails.

## Parser audit (main, not streaming-specific) — three-way split

Two probes against the EBNF surfaced multiple tokenizer issues in one
session, which is itself the signal worth recording: **the tokenizer
has unaudited edge cases that fail badly when hit**. Cluster the
findings by what energy each needs — *fix*, *decide*, or *audit* — not
by surface symptom, so resume-you reads each item with the right
intent.

### A. Parser bugs to fix (go-fix energy)

These produce silent-drops or crashes on grammar-legal input. Independent
of streaming. Two findings, each with sub-fixes:

**A.1 — `fo"o` (symbol with internal `"`) crashes with `BoundsError`**

```
parse_metta("fo\"o")   →  BoundsError: attempt to access 4-element Vector{Char}
```

Per EBNF, `WORD ::= (CHAR | '#'), {CHAR | '"' | '#'}` — `"` is
explicitly permitted in symbol BODIES (after the first char). PRIMUS's
atom tokenizer at [Parser.jl:71](../src/parser/Parser.jl#L71) excludes
`"` from atom-mode, splits at the internal `"`, then enters string mode
on the unterminated `"o` remainder. The string-mode loop walks off the
end and the subsequent `chars[i:j]` BoundsErrors at
[Parser.jl:53](../src/parser/Parser.jl#L53).

This is TWO bugs hiding in one symptom:

- **Policy bug** — `"` should be a WORD char per the EBNF, but only in
  the body, not the head. The fix is *positional*: leading `"` opens
  string mode (current behavior, correct); non-leading `"` continues
  the WORD (currently exits — wrong). The variable loop at
  [Parser.jl:61](../src/parser/Parser.jl#L61) already does the
  conformant thing by accident (it doesn't special-case `"` at all,
  so `$fo"o` works). When fixing, trace these three together to
  confirm the positional rule holds:
  - `"hello"`     — leading `"` → string mode      (must keep)
  - `fo"o`        — internal `"` → symbol body    (currently crashes)
  - `foo`         — no `"` at all → symbol         (must keep)

- **Robustness bug** — even if you don't adopt the EBNF policy, the
  string-mode loop walking off the end without a terminator check is
  its own bug. **A parser should never `BoundsError`; it should produce
  a parse error.** In a self-modifying system that generates and
  re-parses its own atoms, a parser that *throws* on malformed input
  is a latent crash in the reflective loop. Fix the terminator check
  regardless of the policy decision.

**A.2 — `!42` / `!$x` / `!bare-symbol` silently drop (the seam)**

```
!(+ 1 2)        → Any[3]               ✓ (directive on Expression)
!name           → Any[Symbol("!name")] ✓ (HE artifact — `!`-prefix symbol)
!42             → Any[]                ✗ silently dropped
!$x             → Any[]                ✗ silently dropped
!bare-symbol    → Any[]                ✗ silently dropped
```

Not three separate behaviors of one feature — TWO features (`!name`
the symbol-with-`!`-prefix per the EBNF artifact note, and `!(expr)`
the exec directive on Expression) with an **unhandled seam** between
them. `!42` falls in the seam between "no space, so `!` is a symbol
prefix" and "followed by `(`, so it's a directive." The fix isn't
"make `!42` work" — that presumes an answer. The fix is **decide what
`!42` means** (directive on a literal? error? something else?) and
handle that case explicitly. Same for `!$x` and `!bare-symbol`.

### B. Conformance divergences to decide (go-decide energy, NOT bugs)

**`True` / `False` parse as Julia `true` / `false`** instead of Symbol
of type Bool. The EBNF delegates `True`-construction to the tokenizer
(see the spec's footer: tokenizer is `(<regex>, <constructor>)` pairs;
`([0-9]+, <int parser>)` is its example). PRIMUS just has an extra
entry that maps `true|True|false|False` to Julia Bool — a **legal
tokenizer choice**, just different from H-E's "construct Symbol of
type Bool" choice. This is not a bug; it's a tokenizer-table policy
divergence. The decision is whether to keep PRIMUS's choice (simpler
Julia interop, type info lives in the Bool Julia type) or migrate to
H-E's (Symbol-of-Bool-type, type info lives in the type system).
Doesn't belong in cluster A above — conflating it would make
resume-you treat a deliberate choice as a defect.

### C. Meta-finding (the audit, single pass)

The atom-mode loop excludes `"` (crashes on `fo"o`); the variable-mode
loop doesn't (`$fo"o` works); neither was written against the EBNF
char classes. The two loops disagree on `"` by ACCIDENT, not design —
the variable loop is accidentally EBNF-conformant and the atom loop is
accidentally crash-prone. There may be other char-class disagreements
between them that no probe has hit yet.

**Fix as one derived-from-grammar pass**, not three separate patches:

- Audit `tokenize`'s atom-mode, variable-mode, and string-mode loops
  against the EBNF `CHAR`/`WORD`/`STRING` productions
- Derive each loop's exclusion set from the grammar, not from
  reverse-engineered intuition
- Add the string-mode terminator check while you're in there
- Decide and implement the `!`-seam behavior at the same time

This is one ~half-day of work that closes A.1, A.2, and prevents future
"another tokenizer edge case crashes" findings. Doing it as three
separate patches will surface a fourth case later. Low priority overall
(no streaming dependency) but **higher priority than `!42` alone**
because the robustness sub-bug in A.1 means malformed input crashes
the parser, not just produces wrong output.

## `=` semantics audit — two findings from the same probe

The `=` special-expression probe confirmed PRIMUS handles the standard
`(= LHS RHS)` form correctly and treats malformed `=` atoms (arity ≠ 3)
as inert KB atoms per spec. But the probe surfaced two structural items
worth pinning: one is a step-4 acceptance check, the other is a
main-branch bug masquerading as inertness.

### D. Length-3 gate preservation (step-4 acceptance check)

[`CoreSpace.jl:619`](../src/space/CoreSpace.jl#L619) gates rule lookup
on `length(atom) == 3 && atom[1] === :(=)`. This is *why* malformed
`=` atoms — `(= LHS-only)`, `(=)`, `(= L R EXTRA)` — are inert today:
they're stored in the trie, queryable via `match`, but invisible to
`core_rules`. That inertness is a property of THIS LINE, not of `=`
semantics generally, and the rule-lookup path is exactly what step 4
(`_rule_rewrite_stream`) rewrites.

**Step-4 acceptance check** (one line, before declaring step 4 done):

> Confirm `_rule_rewrite_stream` preserves the length-3 gate so
> fan-out doesn't sweep malformed `=` atoms (arity 0/1/4+) into the
> result stream. The current first-match-wins rewriter couldn't sweep
> them by luck of stopping early; fan-out enumerates *all* matching
> atoms, so a looser query would surface them as accidental zero-body
> or extra-arg clauses. The gate is invisible-until-broken; this
> probe shows the atoms that would break it if it goes missing.

Not a bug — an invariant the streaming work has to preserve through
the rewrite.

### E. Symbol-LHS rules are dead code on main (latent bug)

The probe also revealed that `(= bare-symbol body)` rules are stored
in the trie but never fire. [`core_rules`](../src/space/CoreSpace.jl#L622)
explicitly requires `head_part isa Vector && !isempty(head_part) &&
head_part[1] === head_sym`. A symbol-LHS rule has `head_part isa Symbol`,
so the predicate fails and the rule is filtered out at lookup time.

Empirical confirmation:
```
(= LHS proper-body)  added.  Then:
  eval_metta(:LHS, S)         → :LHS         (unreduced)
  core_rules(S, :LHS)         → []           (empty)
  match returns the atom      → proper-body  (trie has it)

(= Nil ()) from stdlib's list.metta:
  eval_metta(:Nil, S)         → :Nil         (unreduced — Nil is dead)
  core_rules(S, :Nil)         → []
```

Currently latent because stdlib's `(= Nil ())` declaration isn't
referenced anywhere as a reducible — `Nil` is used as a literal Symbol
in match patterns, never as something to evaluate.

**Blast radius (wider than `Nil`)**: symbol-LHS is the standard idiom
for **named constants and nullary aliases** in MeTTa: `(= pi 3.14159)`,
`(= empty-board (board))`, `(= default-config (cfg ...))`. Every one
of those is dead in PRIMUS today. The reason this hasn't bitten is
that stdlib happens to use the pattern only for non-reducibles. Stops
being latent the moment any user writes the most natural definition
in the language. **Failure mode is silence** — the author has no
signal their constant didn't take.

**One bug, two callers fixed**. The evaluator's bare-symbol branch in
`_eval_metta_one` ALREADY has the code to handle symbol-LHS rules:
```julia
if expr isa Symbol
    rules = core_rules(space, expr)
    !isempty(rules) && return eval_metta(rules[1][2], space)
```
This branch exists *specifically* to reduce symbol constants — it's
the evaluator trying to do exactly what `(= Nil ())` needs. But
`core_rules` can never return non-empty for a symbol head because of
the line-622 predicate. **One predicate fix at line 622 makes both
the symbol-LHS storage AND the evaluator's existing symbol-reduction
branch work** — not two bugs to chase, one bug whose fix unlocks an
already-written branch.

**Fix** (small, main-branch independent of streaming):
```julia
# Currently (line 622):
head_part isa Vector && !isempty(head_part) && head_part[1] === head_sym || return
push!(rules, (head_part[2:end], body))

# Should be:
if head_part isa Vector && !isempty(head_part) && head_part[1] === head_sym
    push!(rules, (head_part[2:end], body))
elseif head_part isa Symbol && head_part === head_sym
    push!(rules, (Any[], body))   # zero-arg rule, empty params
end
```

**Interaction with section D — fix-must-preserve-the-gate**:
The corrected predicate is still **inside** the length-3 gate from
section D. The symbol-LHS case is a length-3 atom (`[:(=), :head, body]`)
with `head_part isa Symbol`, NOT an escape from the arity gate. A
loose rewrite that drops length-3 to catch symbol-LHS would *also*
start matching malformed `(= LHS-only)`/`(=)`/`(= L R EXTRA)` atoms
as rules. **Section E's fix must stay strictly inside section D's
length-3 gate.** If you do D and E in different sessions, the second
one needs to know about the first — flagged here so they don't
quietly reopen each other.

**Interaction with step 4 (streaming) — surface change for fan-out**:
Once `core_rules` returns symbol-LHS rules, `_rule_rewrite_stream`
(step 4) MUST fan them out too — `(= color red)` `(= color green)`
should stream `{red, green}` exactly as the expression-LHS multi-
clause does. So fixing E on main *before* step 4 means step 4 inherits
a `core_rules` that returns symbol-LHS rules and must fan them; fixing
E on main *after* step 4 means adding a new rule shape to an
already-streaming rewriter. Either order works, but the second person
needs to know the first changed the surface. **E and step 4 touch
the same `core_rules`/`_rule_rewrite_stream` pair.**

Probe-1-shaped acceptance check for symbol-LHS streaming (the test
that should land alongside Probe 1 when E is fixed):
```metta
(= color red)
(= color green)
(= color blue)
!(collapse color)    ; expect {red, green, blue}
```

Priority: BUMPED from "low / fix during a known-issues sweep" to
"fix before anyone writes much MeTTa against this." The blast radius
is "all named constants," not just `Nil`, and the failure mode is
silence. Class is the same as `fo"o`/`!42` (documented-behavior
doesn't actually work) but the user-visibility is higher because
named constants are a normal idiom, not a parser edge case.

## Protocol + robustness + minimal-MeTTa audit (this session)

Three findings from the special-results-and-minimal-MeTTa probe, each
needing its own filing because the "missing error subtype" framing
they came in under bundled items with very different shapes:

### F. `NotReducible` as a grounded-dispatch protocol (cheap independent fix)

Spec: "`NotReducible` — returns the unchanged function call instead."
This is a **grounded-dispatch protocol**, not a streaming question.
A grounded function returns the symbol `NotReducible` to signal
"the interpreter should leave my call unreduced." Today PRIMUS treats
`:NotReducible` as just a Symbol return — the evaluator passes it
through, the original call is replaced by `:NotReducible` instead of
preserved.

**Fix is local and cheap**: at the grounded-dispatch site in
[`Eval.jl:103-107`](../src/eval/Eval.jl#L103-L107), after a grounded
call returns, check if the result is the `NotReducible` symbol — if
so, return the original `expr` instead of the symbol. A few lines,
no streaming dependency, no metatype/eager interaction.

```julia
# Currently:
raw === nothing && return expr
return raw isa String ? from_sexpr(raw) : ...

# Add:
raw === "NotReducible" && return expr   # or whatever the unparse form is
```

Independent of everything else. Land alongside the other parser-bug
and `=` cleanup items when someone does a main-branch sweep.

### G. No evaluator depth bound — divergent recursion crashes the host (robustness)

Spec: "`StackOverflow` — returned by the interpreter when the stack
depth is restricted and maximum depth is reached." This is the spec
telling you H-E has an **evaluator-level depth bound** that catches
divergent recursion and converts it into a catchable `(Error <expr>
StackOverflow)` MeTTa atom.

**PRIMUS lacks the depth bound.** Probed by writing the divergent
factorial (two-clause base/recurse) and running under streaming — the
result was a Julia-level `StackOverflowError`, not a MeTTa `(Error
... StackOverflow)`. **In a self-modifying system that generates
and evaluates its own atoms, an unbounded-recursion atom takes down
the host eval loop rather than producing a catchable error.** That's
the live crash risk this section's other items don't have.

This is the **general backstop behind the per-rule stdlib discipline**.
The stdlib hygiene fix (`4b2033f`) treats divergence per-rule by
forcing single-guarded-clause discipline (factorial → `if`-guarded);
the depth bound is what catches divergence the discipline misses —
analogous to the evaluated-marker (section B) being the general fix
for re-expansion under fan-out.

**Priority is HIGHER than the other Error subtypes** because it's
a robustness/crash item, not a feature gap. `IncorrectNumberOfArguments`
and `BadArgType` not auto-generating means the program limps on with
unreduced expressions — annoying, off-spec, recoverable.
`StackOverflow` crashes. Fix: add a depth counter to `_eval_metta_one`
(or whatever the eval entry point is post-streaming), bound it (default
maybe 1000 levels?), return `(Error <original-atom> StackOverflow)`
when the bound is hit. Independent of streaming — fix on main.

Connects to the "self-modifying loop" framing the user has raised
multiple times: until G lands, every step-4-and-beyond change has
to be designed against "divergent recursion crashes the host," which
constrains experimentation. After G lands, divergent recursion just
errors and the loop survives.

### H. Minimal MeTTa instruction inventory — 8/13 present, two pairs missing

Inventory:

| Instruction | Status | Where |
|---|---|---|
| `eval` | ✓ special form | [Eval.jl L62](../src/eval/Eval.jl#L62) |
| `evalc` | ✓ special form (context arg ignored) | [Eval.jl L63](../src/eval/Eval.jl#L63) |
| `chain` | ✓ special form | [Eval.jl L59](../src/eval/Eval.jl#L59) |
| `unify` | ✓ special form | [Eval.jl L64](../src/eval/Eval.jl#L64) |
| `decons-atom` | ✓ grounded | AtomOps.jl |
| `cons-atom` | ✓ grounded | Primitives.jl |
| `function` | ✓ special form | [Eval.jl L60](../src/eval/Eval.jl#L60) |
| `return` | ✓ special form (uses `_ReturnValue` sentinel) | [Eval.jl L61](../src/eval/Eval.jl#L61) |
| `collapse-bind` | ✗ MISSING | — |
| `superpose-bind` | ✗ MISSING | — |
| `metta` | ✗ MISSING | — |
| `context-space` | ✗ MISSING | — |
| `call-native` | N/A | Rust-only |

The four missing split into **two pairs by why they're missing**, and
the distinction matters because they live at different parts of the
roadmap:

**`collapse-bind` / `superpose-bind` — step-4 deliverable, not generic
"to-do"**: these are precisely the **`(atom, bindings)` pair-stream
primitives** that step 1+3 introduces. Their absence today is exactly
what step 4 is building. Their **presence is a step-4 completion
signal** — when step 4 lands, `collapse-bind` and `superpose-bind`
should land with it as the canonical pair-stream API (PRIMUS's
existing `collapse`/`superpose` are the bare-Vector versions; the
`-bind` variants carry bindings per element).

**`metta` / `context-space` — deferred self-hosting prerequisite**:
these enable a MeTTa program to invoke the interpreter on a different
atom in a different context space, and to query the current
interpreter's working space. Required for any program that wants to
*host* its own interpreter — the spec footnote: "It is possible to
implement MeTTa interpreter in minimal MeTTa." Without these, PRIMUS
can't be its own host language for a MeTTa-defined interpreter. Not
needed for any current work; record as deferred until self-hosting
becomes a goal.

So when step 4 wraps up, the inventory becomes 10/13 (the bind-pair
landing with streaming). The remaining 2 (metta/context-space) are
their own track.

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
