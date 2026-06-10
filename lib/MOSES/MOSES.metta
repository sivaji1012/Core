;;;; MOSES.metta — MOSES library entry point (port of the iCog metta-moses MeTTaLog
;;;; reimplementation of asmoses / Looks' "Competent Program Evolution").
;;;; Upstream 1:1 reference: ~/JuliaAGI/dev-zone/metta-moses. Research-layer reference
;;;; (scalable MORK-native design): docs/research/papers/Mork/MOSES MORK.pdf.
;;;;
;;;; CORE-DIALECT ADAPTATIONS (vs upstream metta-moses):
;;;;   1. Functions are UNTYPED — drop upstream `(: fn (-> …))` signatures.
;;;;   2. LISTS = Core-native `()`-expressions via car-atom/cdr-atom/cons-atom, NOT the
;;;;      upstream `(Cons $h $t)` ADT (Core's `Nil` is already `(: Nil Expression)`).
;;;;      Recursion = single guarded clause + `if (== $xs ())` (per test_recursive_lists).
;;;;   3. No `py-call` — reimplement upstream Python helpers as Core MeTTa / grounded prims.
;;;;
;;;; Build status (incremental port — see docs/specs / the algorithm queue):
;;;;   M0 ✅ scaffold + Core-native list utilities (this commit)
;;;;
;;;; Import:  !(import! &self (library MOSES))

!(import! &self "utilities.metta")
