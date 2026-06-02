;;;; Spreading.metta — Importance Diffusion (Phase 1b)
;;;; Surface: trade-sti!, incident/hebbian prob vectors, diffuse-atom!,
;;;;          ecan-spread-step!, multi-hop-spread!, Hebbian link updates

!(import! &self (library ecan))

;; ── Test 1: trade-sti! moves STI from source to target ────────────────
!(add-atom &self (AV src1 0.2 0.1 0.0))
!(add-atom &self (AV tgt1 0.0 0.0 0.0))
!(trade-sti! src1 tgt1 0.05)
!(assertEqual (get-sti src1) 0.15000000000000002)
!(assertEqual (get-sti tgt1) 0.05)

;; ── Test 2: trade-sti! clamps when amount > source STI ────────────────
!(add-atom &self (AV src2 0.1 0.0 0.0))
!(add-atom &self (AV tgt2 0.0 0.0 0.0))
!(trade-sti! src2 tgt2 0.5)   ;; ask for more than source has
!(assertEqual (get-sti src2) 0.0)
!(assertEqual (get-sti tgt2) 0.1)

;; ── Test 3: incident-prob-vector — equal weight per neighbor ──────────
!(add-atom &self (Link hub  near1))
!(add-atom &self (Link hub  near2))
!(add-atom &self (Link hub  near3))
;; size-atom on the result of (incident-prob-vector hub) must = 3
!(let $pv (incident-prob-vector hub)
  (assertEqual (size-atom $pv) 3))

;; ── Test 4: ecan-spread-step! returns True below threshold ────────────
;; spreading-threshold default = 0.1; src3 sti = 0.05 < threshold → no spread.
!(add-atom &self (AV src3 0.05 0.0 0.0))
!(assertEqual (ecan-spread-step! src3 0.01) True)
;; src3's STI is unchanged because the spread was skipped
!(assertEqual (get-sti src3) 0.05)

;; ── Test 5: ecan-spread-step! diffuses above threshold ────────────────
!(add-atom &self (AV hub2 0.3 0.0 0.0))
!(add-atom &self (AV near-a 0.0 0.0 0.0))
!(add-atom &self (AV near-b 0.0 0.0 0.0))
!(add-atom &self (Link hub2 near-a))
!(add-atom &self (Link hub2 near-b))
!(ecan-spread-step! hub2 0.1)
;; Source STI decreased
!(let $s (get-sti hub2)
  (assertEqual (< $s 0.3) True))
;; At least one neighbor received some STI
!(let* (($a (get-sti near-a))
        ($b (get-sti near-b)))
  (assertEqual (> (+ $a $b) 0.0) True))

;; ── Test 6: Hebbian link creation via maybe-create-hebbian-link! ──────
;; NOTE: counting via (size-atom (get-hebbian-links ...)) is unreliable in
;; Core because collapse(match) with an atom-shaped template returns the
;; atom directly for 1 match (size-atom would return the atom's arity, not
;; the count).  Use the scalar-template count pattern instead.
!(maybe-create-hebbian-link! atom-x atom-y)
!(let $count (collapse (match &self (AsymHebbianLink atom-x $t $s $c) yes))
  (assertEqual (size-atom $count) 1))

;; ── Test 7: identical source/target → no Hebbian link ─────────────────
!(maybe-create-hebbian-link! atom-z atom-z)
!(let $count (collapse (match &self (AsymHebbianLink atom-z $t $s $c) yes))
  (assertEqual (size-atom $count) 0))

;; ── Test 8: default-link-weight and link-learning-rate are defined ───
!(assertEqual (default-link-weight) 1.0)
!(assertEqual (link-learning-rate) 0.1)

;; ── Test 9: hebbian-conjunction affine mapping conj∈[-1,1] → [0,1] ────
;; conj = (ni·nj) + (nj-ni)·|nj-ni|, then (conj+1)/2.
;; Co-activation (both high) → 1.0:  conj = 1·1 + 0 = 1 → (1+1)/2 = 1.0
!(assertEqual (hebbian-conjunction 1.0 1.0) 1.0)
;; Anti-correlation (i high, j low) → 0.0:  conj = 0 + (-1)·1 = -1 → 0.0
!(assertEqual (hebbian-conjunction 1.0 0.0) 0.0)
;; Both zero → 0.5 (the neutral midpoint the old clamp wrongly floored to 0):
;; conj = 0 + 0 = 0 → (0+1)/2 = 0.5
!(assertEqual (hebbian-conjunction 0.0 0.0) 0.5)

!(println! "Spreading.metta: all tests passed ✓")
