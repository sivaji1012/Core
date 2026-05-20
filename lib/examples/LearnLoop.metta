;;;; LearnLoop.metta — Example: OBSERVE/PARSE/ENCODE/LEARN cycle
;;;; Tests: W3 (incremental learning), W4 (prediction), W8 (validation)
;;;; Ref: Franz 2019 §2, Hyperon WP §5.12

!(import! &self "../lib_william.metta")

; Start with an empty learning space (separate from &self)
!(bind! &learn-space (new-space))

; Feed a stream of data atoms — WILLIAM learns patterns incrementally
!(WILLIAM.Learn &learn-space (move knight e4))
!(WILLIAM.Learn &learn-space (move knight d6))
!(WILLIAM.Learn &learn-space (move bishop c4))
!(WILLIAM.Learn &learn-space (move knight f6))
!(WILLIAM.Learn &learn-space (move pawn e5))

; Test 1: dictionary should have grown
!(let $sz (WILLIAM.dict-size &learn-space)
  (assertEqual (> $sz 0) True))

; Test 2: (move knight $x) should be in dictionary (high frequency)
!(let $lookup (WILLIAM.dict-lookup &learn-space (move knight $x))
  (assertEqual (not (== $lookup NotFound)) True))

; Test 3: Query returns top patterns
!(let $topk (WILLIAM.Query &learn-space 3)
  (assertEqual (> (size-atom $topk) 0) True))

; Test 4: Predict completion of (move knight ?)
!(let $pred (WILLIAM.Predict &learn-space (move knight))
  (assertEqual (not (== $pred Empty)) True))

; Test 5: Validate — actual gain should be positive for frequent pattern
!(let* (($result (WILLIAM.Validate &learn-space (move knight $x)))
        ((WILLIAM.ValidationResult $_ $expected $actual $delta) $result))
  (assertEqual (> $actual 0) True))

; Test 6: Stats summary is well-formed
!(let* (($stats (WILLIAM.Stats &learn-space))
        ((WILLIAM.Summary $dict-sz $thresh $top) $stats))
  (assertEqual (> $dict-sz 0) True))

!(println! "LearnLoop.metta: all tests passed ✓")
