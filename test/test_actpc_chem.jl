# ActPC-Chem on Core — migrated from packages/PRIMUS_Core/lib/actpc/Chemistry.metta,
# dialect-adapted to Core's MeTTa. Spec: docs/specs/actpc_chem_spec.md (AC1–AC11).
# Test cases follow the spec's §12 suite (weight ±, selection, chaining, PLN).

using MeTTaCore, Test

register_core_primitives!()

# Fresh, isolated ActPC-Chem space (soup-mutating tests must not cross-pollute).
function fresh_actpc()
    s = new_core_space()
    ef = e -> to_sexpr(eval_metta(from_sexpr(e), s))
    _register_atom_ops!(ef)
    load_stdlib!(s)
    run_metta("!(import! &self (library ActPC-Chem))", s)
    return s
end
qa(s, e) = run_metta(e, s)

@testset "ActPC-Chem on Core" begin
    S = fresh_actpc()

    @testset "accessors (head destructuring)" begin
        @test qa(S, "!(get-weight (ChemRule a b 5.0))") == [5.0]
        @test qa(S, "!(get-pattern (ChemRule a b 5.0))") == [:a]
        @test qa(S, "!(get-rewrite (ChemRule a b 5.0))") == [:b]
    end

    @testset "AC1 — weight update w + η(−ε+ν), clamped" begin
        # gain = −0.3 + 0.8 = 0.5 ; 5.0 + 0.1·0.5 = 5.05
        @test qa(S, "!(get-weight (actpc-update (ChemRule a b 5.0) 0.3 0.8))")[1] ≈ 5.05
        # gain = −1.0 + 0.0 = −1.0 ; 5.0 + 0.1·(−1.0) = 4.9
        @test qa(S, "!(get-weight (actpc-update (ChemRule a b 5.0) 1.0 0.0))")[1] ≈ 4.9
        # clamp upper: huge positive gain saturates at w_max = 10.0
        @test qa(S, "!(get-weight (actpc-update (ChemRule a b 9.9) 0.0 100.0))")[1] ≈ 10.0
        # clamp lower: huge error floors at 0.0
        @test qa(S, "!(get-weight (actpc-update (ChemRule a b 0.1) 100.0 0.0))")[1] ≈ 0.0
    end

    @testset "rule application (match / miss)" begin
        @test qa(S, "!(is-reaction-successful (apply-rule (ChemRule a b 3.0) a))") == [Bool(true)] ||
              qa(S, "!(is-reaction-successful (apply-rule (ChemRule a b 3.0) a))") == [:True]
        @test qa(S, "!(is-reaction-successful (apply-rule (ChemRule a b 3.0) x))") == [Bool(false)] ||
              qa(S, "!(is-reaction-successful (apply-rule (ChemRule a b 3.0) x))") == [:False]
        @test qa(S, "!(reaction-output (apply-rule (ChemRule a b 3.0) a))") == [:b]
    end

    @testset "AC6 — PLN projection (Implication + lowercase stv)" begin
        r = qa(S, "!(chem-rule-to-pln (ChemRule a b 5.0))")[1]
        # (Sentence (Implication a b) (stv 0.5 0.9) (Stamp chem))
        @test r[1] == :Sentence
        @test r[2] == Any[:Implication, :a, :b]
        @test r[3] == Any[:stv, 0.5, 0.9]
    end

    @testset "AC4 — rule chaining a → b → c" begin
        s = fresh_actpc()
        qa(s, "!(add-atom &self (ChemRule a b 5.0))")
        qa(s, "!(add-atom &self (ChemRule b c 3.0))")
        @test qa(s, "!(chem-chain a)") == [:c]
    end

    @testset "AC2 — selection picks the highest-weight rule" begin
        s = fresh_actpc()
        qa(s, "!(add-atom &self (ChemRule p1 q1 5.0))")
        qa(s, "!(add-atom &self (ChemRule p2 q2 2.0))")
        qa(s, "!(add-atom &self (ChemRule p3 q3 0.1))")
        @test qa(s, "!(get-weight (best-rule))") == [5.0]
    end

    @testset "soup-rule-count" begin
        s = fresh_actpc()
        qa(s, "!(add-atom &self (ChemRule a b 5.0))")
        qa(s, "!(add-atom &self (ChemRule b c 3.0))")
        @test qa(s, "!(soup-rule-count)") == [2]
    end
end
