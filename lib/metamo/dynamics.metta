;; MetaMo — dynamics (M4): safe region (eq #7), contraction (eq #8), homeostatic
;; damping / projection (Principle 4), the incremental blend (eq #9), and the
;; self-model-drift coherence check (Principle 5).
;;
;; Adopted from icoglabs MetaMo dynamics/{stability,coherence}.metta, dialect-
;; adapted into Core:
;;   • `(eval (CONST))` → `(CONST)` (Core reduces a 0-ary symbol fn directly).
;;   • checkContractiveUpdateLaw drops the upstream `$bimonad` symbol-record
;;     (the `(eval ($fn …))` dialect gap) and calls `metamoStep` directly.
;;   • the upstream coherence `nextStateCalculator` is a no-op (it blends a state
;;     with ITSELF, ignoring the target — see its own docstring). The genuine
;;     eq #9 update `x' = (1-α)·x + α·x*` is implemented here as `metamoBlend`.
;;
;; Index-conditional vector ops (boostAtIndices / projectGoalsToSafe / blendArrays
;; / setAtIndex) live in helpers.metta as pure MeTTa.

;; ── Safe region R (eq #7) ──────────────────────────────────────────────────
;; R = { x : gInd ≥ θ_safe  ∧  ‖G‖ ≤ G_max }.
(= (isInSafeRegion $state)
   (let* (
     ($gInd (getGoal $state gInd))
     ($gNorm (norm (motivationGoals $state)))
   )
     (and (>= $gInd (THETA_SAFE)) (<= $gNorm (G_MAX)))))

;; Distance to the nearest unsafe boundary (0 if outside R).
(= (distanceToUnsafeBoundary $state)
   (let* (
     ($gInd (getGoal $state gInd))
     ($gNorm (norm (motivationGoals $state)))
     ($distTheta (positivePart (- $gInd (THETA_SAFE))))
     ($distGMax (positivePart (- (G_MAX) $gNorm)))
   )
     (min $distTheta $distGMax)))

;; Boundary band B_η — inside R but within η of the boundary.
(= (isInBoundaryBand $state)
   (if (isInSafeRegion $state)
       (<= (distanceToUnsafeBoundary $state) (ETA_BOUNDARY))
       False))

;; Boundary pressure ∈ [0,1]: 0 comfortably inside, →1 at/over the boundary.
(= (boundaryPressure $state)
   (if (isInSafeRegion $state)
       (let* (($dist (distanceToUnsafeBoundary $state)))
         (if (>= $dist (ETA_BOUNDARY))
             0.0
             (clamp (- 1.0 (/ $dist (ETA_BOUNDARY))) 0.0 1.0)))
       1.0))

;; ── Homeostatic safeguards (Principle 4) ───────────────────────────────────
;; Raise the caution modulators (threshold, securing) in proportion to pressure.
(= (raiseBoundaryCaution $state)
   (let* (($pressure (boundaryPressure $state)))
     (if (== $pressure 0.0)
         $state
         (motivation
           (motivationGoals $state)
           (boostAtIndices (motivationModulators $state)
                           (OPENPSI_CAUTION_MOD_IDX)
                           (* 0.25 $pressure)
                           1.0)))))

;; Damp the proposed ΔG by (1 − pressure·gInd) when near/over the boundary.
(= (applyHomeostaticDamping $state $deltaG)
   (let* (($pressure (boundaryPressure $state)))
     (if (== $pressure 0.0)
         $deltaG
         (let* (
           ($gInd (getGoal $state gInd))
           ($dampingFactor (positivePart (- 1.0 (* $pressure $gInd))))
         )
           (scaleArray $deltaG $dampingFactor)))))

;; Hard projection back into R (floor gInd at θ_safe, scale ‖G‖ down to G_max,
;; and raise caution modulators).
(= (projectToSafeRegion $state)
   (motivation
     (projectGoalsToSafe (motivationGoals $state)
                         (OPENPSI_GOAL_WEIGHT_IDX)
                         (THETA_SAFE)
                         (G_MAX))
     (boostAtIndices (motivationModulators $state) (OPENPSI_CAUTION_MOD_IDX) 0.1 1.0)))

;; ── Contractive update law (eq #8) ─────────────────────────────────────────
;; Within the boundary band, the map must contract: d(Fx,Fy) ≤ c·d(x,y)+ε.
;; (Uses metamoStep as F; trivially True when neither x nor y is in the band.)
(= (checkContractiveUpdateLaw $x $y $stimulus $candidates)
   (if (not (or (isInBoundaryBand $x) (isInBoundaryBand $y)))
       True
       (let* (
         ($distInitial (motivationStateDistance $x $y))
         ($fX (transitionState (metamoStep $x $stimulus $candidates)))
         ($fY (transitionState (metamoStep $y $stimulus $candidates)))
         ($distFinal (motivationStateDistance $fX $fY))
       )
         (<= $distFinal (+ (* (C_CONTRACT) $distInitial) (EPSILON))))))

;; ── Incremental self-model blend (eq #9) ───────────────────────────────────
;; α = clip( ALPHA_0·(1−gInd) + BETA_0·gTrans , 0, 1 )  — overgoal-modulated rate.
(= (calculateBlendFactor $state)
   (let* (
     ($gInd (getGoal $state gInd))
     ($gTrans (getGoal $state gTrans))
   )
     (npClip (+ (* (ALPHA_0) (- 1.0 $gInd)) (* (BETA_0) $gTrans)) 0.0 1.0)))

;; x' = (1-α)·x + α·x*  on goals AND modulators, α from the CURRENT state.
(= (metamoBlend $current $target)
   (let* (($alpha (calculateBlendFactor $current)))
     (motivation
       (blendArrays (motivationGoals $current)     (motivationGoals $target)     $alpha)
       (blendArrays (motivationModulators $current) (motivationModulators $target) $alpha))))

;; ── Self-model drift (Principle 5, coherence) ──────────────────────────────
;; True when the approximated drift (Lipschitz·distance) stays within bound.
(= (checkSelfModelDrift $currentState $nextState $lipschitzConstant $maxAllowedDrift)
   (<= (* $lipschitzConstant (motivationStateDistance $currentState $nextState))
       $maxAllowedDrift))

;; ── Fully-stabilized governance step ───────────────────────────────────────
;; The complete F with the Principle-4 safeguards inline — this is the map the
;; contraction law (eq #8) is meant to govern, and the step the ECAN heartbeat
;; would call:
;;   Ψ appraise → 𝔻 decide → damp ΔG → apply → raise caution → project if unsafe.
;; Returns (transitionResult chosenAction safeNextState); the next state is always
;; in the safe region R.
(= (metamoGovern $state $stimulus $candidates)
   (let* (
     ($appraised (openPsiAppraise $state $stimulus))                 ;; Ψ
     ($decision (magusDecide $appraised $candidates))                ;; 𝔻
     ($dampedG (applyHomeostaticDamping $appraised (decisionDeltaG $decision)))
     ($moved (applyDelta $appraised $dampedG))
     ($cautioned (raiseBoundaryCaution $moved))
     ($safe (if (isInSafeRegion $cautioned) $cautioned (projectToSafeRegion $cautioned)))
   )
     (transitionResult (decisionAction $decision) $safe)))
