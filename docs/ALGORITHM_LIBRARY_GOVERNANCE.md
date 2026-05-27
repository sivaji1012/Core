# Algorithm library governance — where source lives, how it evolves

**Status**: Decided 2026-05-27. The contract below holds until cross-algorithm
churn drops enough to justify revisiting (see "When to revisit").

## The one rule

> **Algorithm source lives in exactly one place: `Core/lib/<algo>/`.**
> Everything downstream (standalone example repos, published mirrors) is
> either *pinned* to a Core version or *generated* from Core — never a
> second editable copy of the same `.metta` rules.

If the same rule library is ever hand-edited in two repos, the architecture
has failed. Avoid that above all else.

## The split, named explicitly

| What | Where | Role |
|---|---|---|
| Algorithm rule libraries | `Core/lib/{ecan,pln,hyperseed,...}/*.metta` | **Source of truth.** Co-evolve here. |
| Example / benchmark suites | `sivaji1012/{ECAN,PLN,...}` standalone repos | Exercise a *pinned* Core version. No algorithm source. |
| The substrate | `Core/src/` (MeTTaCore) | Runtime the libraries load into. |

The standalone `ECAN` / `PLN` repos contain `examples/`, `test.sh`,
`repl_test.jl`, and a `Project.toml` depending on `MeTTaCore` via git URL.
They do **not** carry the algorithm — `Core/lib/ecan/t1_core_logic.metta` is
the real ECAN; the standalone repo just imports it.

## Why source stays co-located in Core/lib

The algorithms are **interconnected at runtime, not just conceptually.** Per
the App + Common atomspace model, PLN / ECAN / MOSES / MetaMo are atoms in
the shared `:common` space: ECAN attention values feed PLN inference, MetaMo
reads PLN scores, and cross-references can be mutual (`import!` cycles like
ECAN-attention ↔ PLN-truth).

The decision driver for monorepo-vs-polyrepo on interconnected components is
**cross-algorithm change frequency**:

- **High churn** (a change to one library routinely forces a change to
  another) → co-locate. One repo, one test run, atomic cross-cutting commits.
- **Low churn** (libraries interact through stable, versioned interfaces) →
  separate versioned repos with pinned deps.

We are firmly in the high-churn phase (WILLIAM being wired, MetaMo equation
#9 in progress, SMOKE-1 having just unblocked rule lookup). In this phase,
splitting algorithm source into separate versioned repos means every
cross-cutting change becomes:

> bump `lib_ecan` → release → bump the SHA pin in `lib_pln` → discover
> breakage late, in a different repo's CI.

That polyrepo tax is pure friction during active development, and `import!`
cycles are effectively unmanageable across independently-versioned repos.
Co-location makes a cross-algorithm change one commit, one load-order edit in
a `loader.metta`, one `runtests.jl` run.

## How each maintenance concern is handled

| Concern | Handling in the Core/lib monorepo |
|---|---|
| Library B starts depending on library A | One commit edits both; `loader.metta` orders the `import!`s; mutual cycles are just load-order, not a version dance |
| Did a change break a cross-algorithm interaction? | One `Core/test/runtests.jl` run exercises the whole `:common` interaction surface at commit time |
| A downstream example breaks against new Core | The standalone example repo pins a Core SHA; its CI bumps-and-tests on a schedule and reports the break in isolation |
| Need a read-only standalone *algorithm* repo later | `git subtree split --prefix=lib/<algo>` produces a generated downstream mirror — never hand-edited |

## What this means for the standalone repos we created

`sivaji1012/ECAN` and `sivaji1012/PLN` are **example/benchmark repos**, by
contract. Their `Project.toml` pins `MeTTaCore` via git URL. They must not
accumulate algorithm rule source — if an example needs a new rule, that rule
goes into `Core/lib/<algo>/` and the example imports it.

## When to revisit

Flip a given library to its own versioned repo only when **both** hold:

1. Its rules have stabilized — weeks without a cross-algorithm change.
2. Other libraries consume it through a documented, stable interface (a fixed
   set of `import!`-able symbols), not by reaching into its internals.

At that point, `git subtree split` the library out as a read-only mirror, or
promote it to a real dependency with semver + a `Project.toml` git-source pin.
Until then, it stays in `Core/lib/`.

## Companion docs

- `STAGE1_ARCHITECTURE.md` — the App + Common multi-space model these
  libraries load into
- `SEMANTIC_DELTA.md` — Core-vs-PRIMUS_Core MeTTa differences to audit ports against
