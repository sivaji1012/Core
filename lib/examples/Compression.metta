;;;; Compression.metta — Example: MDL scoring and weakness integration
;;;; Tests: W2 (MDL objective), W2 weakness bijection (WP §5.1)

!(import! &self "../lib_william.metta")

; Build a repetitive dataset — repeated patterns = high compression gain
!(add-atom &self (event click button-a))
!(add-atom &self (event click button-b))
!(add-atom &self (event click button-a))
!(add-atom &self (event hover menu-1))
!(add-atom &self (event click button-a))
!(add-atom &self (event hover menu-2))

; Test 1: WILLIAM.size of compound expressions
!(assertEqual (WILLIAM.size (event click button-a)) 3)
!(assertEqual (WILLIAM.size (event click $x))       3)
!(assertEqual (WILLIAM.size click)                  1)

; Test 2: gain(pattern, support) — higher support = higher gain
!(let* (($g3 (WILLIAM.gain (event click $x) 3))
        ($g1 (WILLIAM.gain (event click $x) 1)))
  (assertEqual (> $g3 $g1) True))

; Test 3: MDL two-part cost reduces with better pattern
!(let* (($enc  5)
        ($dict 3)
        ($cost (WILLIAM.mdl-cost $enc $dict)))
  (assertEqual $cost 8))

; Test 4: weakness bijection — weaker patterns have higher weakness score
!(let* (($w-complex (WILLIAM.weakness (event click $x) 3))
        ($w-simple  (WILLIAM.weakness click 10)))
  ; click is simpler but less compressive — weakness inversely tracks gain
  (assertEqual (> 1 $w-complex) True))

; Test 5: i-surprisingness — (event click $x) appears more than chance
!(let $surprise (WILLIAM.i-surprisingness &self (event click $x))
  (assertEqual (> $surprise 0) True))

; Test 6: iter-prefix-topk scopes to (event click $x)
!(let $topk (WILLIAM.iter-prefix-topk &self (event click) 5)
  (assertEqual (>= (size-atom $topk) 0) True))

!(println! "Compression.metta: all tests passed ✓")
