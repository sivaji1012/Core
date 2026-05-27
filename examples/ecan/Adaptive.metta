;;;; Adaptive.metta — Self-evolving attention policy (Phase 1c)
;;;; Surface: count-atoms-in-sti-range, measure-attention-state!,
;;;;          classify-attention-state, adapt-spreading-policy!,
;;;;          attention-evolution-step!  (overrides Phase 1b stub)

!(import! &self (library ecan))

;; ── Test 1: count-atoms-in-sti-range with NO atoms ───────────────────
!(assertEqual (count-atoms-in-sti-range 0.0 1.0) 0)

;; ── Test 2: count-atoms-in-sti-range filters correctly ───────────────
;; This is the scalar-template count fix — proving that out-of-range
;; atoms aren't included in the count.
!(add-atom &self (AV a-high 0.8 0.0 0.0))
!(add-atom &self (AV b-high 0.7 0.0 0.0))
!(add-atom &self (AV c-mid  0.4 0.0 0.0))
!(add-atom &self (AV d-low  0.1 0.0 0.0))

!(assertEqual (count-atoms-in-sti-range 0.6 1.1) 2)
!(assertEqual (count-atoms-in-sti-range 0.2 0.6) 1)
!(assertEqual (count-atoms-in-sti-range 0.0 0.2) 1)

;; ── Test 3: classify-attention-state — Collapsed ─────────────────────
;; high=8, mid=1, low=1, total=10 → high-ratio=0.8 > 0.7 → Collapsed
!(assertEqual
  (classify-attention-state (AttentionMeasure 8 1 1 10))
  Collapsed)

;; ── Test 4: classify-attention-state — Diffuse ───────────────────────
;; high=0, mid=5, low=5, total=10 → high == 0 → Diffuse
!(assertEqual
  (classify-attention-state (AttentionMeasure 0 5 5 10))
  Diffuse)

;; ── Test 5: classify-attention-state — Balanced ──────────────────────
;; high=3, mid=4, low=3, total=10 → high-ratio=0.3, high!=0 → Balanced
!(assertEqual
  (classify-attention-state (AttentionMeasure 3 4 3 10))
  Balanced)

;; ── Test 6: classify-attention-state — Skipped (cooldown passthrough) ─
!(assertEqual
  (classify-attention-state (AttentionMeasure skipped))
  Skipped)

;; ── Test 7: empty-space → Balanced (no zero-division) ────────────────
!(assertEqual
  (classify-attention-state (AttentionMeasure 0 0 0 0))
  Balanced)

;; ── Test 8: attention-evolution-step! OVERRIDES the Phase 1b stub ────
;; If this still returns EvolutionStubUnloaded, Phase 1c didn't actually
;; load — the rule shadowing failed.  Returning any of the four real
;; classifier outputs proves the live override worked.
;;
;; First tick — scan IS due (last-scan-tick = -1000 default).
!(let $s (attention-evolution-step!)
  (assertEqual (or (== $s Collapsed)
                   (or (== $s Balanced)
                       (or (== $s Diffuse) (== $s Skipped))))
               True))

;; And it specifically must NOT be the unloaded sentinel.
!(let $s (attention-evolution-step!)
  (assertEqual (== $s EvolutionStubUnloaded) False))

;; ── Test 9: policy-change-allowed? returns True when no prior change ─
!(assertEqual (policy-change-allowed? Collapsed 100) True)

;; ── Test 10: attention-policy-cooldown parameter is reachable ───────
!(assertEqual (attention-policy-cooldown) 30)

!(println! "Adaptive.metta: all tests passed ✓")
