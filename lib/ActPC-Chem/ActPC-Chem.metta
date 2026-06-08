;;;; ActPC-Chem.metta — ActPC-Chem library entry point (PLN-style, like lib/pln/pln.metta).
;;;;
;;;; ActPC-Chem: Discrete Active Predictive Coding for goal-guided algorithmic
;;;; chemistry of metagraph rewrite rules — a candidate cognitive kernel for
;;;; Hyperon/PRIMUS (Goertzel, arXiv:2412.16547). Spec: docs/specs/actpc_chem_spec.md.
;;;;
;;;; Migration status (from packages/PRIMUS_Core/lib/actpc/, dialect-adapted):
;;;;   AC1 ✅ weight update   AC2 ⚠ argmax (softmax-τ TODO)   AC3 ✅ per-rule error
;;;;   AC4 ✅ chaining        AC5 ✅ decay   AC6 ✅ PLN projection   AC7 ⚠ fitness only
;;;;   AC10 ✅ (trivially local)   AC8/AC9/AC11 — not migrated (bridge/future work)
;;;;
;;;; Cross-algorithm neighbor coupling (ECAN/MOSES/Fluid) is in bridges.metta,
;;;; which is NOT imported here — load it explicitly once those libs are present.
;;;;
;;;; Import:  !(import! &self (library ActPC-Chem))

!(import! &self "chemistry.metta")
