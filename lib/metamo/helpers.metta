;;;; helpers.metta — numeric helpers. The icoglabs upstream implements these via
;;;; (py-call helpers.X) into Python/numpy; Core has no Python runtime, so they
;;;; are reimplemented in PURE MeTTa here (Core's math.metta provides exp / sqrt
;;;; / min / max / log). M1 ships the scalar helpers used by appraisal; vector
;;;; helpers (clipVector/scaleArray/parallelMerge/…) arrive with the decision +
;;;; dynamics layers.

;; e^x
(= (expNum $x) (exp $x))

;; logistic sigmoid 1/(1+e^-x)
(= (sigmoidNum $x) (/ 1.0 (+ 1.0 (exp (* -1.0 $x)))))
