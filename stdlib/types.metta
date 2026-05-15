; types.metta — Type system declarations for Core stdlib
; Per MeTTa language spec §Elementary Types and §Type Assignment
; Cross-verified against hyperon-experimental stdlib.metta type section

; ── Elementary meta-types ────────────────────────────────────────────────────
(: Type     Type)
(: Atom     Type)
(: Symbol   Type)
(: Variable Type)
(: Expression Type)
(: Grounded Type)
(: Bool     Type)
(: Number   Type)
(: String   Type)
(: SpaceType Type)
(%Undefined% Type)

; ── Bool values ──────────────────────────────────────────────────────────────
(: True  Bool)
(: False Bool)

; ── Error types ──────────────────────────────────────────────────────────────
(: ErrorType Type)
(: ErrorDescription Type)
(: Error (-> Atom Atom ErrorType))
(: BadType (-> Type Type ErrorDescription))
(: BadArgType (-> Number Type Type ErrorDescription))
(: IncorrectNumberOfArguments ErrorDescription)
(: StackOverflow ErrorDescription)
(: NoReturn ErrorDescription)
(: AssertionFailed ErrorDescription)

; ── Space type ────────────────────────────────────────────────────────────────
(: new-space  (-> SpaceType))
(: add-atom   (-> SpaceType Atom (->)))
(: remove-atom (-> SpaceType Atom (->)))
(: get-atoms  (-> SpaceType Expression))
(: match      (-> SpaceType Atom Atom %Undefined%))

; ── Core atom ops type sigs ───────────────────────────────────────────────────
(: cons-atom    (-> Atom Expression Atom))
(: decons-atom  (-> Expression Atom))
(: car-atom     (-> Expression Atom))
(: cdr-atom     (-> Expression Expression))
(: size-atom    (-> Expression Number))
(: index-atom   (-> Expression Number Atom))
(: min-atom     (-> Expression Number))
(: max-atom     (-> Expression Number))
(: unique-atom  (-> Expression Expression))
(: union-atom   (-> Expression Expression Expression))
(: intersection-atom (-> Expression Expression Expression))
(: subtraction-atom  (-> Expression Expression Expression))
(: foldl-atom   (-> Expression Atom Variable Variable Atom %Undefined%))
(: map-atom     (-> Expression Variable Atom Expression))
(: filter-atom  (-> Expression Variable Atom Expression))

; ── Arithmetic type sigs ─────────────────────────────────────────────────────
(: +  (-> Number Number Number))
(: -  (-> Number Number Number))
(: *  (-> Number Number Number))
(: /  (-> Number Number Number))
(: %  (-> Number Number Number))
(: ^  (-> Number Number Number))
(: <  (-> Number Number Bool))
(: >  (-> Number Number Bool))
(: <= (-> Number Number Bool))
(: >= (-> Number Number Bool))
(: == (-> $t $t Bool))

; ── String ops ───────────────────────────────────────────────────────────────
(: repr   (-> $t String))
(: parse  (-> String Atom))

; ── Control flow (grounded) ──────────────────────────────────────────────────
(: eval     (-> Atom Atom))
(: evalc    (-> Atom SpaceType Atom))
(: chain    (-> Atom Variable Atom %Undefined%))
(: function (-> Atom Atom))
(: return   (-> $t $t))
(: collapse (-> Atom Expression))
(: superpose (-> Expression %Undefined%))
(: let      (-> Variable Atom Atom %Undefined%))
(: case     (-> Atom Expression %Undefined%))
(: unify    (-> Atom Atom Atom Atom %Undefined%))

; ── I/O ───────────────────────────────────────────────────────────────────────
(: println! (-> $t (->)))
(: trace!   (-> $t $t))
