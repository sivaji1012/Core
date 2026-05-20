;;;; PatternMining.metta — Example: basic pattern discovery
;;;; Tests: W1 (gain threshold), W6 (support ranking), W7 (heavy-hitters)

!(import! &self "../lib_william.metta")

; Populate a knowledge base
!(add-atom &self (edge robin bird))
!(add-atom &self (edge sparrow bird))
!(add-atom &self (edge eagle bird))
!(add-atom &self (edge dog mammal))
!(add-atom &self (edge cat mammal))
!(add-atom &self (edge whale mammal))
!(add-atom &self (edge salmon fish))
!(add-atom &self (edge trout fish))

; Test 1: WILLIAM.size
!(assertEqual
  (WILLIAM.size (edge robin bird))
  3)

; Test 2: WILLIAM.count — how many edges of type bird?
!(assertEqual
  (WILLIAM.count &self (edge $x bird))
  3)

; Test 3: WILLIAM.gain — gain of the (edge $x bird) pattern
!(let $g (WILLIAM.gain (edge $_ bird) 3)
  (assertEqual (> $g 0) True))

; Test 4: WILLIAM.iter-any-topk returns non-empty list
!(let $topk (WILLIAM.iter-any-topk &self 3)
  (assertEqual (> (size-atom $topk) 0) True))

; Test 5: WILLIAM.above-threshold? for frequent pattern
!(assertEqual
  (WILLIAM.above-threshold? &self (edge $x bird))
  True)

!(println! "PatternMining.metta: all tests passed ✓")
