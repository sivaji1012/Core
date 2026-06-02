;;;; config.metta — OpenPsi/MAGUS dimensions + constants (ported from icoglabs
;;;; MetaMo openpsi/config.metta + core/config.metta). Dialect-adapted for Core.

(= (NUM_GOALS) 8)
(= (NUM_MODULATORS) 6)
(= (NUM_STIMULUS) 4)

;; Goal index atoms — pattern-matchable via (match &self (GoalIndex $name $i) $i)
(GoalIndex gInd 0)
(GoalIndex gTrans 1)
(GoalIndex gHelp 2)
(GoalIndex gCurio 3)
(GoalIndex gNovel 4)
(GoalIndex gSelf 5)
(GoalIndex gEthic 6)
(GoalIndex gSoc 7)

;; Modulator index atoms (OpenPsi 6-vector)
(ModulatorIndex valence 0)
(ModulatorIndex arousal 1)
(ModulatorIndex approach 2)
(ModulatorIndex resolution 3)
(ModulatorIndex threshold 4)
(ModulatorIndex securing 5)

;; Stimulus index atoms
(StimulusIndex novelty 0)
(StimulusIndex conduciveness 1)
(StimulusIndex risk 2)
(StimulusIndex effort 3)

;; Core framework constants (core/config.metta)
(= (C_CONTRACT) 0.9)
(= (EPSILON) 0.05)
(= (ETA_BOUNDARY) 0.1)
(= (ALPHA_0) 0.1)
(= (BETA_0) 0.15)
(= (LAX_DISTRIBUTIVE_DELTA) 0.001)

;; OpenPsi behavioral constants
(= (LAMBDA_IND) 0.5)
(= (LAMBDA_TRANS) 0.5)
(= (THETA_SAFE) 0.3)
(= (G_MAX) 2.0)

;; OpenPsi merge/projection index categories (openpsi/config.metta)
(= (OPENPSI_GOAL_WEIGHT_IDX) 0)        ;; gInd position in the goal vector
(= (OPENPSI_CAUTION_MOD_IDX) (4 5))    ;; threshold, securing
