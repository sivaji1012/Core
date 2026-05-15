; math.metta — Extended math as pure MeTTa wrappers
; Grounded: +, -, *, /, %, sqrt-math, abs-math, etc. (in Primitives.jl)
; These are MeTTa-level aliases and higher-level math functions.

; ── Aliases for grounded math with -math suffix (Mettatron/CeTTa naming) ─────
(= (sqrt $x)  (sqrt-math $x))
(= (abs $x)   (abs-math $x))
(= (log $x)   (log-math $x))
(= (exp $x)   (exp-math $x))
(= (floor $x) (floor-math $x))
(= (ceil $x)  (ceil-math $x))
(= (round $x) (round-math $x))
(= (trunc $x) (trunc-math $x))
(= (pow $x $n) (pow-math $x $n))

(= (sin $x)   (sin-math $x))
(= (cos $x)   (cos-math $x))
(= (tan $x)   (tan-math $x))
(= (asin $x)  (asin-math $x))
(= (acos $x)  (acos-math $x))
(= (atan $x)  (atan-math $x))

(= (isnan $x) (isnan-math $x))
(= (isinf $x) (isinf-math $x))

; ── Derived math ─────────────────────────────────────────────────────────────
(= (square $x) (* $x $x))
(= (cube $x)   (* $x (* $x $x)))

(= (max $a $b) (if (>= $a $b) $a $b))
(= (min $a $b) (if (<= $a $b) $a $b))

(= (clamp $x $lo $hi) (max $lo (min $x $hi)))

; ── Boolean from comparisons ─────────────────────────────────────────────────
(= (between $lo $x $hi) (and (>= $x $lo) (<= $x $hi)))

(= (zero? $x) (== $x 0))
(= (positive? $x) (> $x 0))
(= (negative? $x) (< $x 0))
(= (even? $x) (== (% $x 2) 0))
(= (odd? $x)  (not (even? $x)))
