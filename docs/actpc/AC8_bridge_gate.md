# AC8 — The Continuous↔Discrete Error Bridge: Gate Definition (build-gate spec)

**Status:** ✅ PHASE-0 (mechanism, §7) AND PHASE-1 (REAL FabricPC↔Core/MeTTa bridge, §8)
BOTH PASSED (2026-06-09). AC8 — the continuous↔discrete bridge "built by nobody" — now
has a validated mechanism + a working real bridge: the actual ActPC-Chem ChemRule soup
(MeTTaCore, AC1/AC3) coupled to FabricPC PC, G1+G2 hold across seeds. Gate-before-build
discipline held end-to-end (defined §3 → Phase-0 pure-Julia §7 → Phase-1 real soup §8).
Proves the MECHANISM, not the whitepaper's full cognitive-synergy claim (Phase 2+).

**Date:** 2026-06-09.

Companion specs (read first, do not re-derive): `actpc_chem_spec.md` (AC1–AC11),
`actpc_geom_spec.md` (AG1–AG45). This doc is the *bridge* (AC8) only.

---

## 1. What AC8 is

ActPC-Chem (Goertzel) frames the whole stack as **predictive coding everywhere** —
both halves minimize prediction error; AC8 is the bridge that lets each half's error
inform the other. Built by **nobody** in the ecosystem (verified: FabricPC repo,
Behrend's "FabricPC Hyperon" deck, iCog `NGC-PC-Transformers` — all zero
hyperon/metta/atomspace refs). It is the novel contribution.

**The two halves (both now built and mature):**

| | Neural half | Symbolic half |
|---|---|---|
| Repo | `CognitiveSubstratesAI/FabricPC` (Julia) | `sivaji1012/Core` `lib/ActPC-Chem` (MeTTa) |
| State | continuous latents `z` | discrete metagraph (ChemRule soup over MORK) |
| Prediction | `z_mu` (node forward) | rewrite-rule output |
| Error | `e = z − z_mu`, energy `E = Σ e²` | `ε = atom-distance(output, actual)` (AC3) |
| Learning | local PC weight grad (Enzyme seam) | `w ← clamp(w + η(−ε + ν), 0, 10)` (AC1) |
| Maturity | eager + JIT + causal + autoregressive + fully-PC decomposed LM | AC1–AC10 (16/16) |

**Interlingua:** HDC (`CognitiveSubstratesAI/FactorVSA` + `HMH`) is the vector↔symbol
layer — atom `s` ⟷ hypervector `v(s)` ⟷ continuous PC latent. The grounded-op shim
(`FactorVSA (VecRef h)`) is the MeTTa-side hook pattern.

---

## 2. The bridge contract

The shared currency is **prediction error in HDC vector space**. AC8 is a
bidirectional PC node at the HDC interface:

- **symbolic → continuous.** The current symbolic metagraph state is HDC-encoded,
  `v = encode(state)`, and **clamped as a target** for a neural bridge-latent. The
  neural net relaxes/learns to predict `v`.
- **continuous → symbolic.** The neural bridge-latent's prediction `z_mu` is
  **decoded** (HDC cleanup → nearest atom(s)) into a target the symbolic soup must
  reach; the discrepancy becomes an `ε`-signal biasing `ChemRule` selection/weighting
  (feeds AC1's `−ε`).

Concretely the **AC8 node** is a PC node whose latent lives in HDC space and whose
local error `e_bridge = encode(symbolic_state) − z_mu` is the single quantity both
halves consume:
- the neural half consumes `e_bridge` continuously (the PC seam — already built);
- the symbolic half consumes `decode(e_bridge)` as `ε` (AC1/AC3 — already built).

No new neural porting is required to *produce* `e_bridge` (FabricPC inference+energy
are present). The new pieces are: `encode`/`decode` (HDC), the clamp/decode glue, and
the symbolic-side consumption of `decode(e_bridge)`.

---

## 3. The admissibility gate — **PC energy is the oracle**

Two metrics, both falsifiable, defined *before* building. (This refutes the audit's
"there is no oracle for AC8".)

**G1 — Relaxation across the boundary.** Under coupled inference, the *joint* error
```
J = E_neural  +  λ · ε_symbolic        (both are prediction errors)
```
decreases monotonically toward a fixed point. (Per-step `J(t+1) ≤ J(t)` modulo the
known softmax-energy caveat; report `J` trajectory.)

**G2 — Coupled beats uncoupled (negative control).** The coupled neuro-symbolic
system reaches a **lower** final `J` than the two halves run **independently**:
```
J_coupled  <  J_neural_only(continuous part)  +  J_symbolic_only(discrete part)
```
i.e. the bridge lets each half reduce error the other could not alone. If G2 fails,
the bridge adds noise, not synergy — AC8 is refuted at the mechanism level.

**Honest scope.** G1+G2 prove the **mechanism** (the bridge reduces *joint* error and
adds value). They do **NOT** prove the whitepaper's full cognitive-synergy claim.
That is deliberately out of scope for the gate.

---

## 4. The minimal experiment (run this, in order)

**Phase 0 — pure-Julia mechanism gate (no Julia↔MeTTa interop).** Cheapest path to
G1/G2. Everything in Julia:
- Task: a toy where output is co-determined by a **continuous** structured component
  (neural-predictable) and a **discrete** compositional component (rule-governed),
  and the optimum needs both (e.g. a sequence whose value = continuous drift + a
  discrete successor rule; or a 2-factor signal: one factor continuous, one a symbol).
- Neural half: a small FabricPC PC graph.
- Symbolic half: a *toy in-Julia* rewrite-rule soup — a handful of discrete rules with
  weights and `ε = discrete distance`, mirroring `chemistry.metta` AC1/AC3 semantics
  (NOT the real MeTTa soup yet).
- HDC: a small random-projection (or `FactorVSA`/`HMH.jl`) `encode`/`decode`.
- Bridge: the AC8 node coupling `e_bridge` ⟷ `ε`.
- Measure G1 (joint-error relaxation) and G2 (coupled vs the two uncoupled baselines).

**Decision point:** if G1+G2 pass in Phase 0, the *mechanism* is real → proceed.
If they fail, stop and diagnose (the bridge encoding, the coupling weight λ, or the
task design) — do **not** build the cross-language bridge on an unproven mechanism.

**Phase 1 — real bridge (FabricPC Julia ↔ Core MeTTa).** Replace the toy in-Julia
soup with the real `Core/lib/ActPC-Chem` MeTTa soup over MORK. Requires Julia↔MeTTa
interop (or running the neural half from MeTTa via a grounded op). Re-run G1/G2 on a
real ChemRule task. This is the heavy, deferred phase.

**Phase 2+ (out of *this* gate's scope; now specced separately):** the
cognitive-synergy *capability* gate is defined in `AC8_synergy_gate.md` (rule
induction under a continuous confound; S1 held-out capability / S2 error-exchange-
not-ensembling / S3 disambiguation on the confound set). Also: scale, and the geometry
layer (ActPC-Geom AG40–42 — now BUILT, see `actpc_geom_spec.md`).

---

## 5. Risks / open questions (resolve during Phase 0)

- **Coupling weight λ.** G1 needs `E_neural` and `ε_symbolic` on commensurate scales;
  λ (or a normalization) is a free knob — sweep it, report sensitivity.
- **HDC fidelity.** `decode(encode(s)) = s` must hold with cleanup; bridge error must
  be dominated by *prediction* error, not *codec* error. Gate the codec separately.
- **Softmax-energy caveat** (decisions/actpc_chem #8): with softmax outputs the energy
  is not a clean monotone objective → for G1 use Gaussian/MSE bridge latents, or judge
  by accuracy not energy on the softmax leg.
- **What is "the continuous part" vs "the discrete part"?** The task must be designed
  so neither half alone suffices (else G2 is vacuous) — analogous to the no-future-leak
  test design lesson (avoid a vacuous control).

---

## 6. One-line summary

AC8 = a bidirectional PC node at the HDC interface where `e_bridge =
encode(symbolic_state) − z_mu` is consumed continuously by FabricPC and as `ε` by
ActPC-Chem. The build is gated on **G1** (joint-error relaxation) and **G2** (coupled
beats uncoupled), run first as a pure-Julia mechanism gate. Both halves and the HDC
interlingua already exist; the gate is feasible with minimal new code.

---

## 7. PHASE-0 RESULT (2026-06-09) — GATE PASSED ✅

Ran the pure-Julia mechanism gate (`../../experiments/actpc_geom_ac8/ac8_phase0_gate.jl`; FabricPC PC neural
half + toy in-Julia cyclic-rule soup + HDC prototype cleanup + the bridge). Task:
`y[t] = proto[s[t]] + α·c[t]·drift` (α=4), symbol via cyclic rule with UNKNOWN seed
(phase inferred), drift continuous in c. 5 seeds.

- **G1 (relaxation across the boundary): PASS.** The coupled joint error
  `J = ‖y − (proto[ŝ] + drift)‖²` relaxes monotonically ~**0.69 → 0.02** to a fixed
  point, every seed. (The relaxation IS the chicken-and-egg resolving: the symbolic
  prototype lets the neural learn the residual drift.)
- **G2 (coupled beats uncoupled, non-vacuous): PASS.** Coupled **J≈0.02** vs
  neural-only **3.9–13.6** and symbolic-only **≈6.7** — every seed. NEITHER half alone
  solves the task (both ~6+), so the bridge combining them is doing the work, not extra
  capacity.
- **Bidirectional error flow, both shown:**
  - *symbolic→neural* (decisive in G1): de-prototyping `y − proto[ŝ]` is what lets the
    neural half learn the continuous drift.
  - *neural→symbolic* (smoking gun): when the symbolic half relies on CLEANUP (not the
    robust whole-sequence rule), the neural de-drift lifts symbol-recovery accuracy
    **0.85 → 1.00** (4/5 seeds; the 5th had no drift-corruption to correct). The neural
    de-corruption is what makes the corrupted symbols recoverable.

**Honest scope (as predicted):** this proves the MECHANISM — the bridge reduces joint
error, both error directions carry information, and coupling beats either half alone.
It does NOT prove the whitepaper's full cognitive-synergy claim. Two design notes that
mattered: (a) the whole-sequence rule-based phase inference is inherently robust to a
consistent drift, so the neural→symbolic flow is decisive only in the cleanup-reliant
(ruleless) regime — shown via the per-step cleanup contrast; (b) the task is non-vacuous
because each half is information-limited (neural sees only c, symbolic only the symbol
structure).

**→ Phase 1 unblocked.** The mechanism holds, so the real FabricPC(Julia)↔Core(MeTTa)
bridge is worth building: replace the toy in-Julia soup with the actual `Core/lib/
ActPC-Chem` ChemRule soup over MORK (Julia↔MeTTa interop or a grounded op), re-run
G1/G2 on a real ChemRule task. The toy soup's `ε`/cleanup map directly onto AC1/AC3.

---

## 8. PHASE-1 RESULT (2026-06-09) — REAL BRIDGE BUILT, G1/G2 HOLD ✅

The "Julia↔MeTTa interop" turned out trivial: **Core is itself a Julia MeTTa runtime
(`MeTTaCore`)**, so FabricPC (Julia) and the ActPC-Chem soup (MeTTa on MeTTaCore, Julia)
load in ONE env (env gate: FabricPC + MeTTaCore + Enzyme resolve + load together;
`actpc-update(ε,ν)` live → 5.05). No HTTP/FFI — direct `run_metta`.

Built the real bridge (`../../experiments/actpc_geom_ac8/ac8_phase1_bridge.jl`): the symbolic half is now the
ACTUAL ChemRule soup, not a toy. It seeds K² candidate `(ChemRule sI sJ w)` and LEARNS
the cyclic-successor rule through its genuine AC1/AC3 machinery — `chem-step!(cur, nxt, ν=1)`
reinforces correct-firing rules (`ε=0 → +η`) while wrong/non-firing stay flat (`−ε+ν=0`).
The bridge drives `chem-step!` with the neural-DE-DRIFTED, cleaned-up transitions (the
continuous→symbolic error flow); the soup's highest-weight-rule predictions anchor the
neural drift (symbolic→neural). 3 seeds:

- **Soup learned the rule:** correct cyclic-transition weight **3.40** vs distractor
  **1.00** → soup symbol-track accuracy **1.000** (the real AC1/AC3 dynamics, driven by
  the neural error, discovered the rule).
- **G1 (relaxation): PASS** — joint error monotone to a fixed point, every seed.
- **G2 (coupled beats uncoupled): PASS** — coupled **0.020** ≪ neural-only **4–14** and
  symbolic-only **≈1.70**, every seed. Non-vacuous (each half info-limited; coupled needs
  both).

**Status:** AC8 — the continuous↔discrete bridge "built by nobody" — now has a validated
MECHANISM (Phase 0) and a working REAL bridge (Phase 1, FabricPC ↔ Core/ActPC-Chem). Still
the mechanism, not the whitepaper's full cognitive-synergy claim. Next (Phase 2, out of
gate scope): richer ChemRule tasks (rewrite rules beyond a transition table), the geometry
layer (ActPC-Geom AG40–42, unbuilt everywhere), real cognitive-synergy benchmarks.
