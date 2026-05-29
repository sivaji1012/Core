# test/test_alpha_three_way_agreement.jl
#
# Prototype branch test — EXPECTED to fail today.
#
# Thesis: alpha-equivalence has one definition. The three places that
# currently implement it (the Equality.atom_equal we just added, the
# stdlib `==`-via-`assertAlphaEqual` path, and MORK's __var_NAME byte
# encoding) MUST agree on every input pair. Drift between them is the
# whole point we're consolidating.
#
# Today the three implementations disagree. That's what this file proves.
# Once Decision 2 is shipped (atom-layer normalization, MORK encoding as
# the *realization* not a second oracle), every assertion here should
# flip from `@test_broken` to `@test`. The flip is the proof the
# consolidation worked.

using Test
using MeTTaCore
using MeTTaCore: atom_equal, alpha_rename, from_sexpr, to_sexpr,
                 _alpha_eq, GROUNDED_REGISTRY, new_core_space,
                 register_for_space!, load_stdlib!, run_metta

# A bank of input pairs covering the four interesting cases:
#   1. Trivially equal: same expression
#   2. Alpha-equal: same shape, different var names
#   3. Not equal: different structure
#   4. Mixed encodings: $x form vs __var_x storage form (round-trip risk)
const PAIRS = [
    # (label, a, b, should_be_alpha_equal?)
    ("identical literals",       :foo,                       :foo,                       true),
    ("identical numbers",        42,                         42,                         true),
    ("identical exprs",          Any[:Father, Symbol("\$x")], Any[:Father, Symbol("\$x")], true),
    ("alpha-equal: \$x vs \$y",  Any[:Father, Symbol("\$x")], Any[:Father, Symbol("\$y")], true),
    ("alpha-equal: nested",      Any[:Pair, Symbol("\$a"), Symbol("\$b")],
                                 Any[:Pair, Symbol("\$x"), Symbol("\$y")], true),
    ("not-equal: head differs",  Any[:Father, Symbol("\$x")], Any[:Mother, Symbol("\$x")], false),
    ("not-equal: arity",         Any[:f, Symbol("\$x")],     Any[:f, Symbol("\$x"), Symbol("\$y")], false),
    ("not-equal: literal vs var",Any[:f, 1],                 Any[:f, Symbol("\$x")],     false),
    # The cross-encoding case — same variable, two encodings. If $x and
    # __var_x don't normalise to the same key, this asserts false.
    ("cross-encoding: \$x vs __var_x",
                                 Any[:f, Symbol("\$x")],     Any[:f, Symbol("__var_x")], true),
]

@testset "Three-way alpha-equivalence agreement (PROTOTYPE — expected red on branch)" begin
    S = new_core_space()
    register_for_space!(S)
    load_stdlib!(S)

    for (label, a, b, should_be_equal) in PAIRS
        @testset "$label" begin
            # ── Implementation 1: Equality.atom_equal (the new bottom layer) ──
            r_atom = atom_equal(a, b)

            # ── Implementation 2: alpha_rename-then-equal ──
            # Invariant: atom_equal(a,b) ⇔ alpha_rename(a) == alpha_rename(b).
            # If this diverges from atom_equal, the bottom-layer function is
            # internally inconsistent.
            r_rename = alpha_rename(a) == alpha_rename(b)

            # ── Implementation 3: legacy _alpha_eq (string-string) ──
            # This is the function `=alpha` USED to call. The branch keeps it
            # alive so we can measure drift.
            r_legacy = try
                _alpha_eq(to_sexpr(a), to_sexpr(b))
            catch
                false
            end

            # ── Implementation 4: =alpha grounded primitive (post-prototype routing) ──
            r_grounded_str = GROUNDED_REGISTRY["=alpha"]([to_sexpr(a), to_sexpr(b)])
            r_grounded     = r_grounded_str == "True"

            # ── Implementation 5: MORK encode-then-equal round-trip ──
            # Send both through to_sexpr → from_sexpr (which crosses the
            # __var_NAME byte boundary) and re-test with atom_equal. If this
            # diverges, the storage round-trip is destroying alpha-class info.
            a_rt = from_sexpr(to_sexpr(a))
            b_rt = from_sexpr(to_sexpr(b))
            r_roundtrip = atom_equal(a_rt, b_rt)

            # Headline: every implementation must match `should_be_equal`.
            # Today most will pass for the easy cases and fail for the
            # cross-encoding case. The branch's job is to surface which.
            @test r_atom      == should_be_equal
            @test r_rename    == should_be_equal
            @test r_legacy    == should_be_equal
            @test r_grounded  == should_be_equal
            @test r_roundtrip == should_be_equal

            # Sanity invariant: all five MUST agree internally, regardless of
            # whether the expected answer is true or false. This is the part
            # that's most likely to fail today.
            agreed = all(==(r_atom), (r_rename, r_legacy, r_grounded, r_roundtrip))
            @test agreed
            if !agreed
                println("  DISAGREEMENT for $label:")
                println("    atom_equal       = $r_atom")
                println("    alpha_rename ==  = $r_rename")
                println("    _alpha_eq legacy = $r_legacy")
                println("    =alpha grounded  = $r_grounded")
                println("    MORK round-trip  = $r_roundtrip")
            end
        end
    end
end
