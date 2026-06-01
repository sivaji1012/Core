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
