;;;; Funds.metta — Global STI/LTI fund pools
;;;; Tests: (AttentionFunds STI/LTI $amount), get/set-funds-sti!, default fallback

!(import! &self (library ecan))

; Test 1: starting-funds-sti is the default when no funds atom exists
!(assertEqual (starting-funds-sti) 100000.0)
!(assertEqual (starting-funds-lti) 100000.0)

; Test 2: get-funds-sti without any AttentionFunds atom falls back to starting
!(assertEqual (get-funds-sti) 100000.0)
!(assertEqual (get-funds-lti) 100000.0)

; Test 3: set-funds-sti! stores, get-funds-sti retrieves
!(set-funds-sti! 5000.0)
!(assertEqual (get-funds-sti) 5000.0)

; Test 4: STI and LTI fund pools are independent
!(set-funds-lti! 7000.0)
!(assertEqual (get-funds-sti) 5000.0)
!(assertEqual (get-funds-lti) 7000.0)

; Test 5: set-funds-sti! replaces (not duplicates) the funds atom.
; Setting twice should leave only one (AttentionFunds STI ...) atom.
!(set-funds-sti! 3000.0)
!(assertEqual (get-funds-sti) 3000.0)
!(set-funds-sti! 2500.0)
!(assertEqual (get-funds-sti) 2500.0)

; Test 6: targets and buffers are parameters (overridable)
!(assertEqual (sti-funds-target) 10000.0)
!(assertEqual (sti-funds-buffer) 10000.0)

!(println! "Funds.metta: all tests passed ✓")
