;;;; ModusPonens.metta — PLN modus ponens (asymmetric)
;;;; Source doctest: pln_core_logic.metta line 226
;;;;   (Truth_ModusPonens (stv 0.8 0.9) (stv 0.7 0.85)) → (stv 0.564 0.4334)
;;;;
;;;; Strength: Ps*PQs + 0.02*(1-Ps)        = 0.8*0.7 + 0.02*0.2 = 0.564 exact
;;;; Confidence: Truth_w2c(Pc*PQc)
;;;;   Pc*PQc  = 0.9*0.85 = 0.765
;;;;   w2c(w)  = w/(w+1) = 0.765/1.765 ≈ 0.43342776 (rounded to 0.4334 in doctest)

!(import! &self (library pln))

;; Local tolerance helper — comparing 4-decimal rounded doctest values to
;; exact FP requires |a-b| < 0.0001
(= (close? $a $b)
   (if (< (- $a $b) -0.0001) False
       (if (< 0.0001 (- $a $b)) False True)))

; Test 1: strength is exact
;; Two-pair let* destructure: bind raw result, then unify against pattern.
;; `let` (single-pair) does NOT destructure compound patterns in Core — must use let*.
!(let* (($r (Truth_ModusPonens (stv 0.8 0.9) (stv 0.7 0.85)))
        ((stv $s $c) $r))
  (assertEqual $s 0.564))

; Test 2: confidence matches doctest within tolerance
!(let* (($r (Truth_ModusPonens (stv 0.8 0.9) (stv 0.7 0.85)))
        ((stv $s $c) $r))
  (assertEqual (close? $c 0.4334) True))

;; Sanity: verify destructure is actually binding (catches vacuous-pass bug
;; where close? on an unbound var returned True).  $s must NOT equal a junk value.
!(let* (($r (Truth_ModusPonens (stv 0.8 0.9) (stv 0.7 0.85)))
        ((stv $s $c) $r))
  (assertEqual (close? $s 99.0) False))

; Test 3: Truth_w2c is the weight-to-confidence map
; w2c(1) = 1/(1+1) = 0.5
!(assertEqual (Truth_w2c 1) 0.5)

; Test 4: Truth_c2w is the inverse: c2w(0.5) = 0.5/0.5 = 1
!(assertEqual (Truth_c2w 0.5) 1)

; Test 6: c2w/w2c round-trip
!(let* (($w (Truth_c2w 0.4334))
        ($c (Truth_w2c $w)))
  (assertEqual (close? $c 0.4334) True))

!(println! "ModusPonens.metta: all tests passed ✓")
