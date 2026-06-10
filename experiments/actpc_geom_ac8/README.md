# ActPC-Geom + AC8 bridge — runnable research prototypes

These are the executable Julia experiments behind the design specs in
`../../docs/actpc/` (`AC8_bridge_gate.md` §7–8, `AC8_synergy_gate.md` (Phase-2
capability gate), `actpc_geom_spec.md` "IMPLEMENTATION RESULT"). Specs describe,
experiments run — code lives here, the specs live under `docs/actpc/`.

- `ac8_phase0_gate.jl`   — AC8 Phase-0 mechanism gate (pure Julia: FabricPC PC +
  toy in-Julia rule soup + HDC cleanup + bridge). G1/G2 pass, 5 seeds.
  Run: `julia --project=<FabricPC>/benchmark/jit ac8_phase0_gate.jl`
- `ac8_phase1_bridge.jl` — AC8 Phase-1 REAL bridge (FabricPC ↔ MeTTaCore ActPC-Chem
  soup; soup learns via AC1/AC3). G1/G2 pass, 3 seeds.
  Run in an env with FabricPC + MeTTaCore + Enzyme (see AC8_bridge_gate.md §8).
- `actpc_geom_ag40_42.jl`     — Wasserstein natural gradient AG40–42 (transport vs
  teleport gate). Pure LinearAlgebra: `julia actpc_geom_ag40_42.jl`.
- `actpc_geom_wnat_learn.jl`  — Wasserstein-as-learning-preconditioner test
  (honest NEGATIVE: Fisher-diagonal wins; transport advantage doesn't transfer).
