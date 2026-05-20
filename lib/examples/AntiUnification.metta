;;;; AntiUnification.metta — Example: LGG and NCD via MORK AUSink
;;;; Tests: W5 (NCD similarity), LGG correctness

!(import! &self "../lib_william.metta")

; Add some structured data
!(add-atom &self (likes alice pizza))
!(add-atom &self (likes bob pizza))
!(add-atom &self (likes carol sushi))

; Test 1: LGG of two identical atoms = same atom
!(let $lgg (WILLIAM.lgg (likes alice pizza) (likes alice pizza))
  (assertEqual $lgg (likes alice pizza)))

; Test 2: LGG of structurally similar atoms generalises the differing argument
!(let $lgg (WILLIAM.lgg (likes alice pizza) (likes bob pizza))
  ; result should be (likes $X pizza) — same structure, variable in slot 2
  (assertEqual (WILLIAM.size $lgg) 3))

; Test 3: NCD of identical atoms = 0
!(let $d (WILLIAM.ncd (likes alice pizza) (likes alice pizza))
  (assertEqual $d 0))

; Test 4: NCD of similar atoms < 1
!(let $d (WILLIAM.ncd (likes alice pizza) (likes bob pizza))
  (assertEqual (< $d 1) True))

; Test 5: NCD of dissimilar atoms > NCD of similar atoms
!(let* (($d-similar  (WILLIAM.ncd (likes alice pizza) (likes bob pizza)))
        ($d-dissimilar (WILLIAM.ncd (likes alice pizza) (edge robin bird))))
  (assertEqual (< $d-similar $d-dissimilar) True))

; Test 6: similarity = 1 - NCD
!(let* (($ncd  (WILLIAM.ncd (likes alice pizza) (likes bob pizza)))
        ($sim  (WILLIAM.similarity (likes alice pizza) (likes bob pizza)))
        ($sum  (+ $ncd $sim)))
  (assertEqual $sum 1))

!(println! "AntiUnification.metta: all tests passed ✓")
