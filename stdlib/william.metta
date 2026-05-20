; william.metta — WILLIAM pattern mining (pure MeTTa rules for MeTTaCore)
;
; Thin MeTTa orchestration layer on MORK exec atoms.
; Heavy lifting is in MORK substrate sinks:
;   CountSink → pattern frequency counting
;   AUSink    → anti-unification / least-general generalization (LGG)
;   HeadSink  → top-k patterns by lexicographic order
;
; Grounded Julia side (registered in WilliamPrimitives.jl):
;   compression-score    — structural complexity heuristic ∈ [0,1]
;   william-threshold    — adaptive gain threshold by space load
;   william-heavy-hitters — top-k atoms by compression gain (O(N) scan)
;
; Session 3c: wired into MeTTaCore stdlib (replaces PRIMUS_Core wiring).

; ── Atom size (structural complexity) ────────────────────────────────────────

; Base cases
(= (william-atom-size $x) 1)

; Compound atom: count all sub-atoms recursively
; (= (william-atom-size ($h $t)) ...) — handled by grounded compression-score

; ── Pattern frequency (via CountSink) ────────────────────────────────────────

; Count unique atoms matching $pattern in &self.
(= (william-count $pattern)
   (let $result (collapse (match &self $pattern $pattern))
     (size-atom $result)))

; ── MDL compression gain ─────────────────────────────────────────────────────

; MDL gain = frequency × (size - 1).
; Higher = better candidate for compression dictionary.
(= (william-gain $pattern)
   (let* (($n    (william-count $pattern))
          ($s    (compression-score $pattern)))
     (* $n $s)))

; ── Least-General Generalization (AUSink via exec atom) ──────────────────────

; Anti-unification of two atoms via MORK AUSink.
; Fires one MORK exec step: exec atom writes the LGG to the space.
(= (william-lgg $a $b)
   (let $out (collapse
               (exec 0 (, (= $a $x) (= $b $x))
                       (O (AU $x))))
     (if (== $out ()) Empty $out)))

; ── NCD proxy (using LGG size) ───────────────────────────────────────────────

; Normalised compression distance approximation.
; NCD(a,b) ≈ (size(lgg(a,b)) - min(size(a), size(b))) / max(size(a), size(b))
(= (william-ncd $a $b)
   (let* (($lgg (william-lgg $a $b))
          ($sl  (compression-score $lgg))
          ($sa  (compression-score $a))
          ($sb  (compression-score $b))
          ($mn  (if (<= $sa $sb) $sa $sb))
          ($mx  (if (>= $sa $sb) $sa $sb)))
     (if (== $mx 0) 0
       (/ (- $sl $mn) $mx))))

; ── Top-k frequent patterns ──────────────────────────────────────────────────

; Score and rank a list of candidate patterns by william-gain.
(= (william-topk $candidates $k)
   (let $scored (map-atom $candidates $c
                   (let $g (william-gain $c)
                     (cons-atom $g (cons-atom $c ()))))
     (take-atom $scored $k)))
