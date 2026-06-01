;;;; metamo.metta — MetaMo library entry point (PLN-style, like lib/pln/pln.metta).
;;;;
;;;; MetaMo: A Robust Motivational Framework for Open-Ended AGI (Lian & Goertzel
;;;; 2025, AGI-2025 Ch 34/35). Adopted from the icoglabs MetaMo MeTTa reference
;;;; (~/JuliaAGI/dev-zone/MetaMo), dialect-adapted to Core's MeTTa. See
;;;; docs/specs/metamo_spec.md + metamo_embodiment_spec.md (eqs #1–#11).
;;;;
;;;; Build status (incremental adoption):
;;;;   M1 ✅ foundation (config/state/accessors/helpers) + OpenPsi appraisal Ψ (eq #4)
;;;;   M2 ⏳ MAGUS decision 𝔻 (eq #5/#10/#11) + vector helpers
;;;;   M3 ⏳ pseudo-bimonad F = 𝔻∘Ψ (eq #6) + lax-distributive check
;;;;   M4 ⏳ dynamics: safe region / contraction (eq #7/#8) + incremental blend (eq #9)
;;;;
;;;; Import:  !(import! &self (library metamo))

!(import! &self "config.metta")
!(import! &self "helpers.metta")
!(import! &self "state.metta")
!(import! &self "accessors.metta")
!(import! &self "appraisal.metta")
