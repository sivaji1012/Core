;;;; ActPC-Chem.metta — ActPC-Chem library entry point (PLN-style, like lib/pln/pln.metta).
;;;;
;;;; ActPC-Chem: Discrete Active Predictive Coding for goal-guided algorithmic
;;;; chemistry of metagraph rewrite rules — a candidate cognitive kernel for
;;;; Hyperon/PRIMUS (Goertzel, arXiv:2412.16547). Spec: docs/specs/actpc_chem_spec.md.
;;;;
;;;; Status (migrated from packages/PRIMUS_Core/lib/actpc/, dialect-adapted, then
;;;; completed against the spec):
;;;;   AC1 ✅ weight update   AC2 ✅ softmax-τ (+ greedy best-rule)   AC3 ✅ distance error
;;;;   AC4 ✅ chaining   AC5 ✅ decay (replace-in-place)   AC6 ✅ PLN projection
;;;;   AC7 ⚠ fitness only (evolve needs MOSES)   AC10 ✅ (trivially local)
;;;;   AC8/AC9/AC11 — not here (AC8 = the neural↔symbolic bridge / future work)
;;;;
;;;; Cross-algorithm neighbor coupling lives in bridges.metta (NOT imported here):
;;;;   ECAN boost-sti! WIRED; MOSES evolve / Fluid diffusion DEFERRED-PENDING (deps
;;;;   not yet in Core). Load bridges.metta explicitly alongside (library ecan).
;;;;
;;;; Import:  !(import! &self (library ActPC-Chem))

!(import! &self "chemistry.metta")
