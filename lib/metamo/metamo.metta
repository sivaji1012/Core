;;;; metamo.metta
;;;; MetaMo — MetaMotivational Framework on Core/MORK
;;;;
;;;; Implements equation #9 from:
;;;;   Lian & Goertzel 2025 "MetaMo: A Robust Motivational Framework for Open-Ended AGI"
;;;;   AGI 2025 Proceedings (LNAI 16057), Chapter 34, pp. 386–398
;;;;   Embodiment spec: metamo_embodiment_spec.md §3
;;;;
;;;; Equation #9 (incremental self-model blend):
;;;;   x_{t+1} = (1 - α) · x_t  +  α · x*
;;;;   α = α_0 · (1 - g_over^Ind) + β_0 · g_over^Trans
;;;;
;;;; State representation:
;;;;   (MotiveState $goal-id (G $g1 $g2 ...) (M $m1 $m2 ...))
;;;;   G = goal intensity vector (length P)
;;;;   M = modulator vector (length 6 for OpenPsi: valence, arousal, approach,
;;;;       resolution, threshold, securing)
;;;;
;;;; MORK substrate: CountSink via WILLIAM.count reused; blend via grounded Julia
;;;; Scratch spaces: use (with-space ...) for transient evaluation contexts
;;;;
;;;; Entry points:
;;;;   MetaMo.seed!   $space $goal (G ...) (M ...)  → seed initial MotiveState
;;;;   MetaMo.get     $space $goal                  → current MotiveState or NotFound
;;;;   MetaMo.update! $space $goal (G* ...) (M* ...) → apply equation #9
;;;;   MetaMo.alpha   $g-over-ind $g-over-trans      → compute blend rate α
;;;;   MetaMo.stats   $space                         → summary
;;;;
;;;; Import:
;;;;   !(import! &self (library metamo))

;;; ===========================================================================
;;; §1 — Configuration (overridable)
;;; ===========================================================================
;;; α_0 = base blend rate (slow → conservative self-model evolution)
;;; β_0 = transcendence boost to blend rate

(= (MetaMo.Config.Alpha0) 0.1)
(= (MetaMo.Config.Beta0)  0.05)

;;; ===========================================================================
;;; §2 — MotiveState Storage
;;; ===========================================================================
;;; Dictionary: (MotiveState $goal (G $g1 $g2 ...) (M $m1 $m2 ...)) atoms.
;;; Read/write via add-atom/remove-atom on the provided space.

;;; Seed: add initial MotiveState for a goal.
(: MetaMo.seed! (-> Atom Atom Atom Atom Atom))
(= (MetaMo.seed! $space $goal $g-vec $m-vec)
   (add-atom $space (MotiveState $goal $g-vec $m-vec)))

;;; Lookup: returns (MotiveState ...) or NotFound.
;;; Uses match without collapse — for single atoms, _eval_match returns the atom
;;; directly (not wrapped in a list), so no car-atom needed.
(: MetaMo.get (-> Atom Atom Atom))
(= (MetaMo.get $space $goal)
   (let $state (match $space (MotiveState $goal $gs $ms) (MotiveState $goal $gs $ms))
     (if (== $state ()) NotFound $state)))

;;; Size: how many MotiveState atoms exist.
;;; Use scalar template 'yes' to avoid the single-match ambiguity in _eval_match
;;; (1 match returns the atom directly; scalar template forces [yes] via collapse).
(= (MetaMo.size $space)
   (size-atom (collapse (match $space (MotiveState $mg $mg2 $mg3) yes))))

;;; Remove current state (internal helper for update cycle).
(= (MetaMo.remove-state! $space $goal $gs $ms)
   (remove-atom $space (MotiveState $goal $gs $ms)))

;;; ===========================================================================
;;; §3 — Blend Rate (equation #9, α term)
;;; ===========================================================================
;;; α = α_0 · (1 - g_over^Ind) + β_0 · g_over^Trans
;;;
;;; g_over^Ind  ∈ [0,1]: individuation overshoot (high = slow blend, preserve self-model)
;;; g_over^Trans ∈ [0,1]: transcendence drive (high = faster adaptive growth)
;;;
;;; Stub defaults: g_over_ind=0, g_over_trans=0 → α = α_0 (conservative base rate)

(: MetaMo.alpha (-> Number Number Number))
(= (MetaMo.alpha $g-over-ind $g-over-trans)
   (+ (* (MetaMo.Config.Alpha0) (- 1 $g-over-ind))
      (* (MetaMo.Config.Beta0)  $g-over-trans)))

;;; ===========================================================================
;;; §4 — Vector Blend (equation #9, x_{t+1} = (1-α)·x_t + α·x*)
;;; ===========================================================================
;;; MetaMo.blend-vec is grounded in Julia — operates on (G g1 g2 ...) atoms.
;;; Returns a new (G ...) or (M ...) atom with blended numeric components.
;;; The first element (the tag G or M) is preserved.
(: MetaMo.blend-vec (-> Number Atom Atom Atom))

;;; ===========================================================================
;;; §5 — Full Update Cycle (equation #9 applied to both G and M)
;;; ===========================================================================
;;;
;;; (MetaMo.update! &space goal (G* g1* g2* ...) (M* m1* m2* ...))
;;;
;;; 1. Read current state x_t from $space
;;; 2. Compute α (stub: g_over = 0)
;;; 3. Apply x_{t+1} = (1-α)·x_t + α·x* to both G and M vectors
;;; 4. Replace old MotiveState with new one

(: MetaMo.update! (-> Atom Atom Atom Atom Atom))
(= (MetaMo.update! $space $goal $g-star $m-star)
   (let* (
     ($state (MetaMo.get $space $goal))
     ((MotiveState $goal $g-cur $m-cur) $state)
     ($alpha (MetaMo.alpha 0 0))
     ($g-new (MetaMo.blend-vec $alpha $g-cur $g-star))
     ($m-new (MetaMo.blend-vec $alpha $m-cur $m-star))
     ($_ (MetaMo.remove-state! $space $goal $g-cur $m-cur))
   )
   (MetaMo.seed! $space $goal $g-new $m-new)))

;;; ===========================================================================
;;; §6 — Introspection
;;; ===========================================================================

;;; Goal intensity at index i (0-based) within the G vector.
(= (MetaMo.goal-strength $space $goal $i)
   (let* (($state (MetaMo.get $space $goal))
          ((MotiveState $goal $g-vec $_) $state))
     (index-atom $g-vec $i)))

;;; Modulator value at index i within the M vector.
(= (MetaMo.modulator $space $goal $i)
   (let* (($state (MetaMo.get $space $goal))
          ((MotiveState $goal $_ $m-vec) $state))
     (index-atom $m-vec $i)))

;;; Summary stats.
(= (MetaMo.stats $space)
   (let* (($n (MetaMo.size $space))
          ($a (MetaMo.alpha 0 0)))
     (MetaMo.Summary $n $a)))
