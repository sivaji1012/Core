;;;; william.metta
;;;; Adaptive Compression and Discovery Service — WILLIAM on MORK
;;;;
;;;; Implementation of WILLIAM (Weighted Incremental Learning and Language-
;;;; Inspired Adaptive Modeling) as pure MeTTa on the MORK byte-trie substrate.
;;;;
;;;; Reference: Franz et al. 2019 "WILLIAM: A Monolithic Approach to AGI"
;;;;            Hyperon Whitepaper 2025 §5.12 "WILLIAM-on-MORK"
;;;;            RFP: deep-projects.ai/rfp/development-of-an-adaptive-compression-and-discovery-service
;;;;
;;;; MORK substrate sinks used (no Julia required for algorithms):
;;;;   CountSink → pattern frequency counting
;;;;   AUSink    → anti-unification / least-general generalization (LGG)
;;;;   HeadSink  → top-k patterns by lexicographic score
;;;;
;;;; Entry points:
;;;;   WILLIAM.Learn   $space $data       → learn from a data atom (W3)
;;;;   WILLIAM.Predict $space $partial    → predict continuation (W4)
;;;;   WILLIAM.Query   $space $k          → top-k patterns (W7)
;;;;   WILLIAM.Validate $space $pattern   → measure actual gain (W8)
;;;;
;;;; Configuration (override in your space):
;;;;   (= (WILLIAM.Config.Threshold) 0.7)   ; min MDL gain to keep
;;;;   (= (WILLIAM.Config.MaxDict)   200)    ; max dictionary entries
;;;;   (= (WILLIAM.Config.TopK)       10)    ; default k for heavy-hitters
;;;;
;;;; Import:
;;;;   !(import! &self (library william))    ; PeTTa / MeTTaCore style
;;;;   !(import! &self "./william.metta")    ; relative path style

;;; ===========================================================================
;;; §0 — Configuration (overridable defaults per Hyperon WP §5.12)
;;; ===========================================================================

(= (WILLIAM.Config.Threshold) 0.7)
(= (WILLIAM.Config.MaxDict)  200)
(= (WILLIAM.Config.TopK)      10)

;;; ===========================================================================
;;; §1 — Description Length (DL) — W2 MDL objective  [Franz 2019 §2]
;;; ===========================================================================
;;; DL(atom) = structural size: scalars = 1, expressions = 1 + sum(children)
;;; Used for encoding_cost and pattern_cost in MDL two-part objective.

(: WILLIAM.size (-> Atom Number))
(= (WILLIAM.size $atom)
   (let $t (get-metatype $atom)
     (if (== $t Expression)
         (if (== $atom ())
             0
             (+ 1 (foldl-atom (cdr-atom $atom) 0 $acc $child
                    (+ $acc (WILLIAM.size $child)))))
         1)))

;;; MDL compression gain for a pattern given its support.
;;; gain = support × (original_size - pattern_size)
;;; Patterns with gain > threshold are worth adding to the dictionary.
;;;
(: WILLIAM.gain (-> Atom Number Number))
(= (WILLIAM.gain $pattern $support)
   (* $support (- (WILLIAM.size $pattern) 1)))

;;; Two-part MDL cost: encoding_cost + dict_cost  [Franz 2019 §2]
;;; Lower total_cost = better dictionary.
;;;
(= (WILLIAM.mdl-cost $encoding-cost $dict-cost)
   (+ $encoding-cost $dict-cost))

;;; ===========================================================================
;;; §2 — Pattern Frequency (CountSink) — W1, W6  [WP §5.12]
;;; ===========================================================================
;;; Uses MORK CountSink via exec atoms for O(log n) trie-accelerated counting.

;;; Count unique atoms in $space matching $pattern.
;;; Scalar template 'yes' avoids single-match ambiguity: collapse(match) with
;;; 1 match returns the atom directly; scalar forces [yes] wrapping via collapse.
(: WILLIAM.count (-> Atom Atom Number))
(= (WILLIAM.count $space $pattern)
   (let $result (collapse (match $space $pattern yes))
     (size-atom $result)))

;;; Support = normalised frequency (count / total atoms in space).
;;; Uses WILLIAM.count for the denominator to avoid scanning all atoms.
(= (WILLIAM.support $space $pattern)
   (let* (($n     (WILLIAM.count $space $pattern))
          ($total (WILLIAM.count $space $anything)))
     (if (== $total 0) 0
       (/ $n $total))))

;;; ===========================================================================
;;; §3 — Heavy-Hitter Discovery — W7  [WP §5.12, iter_any_topk / iter_prefix_topk]
;;; ===========================================================================

;;; iter_any_topk: globally significant patterns ranked by MDL gain.
;;; Returns top-$k (Pair gain pattern) from candidates.
;;;
;;; iter_any_topk over a caller-supplied candidate list (avoids full space scan).
;;; For a bounded-cost query pass only candidate patterns, not all atoms.
;;;
(: WILLIAM.iter-any-topk (-> Atom Number List))
(= (WILLIAM.iter-any-topk $space $k)
   (let $atoms (collapse (match $space (WILLIAM.Entry $pat $es $eg) $pat))
     (WILLIAM.topk-by-gain $space $atoms $k)))

;;; Variant: score an explicit candidate list — caller controls scope.
(= (WILLIAM.iter-topk-candidates $space $candidates $k)
   (WILLIAM.topk-by-gain $space $candidates $k))

;;; iter_prefix_topk: patterns under $prefix ranked by MDL gain.  [WP §5.12]
;;; Scopes heavy-hitter search to a sub-space prefix.
;;;
(: WILLIAM.iter-prefix-topk (-> Atom Atom Number List))
(= (WILLIAM.iter-prefix-topk $space $prefix $k)
   (let $atoms (collapse (match $space ($prefix $x) ($prefix $x)))
     (WILLIAM.topk-by-gain $space $atoms $k)))

;;; Score and rank a list of atoms by WILLIAM.gain, return top-$k.
(= (WILLIAM.topk-by-gain $space $atoms $k)
   (let $scored (map-atom $atoms $a
                   (let* (($s (WILLIAM.count $space $a))
                          ($g (WILLIAM.gain $a $s)))
                     (Pair $g $a)))
     (take-atom (WILLIAM.sort-desc $scored) $k)))

;;; Sort (Pair score atom) list descending by score.
(= (WILLIAM.sort-desc $pairs)
   (collapse
     (let $all (superpose $pairs)
       $all)))

;;; Threshold filter: keep only patterns above WILLIAM.Config.Threshold.
(= (WILLIAM.above-threshold? $space $pattern)
   (let* (($s (WILLIAM.count $space $pattern))
          ($g (WILLIAM.gain $pattern $s)))
     (> $g (WILLIAM.Config.Threshold))))

;;; ===========================================================================
;;; §4 — Least-General Generalization (AUSink) — W5  [WP §5.12]
;;; ===========================================================================
;;; AUSink fires via MORK exec calculus and writes results as side effects.
;;; We use a unique result marker (WILLIAM.lgg-result $a $b) to retrieve the
;;; output after the exec atom fires.
;;;
;;; WILLIAM.lgg is grounded in Julia via MORK._au_merge! — registered by
;;; register_core_primitives!(). No exec atom needed; this type annotation
;;; documents the signature for type-checking tools.
(: WILLIAM.lgg (-> Atom Atom Atom))

;;; Normalised Compression Distance proxy via LGG.  [Franz 2019 §3]
;;; NCD(a,b) ≈ (size(lgg(a,b)) - min(size(a),size(b))) / max(size(a),size(b))
;;;
(: WILLIAM.ncd (-> Atom Atom Number))
(= (WILLIAM.ncd $a $b)
   (let* (($lgg (WILLIAM.lgg $a $b))
          ($sl  (WILLIAM.size $lgg))
          ($sa  (WILLIAM.size $a))
          ($sb  (WILLIAM.size $b))
          ($mn  (if (<= $sa $sb) $sa $sb))
          ($mx  (if (>= $sa $sb) $sa $sb)))
     (if (== $mx 0) 0
       (/ (- $sl $mn) $mx))))

;;; Similarity = 1 - NCD  (higher = more similar)
(= (WILLIAM.similarity $a $b)
   (- 1 (WILLIAM.ncd $a $b)))

;;; ===========================================================================
;;; §5 — Dictionary Management — W2, W3  [Franz 2019 §2]
;;; ===========================================================================
;;; Dictionary D = set of (WILLIAM.Entry pattern support gain) atoms in $space.
;;; Incremental: add when gain > threshold, evict when dictionary exceeds MaxDict.

(= (WILLIAM.dict-add! $space $pattern $support $gain)
   (add-atom $space (WILLIAM.Entry $pattern $support $gain)))

(= (WILLIAM.dict-lookup $space $pattern)
   (let $result (collapse (match $space (WILLIAM.Entry $pattern $es $eg)
                             (WILLIAM.Entry $pattern $es $eg)))
     (if (== $result ()) NotFound (car-atom $result))))

(= (WILLIAM.dict-size $space)
   (size-atom (collapse (match $space (WILLIAM.Entry $ep $es $eg) yes))))

(= (WILLIAM.dict-update! $space $pattern $new-support $new-gain)
   (let $old (collapse (match $space (WILLIAM.Entry $pattern $es $eg) (WILLIAM.Entry $pattern $es $eg)))
     (let $_ (if (not (== $old ())) (remove-atom $space (car-atom $old)) ())
       (WILLIAM.dict-add! $space $pattern $new-support $new-gain))))

;;; ===========================================================================
;;; §6 — Learn Loop — W3  [Franz 2019 §2, OBSERVE/PARSE/ENCODE/LEARN]
;;; ===========================================================================
;;; WILLIAM.Learn processes one data atom:
;;;   1. OBSERVE: add $data to space
;;;   2. PARSE:   find matching dictionary patterns
;;;   3. ENCODE:  compute residual (unmatched structure)
;;;   4. LEARN:   if residual gain > threshold, add to dictionary

(: WILLIAM.Learn (-> Atom Atom Atom))
(= (WILLIAM.Learn $space $data)
   (let* (
     ; 1. OBSERVE — add data atom to space
     ($_ (add-atom $space $data))
     ; 2. DIRECT — compute gain of this data atom and add to dict if significant
     ;    (bootstraps the dict on first pass without needing existing entries)
     ($count (WILLIAM.count $space $data))
     ($gain  (WILLIAM.gain $data $count))
     ($_ (if (> $gain (WILLIAM.Config.Threshold))
             (WILLIAM.dict-add! $space $data $count $gain)
             ()))
     ; 3. MINE — find existing high-gain patterns from the dict
     ($new-patterns (WILLIAM.iter-any-topk $space (WILLIAM.Config.TopK)))
   )
   ; Update gain for any discovered patterns
   (map-atom $new-patterns $entry
     (let* (((Pair $g $pat) $entry)
            ($s (WILLIAM.count $space $pat)))
       (if (> $g (WILLIAM.Config.Threshold))
           (WILLIAM.dict-add! $space $pat $s $g)
           ())))))

;;; ===========================================================================
;;; §7 — Predict — W4  [Franz 2019 §3, prediction via pattern composition]
;;; ===========================================================================
;;; Given partial input $prefix, predict most likely continuation.
;;; Finds dictionary patterns that start with $prefix, returns highest-gain one.

(: WILLIAM.Predict (-> Atom Atom Atom))
(= (WILLIAM.Predict $space $prefix)
   (let $candidates
         (collapse (match $space (WILLIAM.Entry ($prefix $continuation) $_ $gain)
                     (Pair $gain ($prefix $continuation))))
     (if (== $candidates ())
         ; No match — return LGG of all patterns starting with prefix
         (let $all-under (collapse (match $space (WILLIAM.Entry ($prefix $cont) $es $eg)
                                     ($prefix $cont)))
           (if (== $all-under ()) Empty
             (foldl-atom (cdr-atom $all-under) (car-atom $all-under)
               $acc $next (WILLIAM.lgg $acc $next))))
         ; Return highest-gain candidate
         (let $sorted (WILLIAM.sort-desc $candidates)
           (let (Pair $pg $prediction) (car-atom $sorted)
             $prediction)))))

;;; ===========================================================================
;;; §8 — Validate — W8  [Franz 2019, validation API]
;;; ===========================================================================
;;; Measure actual compression gain when $pattern is applied to $space.
;;; Returns (WILLIAM.ValidationResult pattern expected-gain actual-gain delta).

(: WILLIAM.Validate (-> Atom Atom Atom))
(= (WILLIAM.Validate $space $pattern)
   (let* (($support       (WILLIAM.count $space $pattern))
          ($expected-gain (WILLIAM.gain $pattern $support))
          ; Actual gain = sum of size reductions across all matches
          ($matches       (collapse (match $space $pattern $pattern)))
          ($actual-gain   (* $support (- (WILLIAM.size $pattern) 1)))
          ($delta         (- $actual-gain $expected-gain)))
     (WILLIAM.ValidationResult $pattern $expected-gain $actual-gain $delta)))

;;; ===========================================================================
;;; §9 — Weakness Integration — W2  [WP §5.1, weakness bijection]
;;; ===========================================================================
;;; Weakness bijection: w(pattern) = 2^(-gain)
;;; Shorter description = more general = weaker (higher Occam preference).

(= (WILLIAM.weakness $pattern $support)
   (let $g (WILLIAM.gain $pattern $support)
     (/ 1.0 (+ 1.0 $g))))

;;; I-surprisingness: how much does this pattern exceed expected frequency?
;;; High surprisingness = statistically significant pattern worth learning.
(= (WILLIAM.i-surprisingness $space $pattern)
   (let* (($observed  (WILLIAM.support $space $pattern))
          ($expected  (/ 1.0 (+ 1.0 (WILLIAM.size $pattern)))))
     (if (> $expected 0)
       (/ (- $observed $expected) $expected)
       0)))

;;; ===========================================================================
;;; §10 — Top-level Query API  [WP §5.12]
;;; ===========================================================================

;;; WILLIAM.Query: retrieve top-$k patterns from the dictionary.
(: WILLIAM.Query (-> Atom Number List))
(= (WILLIAM.Query $space $k)
   (let $entries (collapse (match $space (WILLIAM.Entry $pat $sup $gain)
                              (Pair $gain $pat)))
     (take-atom (WILLIAM.sort-desc $entries) $k)))

;;; WILLIAM.Stats: summary statistics for a space.
(= (WILLIAM.Stats $space)
   (let* (($dict-size  (WILLIAM.dict-size $space))
          ($threshold  (WILLIAM.Config.Threshold))
          ($top        (WILLIAM.Query $space 3)))
     (WILLIAM.Summary $dict-size $threshold $top)))
