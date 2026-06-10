;;;; instance.metta — the MOSES genotype VALUE (port of metta-moses representation/instance.metta).
;;;; An Instance is a vector of knob settings: `(mkInst (s0 s1 … sk))` where each si is the
;;;; chosen setting (a small Number) for knob i. A representation maps these settings onto an
;;;; exemplar program tree to yield a candidate program (the getCandidate tree-walk — M1c).
;;;;
;;;; CORE-DIALECT note: upstream wraps a `(List Number)` ADT and carries instToExpr/exprToInst/
;;;; listToExpr conversion helpers. Those are DROPPED here — Core lists ARE ()-expressions, so an
;;;; instance is just `(mkInst (…))` over a native list; no Cons/Nil↔Expression marshalling.
;;;; ScoredInstance (mkSInst (mkPair inst score)) is deferred to scoring (M3, needs cScore).

;; accessors
(= (Inst.elems  (mkInst $xs)) $xs)
(= (Inst.length (mkInst $xs)) (List.length $xs))
(= (Inst.get    (mkInst $xs) $i) (List.getByIdx $xs $i))     ;; 0-based knob setting

;; a Pair-wrapped scored instance, accessors (the pair part is dialect-free; the score
;; type lands in M3). getInst / getSInstScore mirror upstream names.
(= (getInst        (mkSInst (mkPair $inst $score))) $inst)
(= (getSInstScore  (mkSInst (mkPair $inst $score))) $score)
