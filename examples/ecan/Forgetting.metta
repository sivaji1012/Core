;;;; Forgetting.metta — ECAN Forgetting Agent (memory reclamation)
;;;;
;;;; LTI < forget-lti-threshold ⇒ forgettable, UNLESS the atom is reinforced by a
;;;; Hebbian link (learning-protected). Forgetting fires only when the population
;;;; exceeds max-atoms; forget-sweep! is the unconditional form.

!(import! &self (library ecan))

;; ── Test 1: parameters ────────────────────────────────────────────────────
!(assertEqual (forget-lti-threshold) 0.05)
!(assertEqual (max-atoms) 1000.0)

;; ── Seed: three low/high-LTI atoms; one low-LTI atom is Hebbian-protected ──
!(add-atom &self (AV keep-hi 0.5 0.50 0.0))   ;; high LTI → kept
!(add-atom &self (AV drop-lo 0.5 0.01 0.0))   ;; low LTI, unlinked → forgettable
!(add-atom &self (AV prot-lo 0.5 0.01 0.0))   ;; low LTI BUT Hebbian-protected
!(add-atom &self (AsymHebbianLink anchor prot-lo 0.5 0.5))  ;; protects prot-lo (as target)
!(add-atom &self (AV src-lo  0.5 0.01 0.0))   ;; low LTI, protected as a link SOURCE
!(add-atom &self (AsymHebbianLink src-lo anchor 0.5 0.5))

;; ── Test 2: Hebbian protection (target and source both count) ──────────────
!(assertEqual (hebbian-protected? prot-lo) True)
!(assertEqual (hebbian-protected? src-lo) True)
!(assertEqual (hebbian-protected? drop-lo) False)

;; ── Test 3: forgettability = low LTI AND not protected ─────────────────────
!(assertEqual (forgettable? drop-lo) True)
!(assertEqual (forgettable? keep-hi) False)    ;; LTI 0.5 ≥ threshold
!(assertEqual (forgettable? prot-lo) False)    ;; protected
!(assertEqual (forgettable? src-lo)  False)    ;; protected

;; ── Test 4: forget-sweep! removes only the unprotected low-LTI atom ────────
!(forget-sweep!)
!(assertEqual (get-lti keep-hi) 0.5)           ;; kept (high LTI)
!(assertEqual (get-lti prot-lo) 0.01)          ;; kept (protected)
!(assertEqual (get-lti src-lo)  0.01)          ;; kept (protected)
!(assertEqual (get-lti drop-lo) 0.0)           ;; gone → get-lti default 0.0

;; ── Test 5: forgetting-step! is a no-op below the population cap ────────────
!(add-atom &self (AV transient 0.5 0.01 0.0))
!(assertEqual (forgetting-step!) True)
!(assertEqual (get-lti transient) 0.01)        ;; still here (population ≪ max-atoms)

!(println! "Forgetting.metta: all tests passed ✓")
