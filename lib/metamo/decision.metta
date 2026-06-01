;;;; decision.metta — MAGUS hierarchical decision monad 𝔻 (eqs #5/#10/#11).
;;;; Ported from icoglabs MetaMo magus/decision.metta, dialect-adapted to Core
;;;; (upstream `decons` → helpers.metta `decons`; vector helpers in helpers.metta).
;;;;
;;;;   𝔻((G,M)) scores each candidate action by goal·modulator·overgoal·corr,
;;;;   minus a risk penalty (λ_Ind·g_over^Ind·caution·risk) and curiosity-ethics
;;;;   conflict penalty, plus a growth reward (λ_Trans·g_over^Trans·growth), then
;;;;   picks the best (magusDecide → (decisionResult bestAction bestΔG)).

;; ── Goal → relevant-modulator mapping (which modulators score each goal) ──
(goalModulatorRelevance gHelp (resolution))
(goalModulatorRelevance gCurio (arousal))
(goalModulatorRelevance gNovel (approach))
(goalModulatorRelevance gEthic (threshold securing))
(goalModulatorRelevance gSoc (valence approach))
(goalModulatorRelevance gSelf (approach resolution))

;; ── Goal → meta-drive (individuation / transcendence / dual) ──
(goalMetaDrive gHelp individuation)
(goalMetaDrive gEthic individuation)
(goalMetaDrive gCurio transcendence)
(goalMetaDrive gNovel transcendence)
(goalMetaDrive gSelf dual)
(goalMetaDrive gSoc dual)

;; ── Exploratory-growth goal set ──
(growthGoal gCurio)
(growthGoal gNovel)
(growthGoal gSelf)

;; Average modulator value over a list of modulator names.
(= (sumModulators $mods $state)
   (if (== $mods ())
       0.0
       (let* ((($head $tail) (decons $mods)) ($val (eval (getModulator $state $head))))
         (+ $val (sumModulators $tail $state)))))

(= (magusRelevantModulator $state $goalName)
   (let $result (match &self (goalModulatorRelevance $goalName $mods) $mods)
     (if (== $result ())
         0.0
         (/ (sumModulators $result $state) (size-atom $result)))))

;; Overgoal support: individuation/transcendence/dual meta-drive scaling.
(= (magusOvergoalSupport $goalName $indSignal $transSignal)
   (let $drive (match &self (goalMetaDrive $goalName $d) $d)
     (case $drive (
       (individuation (+ 0.5 (* 0.5 $indSignal)))
       (transcendence (+ 0.5 (* 0.5 $transSignal)))
       (dual (+ 0.5 (* 0.25 (+ $indSignal $transSignal))))
       ($_ 1.0)))))

;; Indices of the growth goals (from GoalIndex atoms) — no hardcoded (3 4 5).
(= (getGrowthIndices)
   (collapse (match &self (growthGoal $name) (match &self (GoalIndex $name $idx) $idx))))

;; Normalized growth signal for a candidate action.
(= (magusNormalizedGrowthSignal $candidate)
   (let* (
     ($growthIndices (getGrowthIndices))
     ($corrs (actionGoalCorrelations $candidate))
     ($deltaG (actionDeltaG $candidate))
     ($exploratoryAlignment (meanAtIndices $corrs $growthIndices))
     ($growthShift (meanAtIndices (clipVector (scaleArray $deltaG 10.0) 0.0 1.0) $growthIndices))
   )
     (+ (* 0.7 (positivePart $exploratoryAlignment)) (* 0.3 $growthShift))))

(= (getGoalIndex $goalName) (match &self (GoalIndex $goalName $idx) $idx))

;; Weighted contribution of one goal to the score.
(= (goalScoreContribution $state $candidate $goalName $indSignal $transSignal)
   (let* (
     ($weight (eval (getGoal $state $goalName)))
     ($modWeight (magusRelevantModulator $state $goalName))
     ($metaSupport (magusOvergoalSupport $goalName $indSignal $transSignal))
     ($idx (match &self (GoalIndex $goalName $i) $i))
     ($corr (index-atom (eval (actionGoalCorrelations $candidate)) $idx))
   )
     (* (* (* $weight $modWeight) $metaSupport) $corr)))

(= (sumGoalContributions $goals $state $candidate $indSignal $transSignal)
   (if (== $goals ())
       0.0
       (let* (
         (($head $tail) (decons $goals))
         ($headScore (goalScoreContribution $state $candidate $head $indSignal $transSignal))
         ($tailScore (sumGoalContributions $tail $state $candidate $indSignal $transSignal))
       )
         (+ $headScore $tailScore))))

;; MAGUS score of a candidate (eq #10/#11).
(= (magusScore $state $candidate)
   (let* (
     ($gInd (eval (getGoal $state gInd)))
     ($gTrans (eval (getGoal $state gTrans)))
     ($indSignal (eval (sigmoidNum (* (- $gInd 0.5) 6.0))))
     ($transSignal (eval (sigmoidNum (* (- $gTrans 0.5) 6.0))))
     ($cautionSignal (/ (+ (eval (getModulator $state threshold)) (eval (getModulator $state securing))) 2.0))
     ($growthSignal (/ (+ (eval (getModulator $state arousal)) (eval (getModulator $state approach))) 2.0))
     ($primaryGoals (collapse (match &self (goalModulatorRelevance $g $m) $g)))
     ($baseScore (sumGoalContributions $primaryGoals $state $candidate $indSignal $transSignal))
     ($ethicIdx (getGoalIndex gEthic))
     ($curioIdx (getGoalIndex gCurio))
     ($corrs (eval (actionGoalCorrelations $candidate)))
     ($curioEthicConflict (* (index-atom $corrs $curioIdx) (index-atom $corrs $ethicIdx)))
     ($conflictPenalty (if (< $curioEthicConflict -0.2)
                           (eval (expNum (* (absNumber $curioEthicConflict) 3.0)))
                           0.0))
     ($riskPenalty (* (* (* (eval (LAMBDA_IND)) $gInd) $cautionSignal) (eval (actionRiskEstimate $candidate))))
     ($growthReward (* (* (* (eval (LAMBDA_TRANS)) $gTrans) $growthSignal) (magusNormalizedGrowthSignal $candidate)))
   )
     (+ (- $baseScore (+ $riskPenalty $conflictPenalty)) $growthReward)))

;; Recursive best-candidate search.
(= (magusBestLoop $state $currentBest $currentScore $remaining)
   (if (== $remaining ())
       $currentBest
       (let* ((($head $rest) (decons $remaining)) ($headScore (magusScore $state $head)))
         (if (> $headScore $currentScore)
             (magusBestLoop $state $head $headScore $rest)
             (magusBestLoop $state $currentBest $currentScore $rest)))))

;; Decision result + accessors.
(= (decisionAction (decisionResult $action $deltaG)) $action)
(= (decisionDeltaG (decisionResult $action $deltaG)) $deltaG)

;; 𝔻: identity (unit) + decide (pick best candidate).
(= (magusUnit $state) $state)
(= (magusDecide $state $candidates)
   (let* (
     (($first $rest) (decons $candidates))
     ($firstScore (magusScore $state $first))
     ($best (magusBestLoop $state $first $firstScore $rest))
   )
     (decisionResult $best (actionDeltaG $best))))
