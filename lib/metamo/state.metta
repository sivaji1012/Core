;;;; state.metta — motivational state X = G × M + stimulus + action (ported from
;;;; icoglabs MetaMo core/state.metta). MotivationalState = (motivation Goals Modulators).
;;;; Distance / validate helpers (which need the vector ops) arrive with the
;;;; dynamics layer; M1 ships the constructors + projections used by appraisal.

(= (motivationGoals (motivation $goals $modulators)) $goals)
(= (motivationModulators (motivation $goals $modulators)) $modulators)
(= (stimulusValues (stimulus $values)) $values)

;; Action accessors (used by the decision layer)
(= (actionId (action $actionId $goalCorrelations $riskEstimate $deltaG)) $actionId)
(= (actionGoalCorrelations (action $actionId $goalCorrelations $riskEstimate $deltaG)) $goalCorrelations)
(= (actionRiskEstimate (action $actionId $goalCorrelations $riskEstimate $deltaG)) $riskEstimate)
(= (actionDeltaG (action $actionId $goalCorrelations $riskEstimate $deltaG)) $deltaG)

(= (copyMotivationState (motivation $goals $modulators)) (motivation $goals $modulators))

;; L2 distance between two motivational states (goals + modulators), used by the
;; lax-distributive-law check + the contraction law (needs helpers: norm/listDifference).
(= (motivationStateDistance (motivation $g1 $m1) (motivation $g2 $m2))
   (+ (norm (listDifference $g1 $g2)) (norm (listDifference $m1 $m2))))
