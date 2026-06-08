;;;; chemistry.metta — ActPC-Chem algorithmic-chemistry core.
;;;;
;;;; ActPC-Chem: Discrete Active Predictive Coding as a goal-guided algorithmic
;;;; chemistry of metagraph rewrite rules (Goertzel, arXiv:2412.16547).
;;;; Spec: docs/specs/actpc_chem_spec.md (AC1–AC11).
;;;;
;;;; MIGRATED from packages/PRIMUS_Core/lib/actpc/Chemistry.metta, dialect-adapted
;;;; to Core's MeTTa (PLN-style, single shared space). The speculative
;;;; Emergent*/MultiScale/Quantum/Concentration files were NOT migrated (the spec
;;;; flags them as non-paper-grounded). Cross-algorithm bridges (ECAN boost, MOSES
;;;; evolve, Fluid diffusion) live in bridges.metta and are NOT auto-loaded.
;;;;
;;;; Design: a ChemRule is a first-class atom in &self — the "soup" IS the space.
;;;; Operations use match / collapse / foldl-atom over (ChemRule $p $r $w) atoms.
;;;;
;;;; DIALECT NOTE: functions are intentionally UNTYPED (no `(: fn (-> …))`
;;;; signatures). Core's type checker rejects `(ChemRule …)` as `Expression` at a
;;;; `ChemRule`-typed argument position (a constructor-typing gap), so the original
;;;; PRIMUS_Core annotations are dropped; dispatch is by pattern match.

;; Data tags (documentation; not used as arg types — see DIALECT NOTE).
(: ChemRule Type)
(: Reaction Type)
(: NoReaction Type)

;; clamp — local definition (mirrors lib/pln/stv.metta; defined here so ActPC-Chem
;; loads standalone without pulling in PLN). If co-loaded with PLN, dedup to one.
(= (clamp $v $lo $hi)
   (if (> $v $hi) $hi (if (< $v $lo) $lo $v)))

;; ---------------------------------------------------------------------------
;; Accessors — head destructuring (PLN convention)
;; ---------------------------------------------------------------------------
(= (get-weight (ChemRule $p $r $w)) $w)
(= (get-pattern (ChemRule $p $r $w)) $p)
(= (get-rewrite (ChemRule $p $r $w)) $r)

;; ---------------------------------------------------------------------------
;; AC1 — Weight update:  w_new = clamp(w + η(-ε + ν), 0, w_max)   (η=0.1, w_max=10)
;;   (actpc-update (ChemRule a b 5.0) 0.3 0.8) → (ChemRule a b 5.05)
;; ---------------------------------------------------------------------------
(= (actpc-update (ChemRule $p $r $w) $error $value)
   (let* (($gain (+ (- 0 $error) $value))
          ($new-w (+ $w (* 0.1 $gain))))
     (ChemRule $p $r (clamp $new-w 0.0 10.0))))

;; ---------------------------------------------------------------------------
;; Rule application — pattern match + rewrite
;; ---------------------------------------------------------------------------
(= (apply-rule (ChemRule $pattern $rewrite $weight) $data)
   (if (== $pattern $data)
       (Reaction (ChemRule $pattern $rewrite $weight) $data $rewrite)
       (NoReaction)))

(= (is-reaction-successful (Reaction $rule $data $result)) True)
(= (is-reaction-successful (NoReaction)) False)

(= (reaction-output (Reaction $rule $input $output)) $output)

;; ---------------------------------------------------------------------------
;; AC4 — Rule chaining: output of A feeds input of B (foldl over the soup)
;;   (ChemRule a b 3.0) (ChemRule b c 2.0) in space ⇒ (chem-chain a) → c
;; ---------------------------------------------------------------------------
(= (chem-chain $data)
   (let $rules (collapse (match &self (ChemRule $p $r $w) (ChemRule $p $r $w)))
     (foldl-atom $rules $data $current $rule
       (let* (((ChemRule $p $r $w) $rule))
         (if (== $p $current) $r $current)))))

;; ---------------------------------------------------------------------------
;; AC3 — Per-rule local prediction error + AC1 update over the soup
;;   (chem-step! a 0.8)   ; data=a, instrumental-value=0.8
;; ---------------------------------------------------------------------------
(= (chem-step! $data $value)
   (let $rules (collapse (match &self (ChemRule $p $r $w) (ChemRule $p $r $w)))
     (foldl-atom $rules done $acc $rule
       (let* (((ChemRule $p $r $w) $rule)
              ($reaction (apply-rule (ChemRule $p $r $w) $data))
              ($error (if (is-reaction-successful $reaction)
                          (if (== (reaction-output $reaction) $data) 0.0 1.0)
                          0.5))
              ($updated (actpc-update (ChemRule $p $r $w) $error $value)))
         (add-atom &self $updated)))))

;; ---------------------------------------------------------------------------
;; AC5 — Weight decay (unused rules fade)
;; ---------------------------------------------------------------------------
(= (decay-all-rules!)
   (let $rules (collapse (match &self (ChemRule $p $r $w) (ChemRule $p $r $w)))
     (foldl-atom $rules done $acc $rule
       (let* (((ChemRule $p $r $w) $rule))
         (add-atom &self (ChemRule $p $r (* $w 0.99)))))))

;; ---------------------------------------------------------------------------
;; AC2 — Selection by weight (deterministic top-1; softmax-with-τ is a TODO)
;; ---------------------------------------------------------------------------
(= (best-rule)
   (let $rules (collapse (match &self (ChemRule $p $r $w) (ChemRule $p $r $w)))
     (foldl-atom $rules (ChemRule none none 0.0) $best $rule
       (let* (((ChemRule $bp $br $bw) $best)
              ((ChemRule $rp $rr $rw) $rule))
         (if (> $rw $bw) $rule $best)))))

;; ---------------------------------------------------------------------------
;; AC6 — PLN projection.  ChemRule → Sentence(Implication, stv(w/w_max,0.9), Stamp).
;; Adapted to Core PLN vocabulary (Implication, lowercase stv). Feeding Core's
;; |- chainer directly is a bridge concern (see bridges.metta TODO).
;;   (chem-rule-to-pln (ChemRule a b 5.0))
;;     → (Sentence (Implication a b) (stv 0.5 0.9) (Stamp chem))
;; ---------------------------------------------------------------------------
(= (chem-rule-to-pln (ChemRule $pattern $rewrite $weight))
   (Sentence (Implication $pattern $rewrite) (stv (/ $weight 10.0) 0.9) (Stamp chem)))

;; is-consistent?: low strength + high confidence ⇒ contradiction.
(= (is-consistent? (Sentence $content (stv $s $c) $stamp))
   (if (and (< $s 0.1) (> $c 0.5)) False True))

;; validate-rule-combo: PLN consistency check on the second rule's projection.
(= (validate-rule-combo $rule1 $rule2)
   (is-consistent? (chem-rule-to-pln $rule2)))

;; ---------------------------------------------------------------------------
;; AC7 — MOSES fitness (fitness = weight). Evolution itself (evolve-soup!) needs
;; MOSES `evolve-forward`, which is not yet in Core → see bridges.metta.
;; ---------------------------------------------------------------------------
(= (rule-fitness (ChemRule $p $r $w)) $w)

;; ---------------------------------------------------------------------------
;; Goal / instrumental value (read cognitive pressure from the space)
;; ---------------------------------------------------------------------------
(= (get-cognitive-pressure)
   (match &self (Concentration Tension $v) $v))

;; get-instrumental-value: MetaMo-style value signal; 0.5 (neutral) if absent.
(= (get-instrumental-value)
   (let $pressure (collapse (match &self (Concentration Tension $v) $v))
     (if (== $pressure ()) 0.5 (car-atom $pressure))))

;; ---------------------------------------------------------------------------
;; WILLIAM → ChemRule: a discovered pattern becomes a rule (identity rewrite).
;; ---------------------------------------------------------------------------
(= (william-to-chemrule $pattern $score)
   (add-atom &self (ChemRule $pattern $pattern (* $score 10.0))))

;; ---------------------------------------------------------------------------
;; Core cognitive tick (chain → step → decay). NO ECAN/MOSES coupling here —
;; the neighbor-integrated tick lives in bridges.metta.
;;   (chem-tick! a)
;; ---------------------------------------------------------------------------
(= (chem-tick! $data)
   (let* (($result (chem-chain $data))
          ($value (get-instrumental-value))
          ($step (chem-step! $data $value))
          ($decay (decay-all-rules!)))
     $result))

;; ---------------------------------------------------------------------------
;; Soup state publishing (canonical Sentence/stv/Stamp, like PLN/MetaMo/ECAN)
;; ---------------------------------------------------------------------------
(= (publish-soup-state! $activity $tick-id)
   (add-atom &self (Sentence (ChemSoupActivity) (stv $activity 0.9) (Stamp $tick-id))))

(= (get-soup-activity)
   (let $results (collapse (match &self (Sentence (ChemSoupActivity) (stv $s $c) $st) $s))
     (if (== $results ()) 0.0 (car-atom $results))))

(= (soup-rule-count)
   (let $rules (collapse (match &self (ChemRule $p $r $w) 1))
     (foldl-atom $rules 0 $acc $x (+ $acc $x))))
