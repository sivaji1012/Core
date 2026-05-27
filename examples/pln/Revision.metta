;;;; Revision.metta — PLN belief revision (Bayesian-style merge)
;;;; Source doctest: pln_core_logic.metta line 254
;;;;   (Truth_Revision (stv 0.6 0.5) (stv 0.8 0.7)) → (stv 0.74 0.7692)
;;;;
;;;; w1 = c2w(0.5) = 0.5/(1-0.5) = 1.0
;;;; w2 = c2w(0.7) = 0.7/(1-0.7) = 2.333...
;;;; w = w1+w2 = 3.333...
;;;; f = (w1*f1 + w2*f2)/w = (0.6 + 0.7*0.8*3.333...)/3.333... ≈ 0.74 (rounded)
;;;; c = w2c(w) = 3.333/(3.333+1) ≈ 0.7692 (rounded)

!(import! &self (library pln))

(= (close? $a $b)
   (if (< (- $a $b) -0.001) False
       (if (< 0.001 (- $a $b)) False True)))

; Test 1: Truth_Revision matches doctest within tolerance (two-pair let* destructure)
!(let* (($r (Truth_Revision (stv 0.6 0.5) (stv 0.8 0.7)))
        ((stv $s $c) $r))
  (assertEqual (close? $s 0.74) True))
!(let* (($r (Truth_Revision (stv 0.6 0.5) (stv 0.8 0.7)))
        ((stv $s $c) $r))
  (assertEqual (close? $c 0.7692) True))

; Test 2: revising identical evidence is idempotent on strength
!(let* (($r (Truth_Revision (stv 0.7 0.5) (stv 0.7 0.5)))
        ((stv $s $c) $r))
  (assertEqual (close? $s 0.7) True))

; Test 3: |- Revision rule (symbolic — no STV-of-atom lookup needed)
; (= (|- ($T $T1) ($T $T2)) ($T (Truth_Revision $T1 $T2)))
!(let* (($r (|- (Inheritance-of-A (stv 0.6 0.5))
                (Inheritance-of-A (stv 0.8 0.7))))
        (($T $TV) $r))
  (assertEqual $T Inheritance-of-A))

; Test 4: high-confidence revision — strength unchanged, confidence grows
; c1=c2=0.95 → w=2*0.95/0.05=38 → w2c(38)=38/39≈0.9744.  Stays below 1.0
; (min 1.0 clamp would only matter for edge cases that 0.95 doesn't reach).
!(let* (($r (Truth_Revision (stv 0.5 0.95) (stv 0.5 0.95)))
        ((stv $s $c) $r))
  (assertEqual (close? $s 0.5) True))
!(let* (($r (Truth_Revision (stv 0.5 0.95) (stv 0.5 0.95)))
        ((stv $s $c) $r))
  (assertEqual (close? $c 0.9744) True))

;; Sanity: catch vacuous-pass — close? on a junk reference must be False.
!(let* (($r (Truth_Revision (stv 0.6 0.5) (stv 0.8 0.7)))
        ((stv $s $c) $r))
  (assertEqual (close? $s 99.0) False))

!(println! "Revision.metta: all tests passed ✓")
