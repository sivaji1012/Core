; list.metta — rewritten for flat S-expr substrate + eager evaluator.
;
; CRITICAL NOTE: this is NOT the H-E / canonical-MeTTa idiom. H-E uses
; lazy + interleaved reduction, which makes the cons-pair (\$h . \$t)
; destructuring pattern + lazy-CPS helpers (the function/chain/unify/return
; style) the natural style. PRIMUS's evaluator is EAGER:
;   - the rewriter pre-evaluates rule arguments before the rule fires
;   - the parser treats (\$h . \$t) as a 3-element literal vector
;     [\$h, :., \$t], not as a cons destructuring pattern
;   - the only lazy construct is the `if` special form (`_eval_if`
;     evaluates the condition, then ONLY the taken branch)
;
; The previous list.metta was written in the H-E idiom and was
; DEAD-ON-ARRIVAL on PRIMUS: every recursive clause used (\$h . \$t),
; which `_unify!` could never match against a real list. Single-base-
; clause functions (length/sort/etc.) returned unreduced expressions for
; every non-empty input. Under the streaming-eval branch, divergent
; overlaps (factorial/nth-style: literal-headed clause vs variable-headed
; clause) also surfaced as stack overflows.
;
; This rewrite uses the only pattern that's actually correct against the
; evaluator PRIMUS has: a SINGLE GUARDED CLAUSE per function, recursion
; controlled by `if`, head/tail access via grounded `car-atom` /
; `cdr-atom` / `is-empty`. Single-clause eliminates the overlap class
; entirely; `if` provides the laziness needed for termination.
;
; This file works correctly under both the current single-result
; rewriter and the planned streaming rewriter, because there's no
; second clause to also-fire.

(: foldl-atom (-> Expression Atom Variable Variable Atom %Undefined%))
(: map-atom   (-> Expression Variable Atom Expression))
(: filter-atom (-> Expression Variable Atom Expression))
(: unique-atom (-> Expression Expression))
(: union-atom  (-> Expression Expression Expression))
(: intersection-atom (-> Expression Expression Expression))
(: subtraction-atom  (-> Expression Expression Expression))

(: Nil Expression)
(= Nil ())

(= (length $list)
   (if (is-empty $list)
       0
       (+ 1 (length (cdr-atom $list)))))

(= (append $xs $ys)
   (if (is-empty $xs)
       $ys
       (cons-atom (car-atom $xs) (append (cdr-atom $xs) $ys))))

(= (reverse $list) (reverse-acc $list ()))
(= (reverse-acc $list $acc)
   (if (is-empty $list)
       $acc
       (reverse-acc (cdr-atom $list) (cons-atom (car-atom $list) $acc))))

; nth — guarded recursive clause (was the divergent (nth $list 0)/(nth $list $n) pair)
(= (nth $list $n)
   (if (<= $n 0)
       (car-atom $list)
       (nth (cdr-atom $list) (- $n 1))))

(= (member $x $list)
   (if (is-empty $list)
       False
       (if (== $x (car-atom $list))
           True
           (member $x (cdr-atom $list)))))

(= (sum-list $list) (foldl-atom $list 0 $acc $x (+ $acc $x)))
(= (product-list $list) (foldl-atom $list 1 $acc $x (* $acc $x)))

(= (flatten $list)
   (if (is-empty $list)
       ()
       (append (car-atom $list) (flatten (cdr-atom $list)))))

(= (zip $xs $ys)
   (if (is-empty $xs)
       ()
       (if (is-empty $ys)
           ()
           (cons-atom (cons-atom (car-atom $xs) (cons-atom (car-atom $ys) ()))
                      (zip (cdr-atom $xs) (cdr-atom $ys))))))

; insertion sort — single guarded clauses
(= (sort $list)
   (if (is-empty $list)
       ()
       (insert (car-atom $list) (sort (cdr-atom $list)))))
(= (insert $x $sorted)
   (if (is-empty $sorted)
       (cons-atom $x ())
       (if (<= $x (car-atom $sorted))
           (cons-atom $x $sorted)
           (cons-atom (car-atom $sorted) (insert $x (cdr-atom $sorted))))))
