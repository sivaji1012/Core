;;;; bridges.metta — ActPC-Chem ↔ neighbor-algorithm coupling (paper Figure-3 synergy).
;;;;
;;;; NOT auto-loaded by ActPC-Chem.metta — the chem core stays standalone. Load this
;;;; explicitly ALONGSIDE the neighbor libraries (both must be present first):
;;;;   !(import! &self (library ecan))
;;;;   !(import! &self (library ActPC-Chem))
;;;;   !(import! &self (library ActPC-Chem bridges))
;;;;
;;;; Wired NOW: ECAN (boost-sti! is in Core lib/ecan). DEFERRED-PENDING (dependency
;;;; not yet in Core): MOSES evolve-forward (no lib/moses), Fluid diffusion (no fluid
;;;; primitives). The chem-side hooks for those (rule-fitness) are already in
;;;; chemistry.metta, so wiring is a one-liner once the deps land.

;; ── ECAN: rule reactivity → attention. Boost the STI of every rule that fires on
;; `$data` (weight-proportional), coupling chem dynamics to ECAN's attention economy.
(= (boost-successful-rules! $data)
   (let $rules (collapse (match &self (ChemRule $p $r $w) (ChemRule $p $r $w)))
     (foldl-atom $rules done $acc $rule
       (let* (((ChemRule $p $r $w) $rule))
         (if (== $p $data)
             (boost-sti! (ChemRule $p $r $w) (* $w 10.0))
             done)))))

;; ── Full neighbor-integrated cognitive tick: chain → step → ECAN-boost → decay.
;; (chem-tick! in chemistry.metta is the standalone core tick; this is the
;; ECAN-coupled variant. Self-supervised actual = chain output, as in chem-tick!.)
(= (chem-cognitive-tick! $data)
   (let* (($result (chem-chain $data))
          ($value (get-instrumental-value))
          ($step (chem-step! $data $result $value))
          ($boost (boost-successful-rules! $data))
          ($decay (decay-all-rules!)))
     $result))

;; ── MOSES: evolve the rule population (DEFERRED — needs lib/moses evolve-forward).
;; rule-fitness (= weight) is ready in chemistry.metta; wire when lib/moses lands:
;;   (= (evolve-soup! $gens)
;;      (evolve-forward (collapse (match &self (ChemRule $p $r $w) (ChemRule $p $r $w)))
;;                      rule-fitness $gens))

;; ── Fluid ECAN: couple symbolic concentrations to fluid dynamics (DEFERRED).
;; apply-grounded-diffusion! needs get-concentration-map / incompressible-fluid-step,
;; not yet present in Core lib/ecan. Wire when the fluid prims land.
