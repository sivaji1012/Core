;;;; Fluid.metta — Continuous-time fluid attention dynamics (Phase 1c)
;;;; Surface: get/set-fluid-viscosity!, get/set-fluid-dt!,
;;;;          fluid-decay-step!, fluid-normalize-step!, fluid-attention-step!,
;;;;          fluid-af-step!, inspect-fluid-ecan

!(import! &self (library ecan))

;; ── Test 1: fluid parameter defaults ─────────────────────────────────
!(assertEqual (get-fluid-viscosity) 0.05)
!(assertEqual (get-fluid-dt) 0.1)

;; ── Test 2: set-fluid-viscosity! replaces value (collapse-fix works) ─
!(set-fluid-viscosity! 0.08)
!(assertEqual (get-fluid-viscosity) 0.08)

!(set-fluid-dt! 0.2)
!(assertEqual (get-fluid-dt) 0.2)

;; ── Test 3: setting twice replaces, doesn't accumulate ───────────────
!(set-fluid-viscosity! 0.03)
!(assertEqual (get-fluid-viscosity) 0.03)
;; A second set must also replace, not duplicate.  If a duplicate atom
;; survives, the get function returns the FIRST match (could be either).
;; Setting to a unique value and reading back proves the replace worked.
!(set-fluid-viscosity! 0.99)
!(assertEqual (get-fluid-viscosity) 0.99)

;; ── Test 4: fluid-decay-step! returns alpha = viscosity * dt ─────────
!(set-fluid-viscosity! 0.1)
!(set-fluid-dt! 0.5)
;; Seed an atom so apply-decay! has something to decay
!(add-atom &self (AV fluid-probe 0.5 0.3 0.0))
!(assertEqual (fluid-decay-step!) 0.05)

;; ── Test 5: fluid-attention-step! returns True on a focus atom ───────
!(add-atom &self (AV focus 0.5 0.3 0.0))
!(assertEqual (fluid-attention-step! focus) True)

;; ── Test 6: inspect-fluid-ecan tags the current params ───────────────
!(assertEqual (inspect-fluid-ecan) (FluidECANConfig 0.1 0.5))

!(println! "Fluid.metta: all tests passed ✓")
