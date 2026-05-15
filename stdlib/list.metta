; list.metta — List and collection operations as pure MeTTa
; The grounded primitives (foldl-atom, map-atom, filter-atom, unique-atom,
; union-atom, intersection-atom, subtraction-atom) are in AtomOps.jl.
; These are high-level wrappers and convenience functions.
;
; Cross-verified against:
;   CeTTa/lib/stdlib.metta §foldl-atom
;   CeTTa/lib/list.metta
;   hyperon-experimental stdlib.metta

; ── Type declarations ─────────────────────────────────────────────────────────
(: foldl-atom (-> Expression Atom Variable Variable Atom %Undefined%))
(: map-atom   (-> Expression Variable Atom Expression))
(: filter-atom (-> Expression Variable Atom Expression))
(: unique-atom (-> Expression Expression))
(: union-atom  (-> Expression Expression Expression))
(: intersection-atom (-> Expression Expression Expression))
(: subtraction-atom  (-> Expression Expression Expression))

; ── Nil / empty list ─────────────────────────────────────────────────────────
(: Nil Expression)
(= Nil ())

; ── Length ────────────────────────────────────────────────────────────────────
(= (length ()) 0)
(= (length ($head . $tail)) (+ 1 (length $tail)))

; ── Append ────────────────────────────────────────────────────────────────────
(= (append () $ys) $ys)
(= (append ($x . $xs) $ys) (cons-atom $x (append $xs $ys)))

; ── Reverse ───────────────────────────────────────────────────────────────────
(= (reverse $list) (reverse-acc $list ()))
(= (reverse-acc () $acc) $acc)
(= (reverse-acc ($h . $t) $acc) (reverse-acc $t (cons-atom $h $acc)))

; ── Nth element ───────────────────────────────────────────────────────────────
(= (nth $list 0) (car-atom $list))
(= (nth $list $n) (nth (cdr-atom $list) (- $n 1)))

; ── Member check ─────────────────────────────────────────────────────────────
(= (member $x ()) False)
(= (member $x ($h . $t))
   (if (== $x $h) True (member $x $t)))

; ── List sum / product ───────────────────────────────────────────────────────
(= (sum-list $list) (foldl-atom $list 0 $acc $x (+ $acc $x)))
(= (product-list $list) (foldl-atom $list 1 $acc $x (* $acc $x)))

; ── Flatten (one level) ──────────────────────────────────────────────────────
(= (flatten ()) ())
(= (flatten ($h . $t))
   (append $h (flatten $t)))

; ── Zip ───────────────────────────────────────────────────────────────────────
(= (zip () $ys) ())
(= (zip $xs ()) ())
(= (zip ($x . $xs) ($y . $ys))
   (cons-atom ($x $y) (zip $xs $ys)))

; ── Sort (insertion sort for ground atoms) ───────────────────────────────────
(= (sort ()) ())
(= (sort ($h . $t)) (insert $h (sort $t)))
(= (insert $x ()) ($x))
(= (insert $x ($h . $t))
   (if (<= $x $h)
       (cons-atom $x (cons-atom $h $t))
       (cons-atom $h (insert $x $t))))
