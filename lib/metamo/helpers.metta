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

;; ── M2: scalar + vector helpers (pure MeTTa; upstream had these as py-call) ──

;; max(0, v)
(= (positivePart $v) (max 0.0 $v))

;; |v|
(= (absNumber $v) (abs $v))

;; (head tail) destructure pair — upstream `decons` (Core has decons-atom; this
;; form lets `let*` bind `(($h $t) (decons $l))`).
(= (decons $l) ((car-atom $l) (cdr-atom $l)))

;; elementwise clamp to [lo,hi]
(= (clipVector $arr $lo $hi) (map-atom $arr $x (clamp $x $lo $hi)))

;; elementwise scale
(= (scaleArray $arr $factor) (map-atom $arr $x (* $x $factor)))

;; mean of the elements of $arr at the positions listed in $indices
(= (meanAtIndices $arr $indices)
   (/ (foldl-atom $indices 0.0 $acc $i (+ $acc (index-atom $arr $i)))
      (size-atom $indices)))

;; ── M3: vector helpers for the bimonad / distance (pure MeTTa) ──

;; elementwise a+b (recursive; base case empty list)
(= (vectorAdd $a $b)
   (if (== $a ())
       ()
       (let* ((($ah $at) (decons $a)) (($bh $bt) (decons $b)))
         (cons-atom (+ $ah $bh) (vectorAdd $at $bt)))))

;; elementwise a-b
(= (listDifference $a $b)
   (if (== $a ())
       ()
       (let* ((($ah $at) (decons $a)) (($bh $bt) (decons $b)))
         (cons-atom (- $ah $bh) (listDifference $at $bt)))))

;; Euclidean norm: sqrt(Σ xᵢ²)
(= (norm $arr) (sqrt (foldl-atom $arr 0.0 $acc $x (+ $acc (* $x $x)))))

;; ── M4: dynamics helpers (pure MeTTa; index-conditional via member/min/max) ──

;; clip scalar to [lo,hi] (upstream npClip)
(= (npClip $v $lo $hi) (clamp $v $lo $hi))

;; (1-α)·a + α·b elementwise
(= (blendArrays $a $b $alpha)
   (vectorAdd (scaleArray $a (- 1.0 $alpha)) (scaleArray $b $alpha)))

;; set element at position $idx to $val
(= (setAtIndex $arr $idx $val) (_setAtIdx $arr 0 $idx $val))
(= (_setAtIdx $arr $pos $idx $val)
   (if (== $arr ())
       ()
       (let* ((($h $t) (decons $arr)))
         (cons-atom (if (== $pos $idx) $val $h) (_setAtIdx $t (+ $pos 1) $idx $val)))))

;; add $boost (capped at $maxVal) to elements whose position is in $indices
(= (boostAtIndices $arr $indices $boost $maxVal) (_boostAtIdx $arr 0 $indices $boost $maxVal))
(= (_boostAtIdx $arr $pos $indices $boost $maxVal)
   (if (== $arr ())
       ()
       (let* ((($h $t) (decons $arr))
              ($nh (if (member $pos $indices) (min $maxVal (+ $h $boost)) $h)))
         (cons-atom $nh (_boostAtIdx $t (+ $pos 1) $indices $boost $maxVal)))))

;; project goals into the safe region: floor goals[weightIdx] at thetaSafe, then
;; scale the whole vector down if ‖goals‖ exceeds gMax.
(= (projectGoalsToSafe $goals $weightIdx $thetaSafe $gMax)
   (let* (
     ($g1 (setAtIndex $goals $weightIdx (max (index-atom $goals $weightIdx) $thetaSafe)))
     ($n (norm $g1))
   )
     (if (> $n $gMax) (scaleArray $g1 (/ $gMax $n)) $g1)))
