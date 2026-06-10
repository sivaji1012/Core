# ActPC subsystem — index

ActPC (Active Predictive Coding, Goertzel) is the neural↔symbolic cognitive kernel: a stack
where **both halves minimize prediction error** and a bridge (AC8) lets each half's error inform
the other. This dir indexes the ActPC pieces that live in the **Core** package. It is a
navigation map + status, not a tutorial — detailed docs are deferred to the eventual repo split
(see *Status & roadmap* below).

```
packages/Core/
  lib/ActPC-Chem/      ← symbolic half (MeTTa ChemRule soup over MORK)
  lib/ActPC-Geom/      ← geometry layer (currently empty; algorithms prototyped in experiments/)
  experiments/actpc_geom_ac8/   ← runnable gate/experiment scripts (the lab notebook)
  docs/actpc/          ← specs + this index
```

## The three components

| Component | Lives in | What it is | Status |
|---|---|---|---|
| **ActPC-Chem** (symbolic) | `lib/ActPC-Chem/` (`ActPC-Chem.metta`, `chemistry.metta`, `bridges.metta`) | Discrete rewrite-rule soup; learning via AC1/AC3 (`chem-step!`) | Mature — AC1–AC10, 16/16 tests. Spec: `actpc_chem_spec.md` |
| **ActPC-Geom** (geometry) | `lib/ActPC-Geom/` (empty) + `experiments/` | Wasserstein natural gradient on the discrete probability manifold (AG40–45) | AG40–42 **built** (transport gate passed); AG43–45 unbuilt; learning-preconditioner an honest negative. Spec: `actpc_geom_spec.md` |
| **AC8** (the bridge) | specs here + `experiments/` | Bidirectional PC node at the HDC interface: `e_bridge = encode(symbolic) − z_mu` | Mechanism **passed** (Phase-0/1); capability synergy (Phase-2) **open** |

The **neural half** is *not* in this repo — it is `CognitiveSubstratesAI/FabricPC` (PC graph,
autodiff-free Linear core). The **HDC interlingua** is `CognitiveSubstratesAI/FactorVSA` + `HMH`.

## Specs (this dir)

- `actpc_chem_spec.md` — ActPC-Chem axioms AC1–AC11.
- `actpc_geom_spec.md` — ActPC-Geom AG1–AG45 (+ the AG40–42 BUILT result section).
- `AC8_bridge_gate.md` — AC8 contract + the **mechanism** gate (G1 joint-error relaxation,
  G2 coupled-beats-uncoupled). §7 Phase-0 PASSED, §8 Phase-1 PASSED.
- `AC8_synergy_gate.md` — AC8 **capability** gate (S1/S2/S3) + §9 build log (see below).

## Experiment / gate scripts (`../../experiments/actpc_geom_ac8/`)

| Script | Gate | Result |
|---|---|---|
| `ac8_phase0_gate.jl` | AC8 mechanism, pure-Julia (toy soup) | ✅ G1+G2, 5 seeds |
| `ac8_phase1_bridge.jl` | AC8 mechanism, real MeTTa soup | ✅ G1+G2, 3 seeds |
| `actpc_geom_ag40_42.jl` | Wasserstein transport vs teleport | ✅ GEO-1+GEO-2 |
| `actpc_geom_wnat_learn.jl` | Wasserstein as a learning preconditioner | ⚠️ honest negative (Fisher wins) |
| `ac8_phase2_task.jl` | Synergy step 1 — task + vacuity proofs | ✅ confound exact, barrier informational |
| `ac8_phase2_synergy.jl` | Synergy step 2a — linear-drift task | ❌ falsified (wrap too accessible) |
| `ac8_phase2b_nonlinear.jl` | Synergy step 2b — path-integral, idealized joint | ⚠️ S1 robust, S2 unsettleable |
| `ac8_phase2b_real.jl` | Synergy step 2b — real MeTTa soup | superseded (`chem-step!` ~6 s/call) |
| `ac8_phase2b_vsa.jl` | Synergy step 2b — FabricPC + FactorVSA | S1 weak; **S2 honest negative** |

Run scripts from the FabricPC/MeTTaCore/FactorVSA env (see the experiments `README.md`).

## Status & roadmap

- **Done & solid:** ActPC-Chem core; ActPC-Geom AG40–42 transport mechanism; AC8 *mechanism*
  (Phase-0/1).
- **Open:** AC8 *capability synergy* (Phase-2 S2) — not established on the rule-induction-under-
  drift family; needs a channel that is genuinely un-de-driftable without the discrete rule (a
  task-design problem, **not** to be chased by tweaking the current task). ActPC-Geom AG43–45
  (scalable approximators) — parked as premature.
- **Repo split (deferred):** when ActPC-Chem + Geom + AC8 reach *heavy + stable* (AG43–45 decided,
  AC8 synergy resolved or explicitly scoped out), extract a standalone `CognitiveSubstratesAI`
  repo and move `lib/ActPC-*` + `experiments/actpc_geom_ac8/` + `docs/actpc/` **together**
  (self-contained). **Detailed documentation should be authored there, not here** — so it is not
  written twice. This index travels with the dir.
