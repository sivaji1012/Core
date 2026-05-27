;;;; Deduction.metta — PLN deduction formula
;;;; Source doctest: pln_core_logic.metta line 174
;;;;   (Truth_Deduction (stv 0.8 0.9) (stv 0.7 0.85) (stv 0.6 0.8)
;;;;                    (stv 0.7 0.9) (stv 0.6 0.85))
;;;;   → (stv 0.6 0.3213)

!(import! &self (library pln))

; Test 1: full Truth_Deduction with consistent preconditions
; Strength = 0.7*0.6 + (0.3 * (0.6 - 0.7*0.6))/0.3 = 0.42 + 0.18 = 0.6 exact
; Confidence = 0.7*0.6 * 0.9*0.85 = 0.42 * 0.765 = 0.3213 exact
!(assertEqual
  (Truth_Deduction (stv 0.8 0.9) (stv 0.7 0.85) (stv 0.6 0.8)
                   (stv 0.7 0.9) (stv 0.6 0.85))
  (stv 0.6 0.3213))

; Test 2: smallest-intersection-probability — PLN book p.74 consistency check
; (0.8 + 0.7 - 1) / 0.8 = 0.5 / 0.8 = 0.625
!(assertEqual (smallest-intersection-probability 0.8 0.7) 0.625)

; Test 3: largest-intersection-probability
; 0.7 / 0.8 = 0.8749999999999999 in IEEE-754 FP (not 0.875 exactly)
!(assertEqual (largest-intersection-probability 0.8 0.7) 0.8749999999999999)

; Test 4: conditional-probability-consistency
; 0.625 <= 0.7 <= 0.875 → True
!(assertEqual (conditional-probability-consistency 0.8 0.7 0.7) True)
; 0.625 <= 0.95 → True, but 0.95 > 0.875 → False
!(assertEqual (conditional-probability-consistency 0.8 0.7 0.95) False)

; Test 5: failing precondition returns (stv 1 0) fallback
; ABs=0.95 is above largest=0.875 → consistency fails
!(assertEqual
  (Truth_Deduction (stv 0.8 0.9) (stv 0.7 0.85) (stv 0.6 0.8)
                   (stv 0.95 0.9) (stv 0.6 0.85))
  (stv 1 0))

!(println! "Deduction.metta: all tests passed ✓")
