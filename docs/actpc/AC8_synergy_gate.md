# AC8 Phase 2 — Cognitive-Synergy Gate (build-gate spec)

**Status:** 📐 GATE DEFINED, NOT YET BUILT. This is the *capability* gate that
graduates AC8 from "the bridge mechanism works" (Phase 0/1, energy-level, synthetic
toy) to "the coupled neuro-symbolic system has a capability **neither half has
alone**" (held-out generalization, real soup, disambiguation). Gate-before-build:
define the falsifiable success criteria here, *then* build.

**Date:** 2026-06-10.

Companion specs (read first, do not re-derive): `AC8_bridge_gate.md` (the bridge
contract + Phase 0/1 mechanism gate G1/G2 — both PASSED), `actpc_chem_spec.md`
(AC1–AC11; §"Cognitive synergy"), `actpc_geom_spec.md` (AG1–AG45). This doc is the
*Phase-2 capability gate* only.

---

## 1. Why a new gate (what Phase 0/1 did NOT prove)

The AC8 mechanism gate proved **G1** (coupled joint *energy* relaxes monotonically)
and **G2** (coupled reaches lower joint energy than the two halves run independently).
That is real, but it is *energy on a task we designed to need both halves*, with a
synthetic cyclic rule and prototype vectors. Three things it does **not** establish:

1. **Capability, not energy.** Lower training-time joint energy ≠ a better *held-out
   capability*. The whitepaper claims the coupled system can *do something* (induce a
   rule, generalize, extrapolate), not merely reach a lower number during fitting.
2. **Non-additivity.** G2 beats "two halves run *independently*." But independent
   halves never see each other's data structure. The real synergy claim is stronger:
   coupled must beat halves that get the **same data and compute but cannot exchange
   error** (parallel-but-uncoupled). Otherwise G2 is just ensembling/division-of-labor,
   not bootstrap.
3. **Genuine entanglement.** On the Phase-0/1 task the continuous and discrete parts
   were *separable in principle* (de-drift, then cleanup). Synergy in the strong sense
   requires items that are **ambiguous to either half alone** and resolvable only by
   joint inference — a chicken-and-egg neither half breaks by itself.

This gate targets exactly those three gaps.

---

## 2. The capability claim (what "cognitive synergy" means, operationally)

> A discrete generative process (a rewrite rule / small program) is observed only
> through a continuous, context-dependent perceptual channel. **The rule cannot be
> induced without correcting the channel, and the channel cannot be corrected without
> knowing the rule.** The coupled system bootstraps both and thereby *induces the
> correct rule* — which it demonstrates by **generalizing** (unseen seeds) and
> **extrapolating** (horizons longer than training). Neither half alone can, for an
> information-theoretic reason, not a capacity one.

The neural half (FabricPC PC net) models the continuous channel (the "drift"); the
symbolic half (the **real** `Core/lib/ActPC-Chem` ChemRule soup over MORK) induces the
discrete rule. The AC8 bridge exchanges prediction error between them (the Phase-1
machinery, now driving a capability task rather than an energy demo).

---

## 3. The task family — rule induction under a continuous confound

A deterministic discrete process generates a symbol track `s_1 → s_2 → …` under an
**unknown** rewrite rule `R` drawn from a rule space large enough that memorization ≠
induction (e.g. the modular-successor-with-branching family, or an elementary CA rule;
both expressible as ChemRules and both in the existing MORK regression family —
counter_machine / hexlife / odd_even_sort). Each symbol is observed only as

```
y_t = proto[s_t] + drift(context_t) + noise        # context = position, history, etc.
```

where `drift(·)` is an **unknown, context-dependent** continuous function (a real
regression problem, not a constant) scaled large enough that **naive cleanup**
(nearest-prototype *without* de-drifting) systematically mis-labels a designed subset
of symbols. That mislabeled subset is the **confound set** — the items where the wrong
drift hypothesis and the wrong rule hypothesis are mutually consistent.

- **Pure-symbolic** (cleanup → induce on `y` directly): induces the **wrong** `R`,
  because its symbol observations are corrupted by drift on the confound set.
- **Pure-neural** (regress `y` from context): fits training, but has **no compositional
  rule**, so its predictions collapse at extrapolation horizon / unseen seeds.
- **Coupled**: neural de-drifts → symbol estimates improve → soup induces correct `R`
  → `R` predicts symbols → better drift targets → … bootstrap to the correct rule.

**Train/test split.** Train on short horizon `T_train` and a seed set `Σ_train`. Test
on (a) **unseen seeds** `Σ_test`, and (b) **extrapolation horizon** `T_test ≫ T_train`.
Report a held-out **confound subset** explicitly.

---

## 4. The gate — three falsifiable criteria, pre-registered

All three must hold, across ≥5 seeds, with margins fixed *before* the run.

**S1 — Capability beats both *tuned* single-half baselines.** On held-out test
(unseen seeds + extrapolation horizon), coupled next-symbol accuracy (and continuous
trajectory error) strictly beats **both** the pure-neural and pure-symbolic baselines
by a pre-registered margin. Each baseline gets *fair, independent* hyperparameter
tuning (the parity-vs-opt-in lesson — a hobbled baseline is a vacuous win).

**S2 — Synergy is the *error exchange*, not ensembling.** Add a control:
**parallel-but-uncoupled** — both halves run on the same data with the same compute
budget, but the AC8 bridge is *severed* (no `e_bridge`/`ε` exchange). Coupled must beat
parallel-uncoupled by a pre-registered margin. If coupled ≈ parallel-uncoupled, the
bridge adds nothing beyond running two models — **synergy is refuted**.

**S3 — Disambiguation on the confound set (the strong claim).** On the held-out
**confound subset** — items provably ambiguous to either half alone — coupled accuracy
≫ both singles. This is the non-vacuous core: it directly shows joint inference resolves
what neither half can. If coupled does *not* separate from the singles specifically on
the confound set, the task was secretly separable and the synergy claim is unproven.

---

## 5. Vacuity guards (the no-future-leak discipline, applied)

These are the ways a "synergy" result is secretly fake. Check each *before* believing
a pass:

1. **Capacity artifact, not information barrier.** The pure-neural failure must be
   *information-theoretic*, not under-capacity. Verify: a pure-neural net with
   **unlimited** width/depth/epochs **still** cannot solve the confound set (the
   compositional rule genuinely isn't recoverable from `y` alone at extrapolation
   horizon). If a bigger net alone solves it, "needs symbolic" was an artifact → task
   is invalid, redesign.
2. **No leakage.** `Σ_test ∩ Σ_train = ∅`; `T_test` strictly beyond training horizon;
   the rule space large enough that the soup cannot memorize the track (must induce a
   *rule*, then roll it out).
3. **Codec dominates nothing.** As in Phase 0/1: HDC/cleanup error must not dominate —
   bridge error must be *prediction* error, not codec error. Gate the codec separately.
4. **The confound must be real.** Independently verify that on the confound set, the
   wrong-rule + wrong-drift hypothesis is *exactly as consistent* with `y` as the
   truth, for each single half — i.e. the ambiguity is genuine, not a tuning accident.

---

## 6. Minimal experiment (run in order; stop at the first failure)

1. **Build the task generator** + the confound set; *prove* the confound (guard §5.4)
   and the information barrier (guard §5.1) **before** training anything coupled.
2. **Three baselines, each tuned:** pure-neural, pure-symbolic, parallel-uncoupled.
   Record held-out S1/S3 metrics.
3. **Coupled run** (reuse the Phase-1 bridge: FabricPC ↔ real ActPC-Chem soup).
4. **Evaluate S1, S2, S3** on held-out unseen-seed + extrapolation-horizon sets, with
   the confound subset reported separately. ≥5 seeds.

**Decision point.** S1 ∧ S2 ∧ S3 pass → *task-level cognitive synergy demonstrated*
(a real, publishable capability result, and the wired bridge module now has a genuine
consumer → extract it then, per the deferred-module plan in `AC8_bridge_gate.md`). Any
fail → stop and diagnose (confound design, coupling schedule, codec) — do **not**
p-hack the margins or seeds.

---

## 7. Honest scope

Passing S1–S3 demonstrates cognitive synergy on **one constructed task family**. It
does **NOT** prove the whitepaper's *general* cognitive-synergy claim across domains,
nor that the synergy survives scale or richer rule spaces. Those remain out of scope.
What it *would* establish: the AC8 bridge produces a **capability neither substrate has
alone**, on a held-out generalization metric, with the synergy isolated to the error
exchange (S2) and demonstrated on genuinely ambiguous items (S3). That is the first
falsifiable capability evidence for the "built by nobody" bridge — the real
contribution, beyond the mechanism gate.

---

## 8. One-line summary

AC8 Phase-2 gate = a rule-induction-under-continuous-confound task where the rule and
the channel are mutually unidentifiable, gated on **S1** (coupled beats both tuned
single halves on held-out generalization), **S2** (coupled beats parallel-but-uncoupled
— synergy is the *error exchange*, not ensembling), and **S3** (coupled ≫ singles
specifically on the provably-ambiguous confound set). Guarded against capacity-artifact
and leakage vacuity. Pass ⇒ task-level cognitive synergy + a real consumer for the
wired bridge module.
