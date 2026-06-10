;;;; utilities.metta — list helpers, ported from metta-moses utilities/list-methods.metta
;;;; into Core's NATIVE list idiom: a list is a `()`-expression; recursion is a single
;;;; guarded clause + `if (== $xs ())` over car-atom/cdr-atom (NOT the upstream Cons/Nil
;;;; ADT, which clashes with Core's `Nil = Expression`). Functions UNTYPED (Core dialect).

;; List.foldl f acc (x1 x2 …) = (f (… (f (f acc x1) x2) …) xn)
(= (List.foldl $f $acc $xs)
   (if (== $xs ())
       $acc
       (List.foldl $f ($f $acc (car-atom $xs)) (cdr-atom $xs))))

;; List.foldr f z (x1 … xn) = (f x1 (f x2 (… (f xn z))))
(= (List.foldr $f $z $xs)
   (if (== $xs ())
       $z
       ($f (car-atom $xs) (List.foldr $f $z (cdr-atom $xs)))))

;; List.length
(= (List.length $xs)
   (if (== $xs ())
       0
       (+ 1 (List.length (cdr-atom $xs)))))

;; List.map f (x1 … xn) = (f x1 … f xn)
(= (List.map $f $xs)
   (if (== $xs ())
       ()
       (cons-atom ($f (car-atom $xs)) (List.map $f (cdr-atom $xs)))))

;; List.getByIdx (0-based)
(= (List.getByIdx $xs $i)
   (if (== $i 0)
       (car-atom $xs)
       (List.getByIdx (cdr-atom $xs) (- $i 1))))

;; List.sum / List.member
(= (List.sum $xs) (List.foldl + 0 $xs))
(= (List.member $x $xs)
   (if (== $xs ())
       False
       (if (== $x (car-atom $xs)) True (List.member $x (cdr-atom $xs)))))
