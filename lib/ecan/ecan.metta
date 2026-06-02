;; lib/ecan/ecan.metta — ECAN (Economic Attention Network) library entry point.
;;
;; ECAN: Goertzel/Hart attention allocation — STI (Short-Term Importance) and
;; LTI (Long-Term Importance) per atom, with rent/wage economic dynamics.
;;
;; Upstream:  https://github.com/iCog-Labs-Dev/metta-attention.git
;; Via:       packages/PRIMUS_Core/lib/ecan/ (mature multi-file impl,
;;            +semantic spreading +multi-objective importance +cross-system).
;;
;; ── Phase 0 (this load) ─────────────────────────────────────────────────────
;;   t1_ECAN_Policies   — economic parameters (funds, wages, rent rates)
;;   t1_core_logic      — AV accessors, rent collection, wage stimulation
;;
;; This is the foundation: enables get-sti, set-sti!, boost-sti!, AV storage,
;; and the economic primitives.  Sufficient to override PLN's ECAN stubs so
;; PLN.Derive's priority blend stops being confidence-only.
;;
;; ── Pending (Phase 1) ───────────────────────────────────────────────────────
;;   t1_state_logic, t1_FluidECAN, t1_AttentionPolicies, t1_SpreadingActivation,
;;   t1_ResonancePolicies, hyperseed/adaptive_attention.metta
;;   → adds governance-step!, heartbeat!, spreading kernel, self-evolution.
;;
;; ── Pending (Phase 2) ───────────────────────────────────────────────────────
;;   t2_ECAN_WILLIAM_Integration, t2_ImportanceOptimization
;;   → cross-system attention + adaptive STI/LTI updates.
;;
;; Julia primitives `decimate-importance!` and `normalize-attention!` are
;; Phase 1 scope (used only by governance-step!).  Not needed for Phase 0.

!(import! &self "t1_ECAN_Policies.metta")
!(import! &self "t1_core_logic.metta")
!(import! &self "t1_state_logic.metta")    ;; Phase 1a — AF membership, tick counter, scan gate
!(import! &self "t1_SpreadingActivation.metta")   ;; Phase 1b — spreading kernel, Hebbian links
!(import! &self "t1_AttentionPolicies.metta")     ;; Phase 1b — governance-step!, heartbeat!
!(import! &self "t1_FluidECAN.metta")             ;; Phase 1c — continuous-time fluid dynamics
!(import! &self "t1_Forgetting.metta")            ;; Phase 1c — memory reclamation (LTI threshold + Hebbian protection)
!(import! &self "../hyperseed/adaptive_attention.metta")  ;; Phase 1c — entropy classifier + self-evolution
