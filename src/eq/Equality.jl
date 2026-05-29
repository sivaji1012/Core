# packages/Core/src/eq/Equality.jl
#
# Single source of truth for atom equality across Core. Drafted on the
# prototype/stream-eval-and-alpha branch. The thesis: "did this rule match?"
# and "are these two atoms the same?" are one predicate at two scopes, so
# every consumer (rewriter unify-test, =alpha primitive, assertAlphaEqual,
# rule cache key, MORK byte encoding) routes through the same function.
#
# This file is the BOTTOM of that stack. Three things live here:
#
#   is_var(x)         — does x denote a MeTTa variable, regardless of
#                       which surface encoding ($x parser form vs
#                       __var_x storage form)?
#
#   _canonical_var(x) — normalise a variable Symbol to its parser form
#                       ($x). Removes the "$x and __var_x key to
#                       different dict symbols" class of bug — see the
#                       diff in Eval.jl _unify!/_apply_bindings/_eval_let
#                       on this branch for live examples.
#
#   atom_equal(a, b)  — alpha-equivalent structural equality. Recurses
#                       into Vectors. Variables alpha-equal under a
#                       consistent bidirectional renaming.
#
#   alpha_rename(x)   — canonicalise variables to $_a1, $_a2, …
#                       in left-to-right encounter order. Two alpha-equivalent
#                       expressions produce identical alpha_rename output,
#                       so this is the basis for an alpha-respecting hash
#                       (rule_cache key, MORK encoding cross-check).
#
# Deliberately uncoupled from MORK's byte trie. MORK's __var_NAME bytes
# are a *realisation* of this equivalence — the three-way agreement test
# in test/test_alpha_three_way_agreement.jl asserts that
# atom_equal(a, b)  ⇔  alpha_rename(a) == alpha_rename(b)
#                   ⇔  MORK encode-then-equal(a, b)
# Today that test is expected to fail (drift between the three).

"""
    is_var(x) :: Bool

True iff x is a Symbol denoting a MeTTa variable, in either encoding:
- Parser form:  Symbol("\$x")
- Storage form: Symbol("__var_x")
"""
is_var(@nospecialize(x)) =
    x isa Symbol && (startswith(string(x), "\$") || startswith(string(x), "__var_"))

"""
    _canonical_var(s::Symbol) :: Symbol

Normalise a variable Symbol to its parser form (`\$name`), regardless of
which surface encoding it arrived in. Non-variable Symbols are returned
unchanged.

This is the lever the "single equality" thesis pulls. Every place that
keys a dict by variable identity should canonicalise first; otherwise
`\$x` and `__var_x` are two different keys for the same variable.
"""
function _canonical_var(s::Symbol) :: Symbol
    str = string(s)
    startswith(str, "__var_") && return Symbol("\$" * str[7:end])
    s
end
_canonical_var(@nospecialize(x)) = x

"""
    atom_equal(a, b) :: Bool

Alpha-equivalent structural equality between two atoms.

Two atoms are alpha-equal iff:
  - Both Numbers / Bools / Strings of equal value, or
  - Both non-variable Symbols of equal name, or
  - Both Variables under a *consistent bidirectional* renaming (any
    variable can match any other variable, but only one-to-one across
    the whole expression), or
  - Both Vectors of equal length with pairwise alpha-equal children
    under the SAME renaming.

Used by:
  - the rewriter, indirectly via `_unify!`'s symbol-equality fallback
    (so a rule head `(f \$x)` matches `(f \$y)` correctly)
  - the `=alpha` grounded primitive
  - the `assertAlphaEqual` stdlib rule (after assertEqual fix)
  - the three-way agreement test (must agree with `alpha_rename`
    equality and with a MORK encode-then-equal round-trip)
"""
function atom_equal(@nospecialize(a), @nospecialize(b)) :: Bool
    _atom_equal(a, b, Dict{Symbol,Symbol}(), Dict{Symbol,Symbol}())
end

function _atom_equal(@nospecialize(a), @nospecialize(b),
                     ab::Dict{Symbol,Symbol}, ba::Dict{Symbol,Symbol}) :: Bool
    av = is_var(a)
    bv = is_var(b)
    if av && bv
        ca = _canonical_var(a)::Symbol
        cb = _canonical_var(b)::Symbol
        prev_ab = get(ab, ca, nothing)
        prev_ba = get(ba, cb, nothing)
        if prev_ab === nothing && prev_ba === nothing
            ab[ca] = cb
            ba[cb] = ca
            return true
        end
        return prev_ab === cb && prev_ba === ca
    end
    # one is var, the other isn't — never alpha-equal (no operator-
    # precedence trap: this is a single statement, no || mixed with &&)
    if av || bv
        return false
    end
    if a isa Vector && b isa Vector
        length(a) == length(b) || return false
        return all(i -> _atom_equal(a[i], b[i], ab, ba), eachindex(a))
    end
    a == b
end

"""
    alpha_rename(expr) → expr

Return a canonical-form copy of `expr` with all variables renamed to
`\$_a1`, `\$_a2`, … in left-to-right encounter order. Two alpha-equivalent
expressions produce IDENTICAL alpha_rename output, so:

    atom_equal(a, b)  ⇔  alpha_rename(a) == alpha_rename(b)

is an invariant the three-way agreement test exploits.

Non-variable atoms are returned unchanged. Vectors are recursively
rewritten. The counter and renaming dict are threaded explicitly (no
hidden global state) so the function is reentrant and safe under
concurrent calls.
"""
function alpha_rename(@nospecialize(expr))
    counter = Ref(0)
    seen    = Dict{Symbol,Symbol}()
    _alpha_rename(expr, seen, counter)
end

function _alpha_rename(@nospecialize(x), seen::Dict{Symbol,Symbol}, counter::Ref{Int})
    if is_var(x)
        ca = _canonical_var(x)::Symbol
        return get!(seen, ca) do
            counter[] += 1
            Symbol("\$_a", counter[])
        end
    elseif x isa Vector
        return Any[_alpha_rename(c, seen, counter) for c in x]
    else
        return x
    end
end

export is_var, atom_equal, alpha_rename, _canonical_var
