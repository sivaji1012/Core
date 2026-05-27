# Algorithm library governance — where source lives, how it evolves

**Status**: Decided 2026-05-27. While algorithms are light, everything lives
in Core. Splitting an algorithm into its own repo is a *later* step gated on
weight + interface stability (see "When to revisit").

## The one rule

> **Each algorithm lives in exactly one place: inside the Core repo.**
> Library source in `Core/lib/<algo>/`, demos in `Core/examples/<algo>/`,
> scratch in `Core/experiments/`. There is no second editable copy of the
> same `.metta` rules in any other repo.

If the same rule library is ever hand-edited in two repos, the architecture
has failed. Avoid that above all else.

## Layout (validated against PeTTa + CeTTa, dev-zone, 2026-05-27)

Both PeTTa and CeTTa put `lib/` and `examples/` as **top-level siblings** —
Core follows that. The one deviation: Core subfolders by algorithm where the
upstreams are flat, because Core's libs/examples are per-algorithm *suites*
(12 ECAN + 5 PLN + 4 WILLIAM demos) rather than the upstreams' loose
language-feature tests, and Core's `_resolve_library` already prefers the
directory form `lib/<name>/<name>.metta`.

```
Core/
  lib/          algorithm rule libraries — SOURCE OF TRUTH
    ecan/  pln/  hyperseed/  william/  metamo/      (entry: <algo>/<algo>.metta)
  examples/     runnable demos / benchmarks, per algorithm
    ecan/  pln/  william/
  experiments/  WIP / scratch explorations
  src/          the MeTTaCore substrate (runtime the libs load into)
  stdlib/  test/  docs/
```

Library entry point per the resolver: `(import! &self (library <algo>))`
resolves to `Core/lib/<algo>/<algo>.metta`. Examples import their algorithm
that way too (location-independent), never by relative path.

There are **no standalone per-algorithm repos** while algorithms are light —
that was briefly tried for ECAN/PLN on 2026-05-27 and folded back into Core
the same day, because co-location is the right call during the current
high-churn phase (below).

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

| Concern | Handling with everything in Core |
|---|---|
| Library B starts depending on library A | One commit edits both; load-order in one place; mutual `import!` cycles are just load-order, not a version dance |
| Did a change break a cross-algorithm interaction? | One `Core/test/runtests.jl` run exercises the whole `:common` interaction surface at commit time |
| An example breaks against a library change | The example lives in `Core/examples/<algo>/` — same repo, same test run catches it immediately, not in a downstream repo's CI later |
| Need a read-only standalone *algorithm* repo later | `git subtree split --prefix=lib/<algo>` (+ its `examples/<algo>`) produces a generated downstream mirror — never hand-edited |

## Examples and experiments are Core folders, not repos

Demos live in `Core/examples/<algo>/` and import their library via
`(import! &self (library <algo>))`. Scratch / WIP goes in
`Core/experiments/`. Neither is a separate repo while algorithms are light —
one repo, one test run, no version coordination.

(Historical note: standalone `ECAN`/`PLN` repos were briefly created on
2026-05-27 and folded back into Core the same day once we settled on
"keep in Core while light." Don't recreate them without clearing the
"When to revisit" bar below.)

## When to revisit (split an algorithm into its own repo)

Flip a given algorithm to its own versioned repo only when **both** hold:

1. Its rules have stabilized — weeks without a cross-algorithm change.
2. Other libraries consume it through a documented, stable interface (a fixed
   set of `import!`-able symbols), not by reaching into its internals.

Or when the algorithm gets **heavy** — large enough (data, generated assets,
long test suites) that carrying it in Core slows everyone's clone/precompile.

At that point, `git subtree split` the algorithm out as a read-only mirror,
or promote it to a real dependency with semver + a `Project.toml` git-source
pin. Until then, it stays in Core.

## Companion docs

- `STAGE1_ARCHITECTURE.md` — the App + Common multi-space model these
  libraries load into
- `SEMANTIC_DELTA.md` — Core-vs-PRIMUS_Core MeTTa differences to audit ports against
