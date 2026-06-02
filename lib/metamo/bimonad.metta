;;;; bimonad.metta — MetaMo pseudo-bimonad F = 𝔻 ∘ Ψ (eq #6) + the lax-distributive
;;;; law (Principle 1). Ported from icoglabs MetaMo category/bimonad.metta.
;;;;
;;;; DISPATCH ADAPTATION: the upstream stores the appraisal/decision/dynamics fns
;;;; as SYMBOLS in a MetaMoPseudoBimonad record and applies them via
;;;; `(eval ($fn args))`. Core's MeTTa does NOT reduce a variable in head position
;;;; (feasibility-spike finding), so we drop the symbol-record and call the
;;;; concrete functions directly: Ψ = openPsiAppraise, 𝔻 = magusDecide. The
;;;; dynamics-stabilized variant of the step (damping / projection / safe-region)
;;;; arrives with M4 (dynamics.metta); M3 ships the bare F = 𝔻 ∘ Ψ.

(= (transitionAction (transitionResult $action $nextState)) $action)
(= (transitionState  (transitionResult $action $nextState)) $nextState)

;; Apply a goal-update ΔG: next goals = clip(G + ΔG, 0, 1); modulators carried
;; through from the post-appraisal state (M4 inserts damping + safe-projection here).
(= (applyDelta $state $deltaG)
   (motivation
     (clipVector (vectorAdd (motivationGoals $state) $deltaG) 0.0 1.0)
     (motivationModulators $state)))

;; F = 𝔻 ∘ Ψ : appraise the stimulus (Ψ), score+pick a candidate (𝔻), apply its ΔG.
;; → (transitionResult chosenAction nextState).
(= (metamoStep $state $stimulus $candidates)
   (let* (
     ($decisionState (openPsiAppraise $state $stimulus))
     ($decResult (magusDecide $decisionState $candidates))
     ($nextState (applyDelta $decisionState (decisionDeltaG $decResult)))
   )
     (transitionResult (decisionAction $decResult) $nextState)))

;; Principle 1 — lax distributive law: "appraise-then-decide" (𝔻∘Ψ) and
;; "decide-then-appraise" (Ψ∘𝔻) commute up to a small bounded distortion δ.
(= (checkLaxDistributiveLaw $state $stimulus $candidates)
   (let* (
     ($ds1 (openPsiAppraise $state $stimulus))
     ($dr1 (magusDecide $ds1 $candidates))
     ($final1 (applyDelta $ds1 (decisionDeltaG $dr1)))
     ($dr2 (magusDecide $state $candidates))
     ($decided2 (applyDelta $state (decisionDeltaG $dr2)))
     ($final2 (openPsiAppraise $decided2 $stimulus))
     ($distortion (motivationStateDistance $final1 $final2))
   )
     (if (<= $distortion (eval (LAX_DISTRIBUTIVE_DELTA))) True False)))
