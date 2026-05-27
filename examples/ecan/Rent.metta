;;;; Rent.metta — Two-tier rent collection
;;;;
;;;; WA rent: charged to ALL atoms every governance tick.
;;;; AF rent: charged ADDITIONALLY to atoms inside Attentional Focus.
;;;; Defaults:
;;;;   wa-sti-rent-rate = 0.01
;;;;   wa-lti-rent-rate = 0.005
;;;;   af-sti-rent-rate = 0.05
;;;;   af-lti-rent-rate = 0.02

!(import! &self (library ecan))

; Test 1: rent rate parameters
!(assertEqual (wa-sti-rent-rate) 0.01)
!(assertEqual (wa-lti-rent-rate) 0.005)
!(assertEqual (af-sti-rent-rate) 0.05)
!(assertEqual (af-lti-rent-rate) 0.02)

; Test 2: collect-wa-rent! deducts wa-sti-rent-rate from STI
; Seed: STI=0.5, LTI=0.3, VLTI=0.1
; After WA rent: STI = clamp(0.5 - 0.01, 0, 1) = 0.49
!(add-atom &self (AV rent-probe 0.5 0.3 0.1))
!(collect-wa-rent! rent-probe)
!(assertEqual (get-sti rent-probe) 0.49)

; Test 3: WA rent also deducts from LTI
; LTI: 0.3 - 0.005 = 0.295
!(assertEqual (get-lti rent-probe) 0.295)

; Test 4: VLTI is preserved by rent
!(assertEqual (get-vlti rent-probe) 0.1)

; Test 5: collect-af-rent! deducts the higher AF rates
; Seed a fresh atom: STI=0.5, LTI=0.3, VLTI=0.1
; After AF rent: STI = 0.5 - 0.05 = 0.45 (exact in FP),
;                LTI = 0.3 - 0.02 = 0.27999999999999997 (not 0.28 in IEEE-754)
!(add-atom &self (AV af-probe 0.5 0.3 0.1))
!(collect-af-rent! af-probe)
!(assertEqual (get-sti af-probe) 0.45)
!(assertEqual (get-lti af-probe) 0.27999999999999997)

; Test 6: rent clamps at 0 — atoms can't go negative
!(add-atom &self (AV tiny-probe 0.005 0.001 0.0))
!(collect-wa-rent! tiny-probe)
; 0.005 - 0.01 = -0.005 → clamped to 0.0
!(assertEqual (get-sti tiny-probe) 0.0)
; 0.001 - 0.005 = -0.004 → clamped to 0.0
!(assertEqual (get-lti tiny-probe) 0.0)

!(println! "Rent.metta: all tests passed ✓")
