; core.metta — Core MeTTa standard library
; Pure MeTTa rules, hot-reloadable, introspectable via (match &self (= ...) ...)
;
; Cross-verified against:
;   CeTTa/lib/stdlib.metta
;   hyperon-experimental/lib/src/metta/runner/stdlib/stdlib.metta
;   PeTTa/lib/lib_he.metta (HE-MeTTa compatibility)
;   MeTTa-Compiler/src/backend/eval/control_flow.rs
;   docs/research/metta-language-spec.md

; ── Type declarations ─────────────────────────────────────────────────────────
(: = (-> $t $t %Undefined%))
(: if (-> Bool Atom Atom $t))
(: if-equal (-> Atom Atom Atom Atom %Undefined%))
(: noeval (-> Atom Atom))
(: atom-subst (-> Atom Variable Atom Atom))
(: if-decons-expr (-> Expression Variable Variable Atom Atom %Undefined%))
(: if-error (-> Atom Atom Atom %Undefined%))
(: return-on-error (-> Atom Atom %Undefined%))
(: ErrorType Type)
(: Error (-> Atom Atom ErrorType))
(: Empty (-> Atom))
(: NotReducible Atom)
(: id (-> $t $t))
(: not (-> Bool Bool))
(: or (-> Bool Bool Bool))
(: and (-> Bool Bool Bool))

; ── Boolean / conditional ─────────────────────────────────────────────────────
; Per CeTTa stdlib.metta lines 354-355 and MeTTa spec §Special Expressions

(= (if True $then $else) $then)
(= (if False $then $else) $else)

(= (if-equal $a $b $then $else)
   (if (== $a $b) $then $else))

; ── Identity and no-eval ──────────────────────────────────────────────────────
; Per CeTTa stdlib.metta and hyperon-experimental stdlib.metta

(= (id $x) $x)

(= (noeval $x) $x)

(= (atom-subst $atom $var $templ)
   (function
     (chain (eval (noeval $atom)) $var
       (return $templ))))

; ── Error handling ────────────────────────────────────────────────────────────
; Per CeTTa stdlib.metta §Error handling and hyperon-experimental

(= (if-error $atom $then $else)
   (function
     (eval
       (if-equal $atom ()
         (return $else)
         (chain (decons-atom $atom) $list
           (unify $list ($head $tail)
             (eval (if-equal $head Error (return $then) (return $else)))
             (return $else)))))))

(= (return-on-error $result $next)
   (if-error $result $result $next))

; ── Expression deconstruction helpers ────────────────────────────────────────
; Per CeTTa stdlib.metta lines 379-388

(= (if-decons-expr $atom $head $tail $then $else)
   (function
     (eval
       (if-equal $atom ()
         (return $else)
         (chain (decons-atom $atom) $list
           (unify $list ($head $tail)
             (return $then)
             (return $else)))))))

; ── Type predicates (MeTTa-level wrappers) ───────────────────────────────────
; Grounded: get-metatype, is-number, is-symbol, is-variable, is-expression

(= (is-function (-> $a $b)) True)
(= (is-function $x) False)

; ── Quoting ───────────────────────────────────────────────────────────────────
; Per hyperon-experimental and CeTTa

(= (unquote (quote $atom)) $atom)

; ── HE-MeTTa compatibility (PeTTa lib_he.metta) ──────────────────────────────

(= (if-equal2 $a $b $then $else)
   (if (== $a $b) $then $else))

(= (noreduce-eq $a $b) (== $a $b))

(= (match-types $a $b $then $else)
   (if (== $a $b) $then $else))

(= (first-from-pair ($a $b)) $a)

(= (evalc $expression &self)
   (eval $expression))

; ── Assertion helpers (for testing) ──────────────────────────────────────────
; Per CeTTa cverify_compat.metta and hyperon-experimental

(= (assertEqual $a $b)
   (if (== $a $b)
       (assertEqual-passed $a)
       (Error (assertEqual $a $b) AssertionFailed)))

(= (assertAlphaEqual $a $b)
   (if (== $a $b)
       (assertAlphaEqual-passed $a)
       (Error (assertAlphaEqual $a $b) AssertionFailed)))
