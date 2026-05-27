;;;; SymmetricModusPonens.metta — PLN symmetric modus ponens
;;;; Source doctest: pln_core_logic.metta line 241
;;;;   (Truth_SymmetricModusPonens (stv 0.8 0.9) (stv 0.7 0.85)) → (stv 0.628 0.7191)
;;;;
;;;; Strength = sA*sAB + (0.2*(1-sA))*(1+sAB)
;;;;          = 0.8*0.7 + (0.2*0.2)*(1+0.7) = 0.56 + 0.04*1.7 = 0.56 + 0.068 = 0.628 exact
;;;; Confidence = cA*cAB*Truth_or(sA, sAB)
;;;;            = 0.9*0.85 * Truth_or(0.8, 0.7)
;;;;   Truth_or(0.8, 0.7) = 1 - (1-0.8)*(1-0.7) = 1 - 0.06 = 0.94
;;;; → 0.9 * 0.85 * 0.94 = 0.7191 exact

!(import! &self (library pln))

(= (close? $a $b)
   (if (< (- $a $b) -0.0001) False
       (if (< 0.0001 (- $a $b)) False True)))

; Test 1: Truth_or — probabilistic OR (Łukasiewicz t-conorm under independence)
!(assertEqual (Truth_or 0.6 0.4) 0.76)
!(assertEqual (Truth_or 0.0 0.5) 0.5)
!(assertEqual (Truth_or 1.0 0.5) 1.0)
!(assertEqual (Truth_or 0.8 0.7) 0.94)

; Test 2: full Truth_SymmetricModusPonens (must use let* — let doesn't destructure)
!(let* (($r (Truth_SymmetricModusPonens (stv 0.8 0.9) (stv 0.7 0.85)))
        ((stv $s $c) $r))
  (assertEqual (close? $s 0.628) True))
!(let* (($r (Truth_SymmetricModusPonens (stv 0.8 0.9) (stv 0.7 0.85)))
        ((stv $s $c) $r))
  (assertEqual (close? $c 0.7191) True))

;; Sanity: catch vacuous-pass — close? on a junk reference must be False.
!(let* (($r (Truth_SymmetricModusPonens (stv 0.8 0.9) (stv 0.7 0.85)))
        ((stv $s $c) $r))
  (assertEqual (close? $s 99.0) False))

; Test 3: Truth_Negation — symmetry over s
!(assertEqual (Truth_Negation (stv 0.7 0.9)) (stv 0.30000000000000004 0.9))
; (Note: 1.0 - 0.7 in FP is 0.30000000000000004, not 0.3.  Faithful to the math.)

!(println! "SymmetricModusPonens.metta: all tests passed ✓")
