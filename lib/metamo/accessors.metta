;;;; accessors.metta — named state accessors (ported from icoglabs MetaMo
;;;; core/state_accessors.metta). Resolve names→indices via (GoalIndex …) atoms
;;;; in config.metta, then index-atom into the vector.

(= (getGoal (motivation $goals $modulators) $name)
   (let $idx (match &self (GoalIndex $name $i) $i) (index-atom $goals $idx)))

(= (getModulator (motivation $goals $modulators) $name)
   (let $idx (match &self (ModulatorIndex $name $i) $i) (index-atom $modulators $idx)))

(= (getStimulus (stimulus $values) $name)
   (let $idx (match &self (StimulusIndex $name $i) $i) (index-atom $values $idx)))

;; Backward-compatible 4-arity stimulus constructor
(= (openPsiStimulus $novelty $conduciveness $risk $effort)
   (stimulus ($novelty $conduciveness $risk $effort)))
