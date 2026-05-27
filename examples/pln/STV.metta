;;;; STV.metta — Truth value storage and retrieval (atom-keyed)
;;;; Tests: set-stv, get-stv, get-tv, stv-strength, stv-confidence

!(import! &self (library pln))

; Test 1: set-stv stores, get-stv retrieves
!(set-stv MyClaim 0.9 0.85)
!(assertEqual (get-stv MyClaim) (STV 0.9 0.85))

; Test 2: get-tv is an alias for get-stv
!(assertEqual (get-tv MyClaim) (STV 0.9 0.85))

; Test 3: distinct atoms have independent truth values
!(set-stv OtherClaim 0.3 0.7)
!(assertEqual (get-stv MyClaim) (STV 0.9 0.85))
!(assertEqual (get-stv OtherClaim) (STV 0.3 0.7))

; Test 4: stv-strength / stv-confidence extract components
!(assertEqual (stv-strength (STV 0.9 0.85)) 0.9)
!(assertEqual (stv-confidence (STV 0.9 0.85)) 0.85)

; Test 5: clamp utility
!(assertEqual (clamp 1.5 0.0 1.0) 1.0)
!(assertEqual (clamp -0.3 0.0 1.0) 0.0)
!(assertEqual (clamp 0.5 0.0 1.0) 0.5)

!(println! "STV.metta: all tests passed ✓")
