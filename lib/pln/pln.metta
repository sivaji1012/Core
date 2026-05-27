;; lib/pln/pln.metta — PLN library entry point.
;;
;; PLN: Probabilistic Logic Networks (Goertzel, Iklé, Wang).
;; Truth_* formulas (PLN book), |- inference rules, PLN.Derive engine.
;;
;; Adopted from packages/PRIMUS_Core/lib/pln/ (mature reference impl).
;; MOSES_PatternMiner.metta is intentionally NOT loaded here — it depends on
;; MOSES and will be wired in when packages/Core/lib/moses/ lands.

!(import! &self "stv.metta")
!(import! &self "pln_core_logic.metta")
