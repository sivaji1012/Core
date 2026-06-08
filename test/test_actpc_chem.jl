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

    @testset "AC2 — softmax(τ) selection ∝ exp(w/τ)" begin
        s = fresh_actpc()
        qa(s, "!(add-atom &self (ChemRule p1 q1 5.0))")
        qa(s, "!(add-atom &self (ChemRule p2 q2 2.0))")
        # P(rule1) = exp(5)/(exp(5)+exp(2)) ≈ 0.95257 ; P(rule2) ≈ 0.04743  (order-free)
        @test qa(s, "!(softmax-prob (ChemRule p1 q1 5.0) 1.0)")[1] ≈ 0.95257413 atol = 1e-4
        @test qa(s, "!(softmax-prob (ChemRule p2 q2 2.0) 1.0)")[1] ≈ 0.04742587 atol = 1e-4
        # low temperature → greedy: picks the max-weight rule for any u (order-free)
        @test qa(s, "!(get-weight (softmax-select 0.5 0.1))") == [5.0]
        @test qa(s, "!(get-weight (softmax-select 0.9 0.1))") == [5.0]
    end

    @testset "AC3/AC5 — soup converges: predictive rule rises, wrong rule decays" begin
        s = fresh_actpc()
        qa(s, "!(add-atom &self (ChemRule a b 1.0))")   # good: a→b == actual b ⇒ ε=0
        qa(s, "!(add-atom &self (ChemRule a x 1.0))")   # bad:  a→x ≠ actual b   ⇒ ε=1
        for _ in 1:20
            qa(s, "!(chem-step! a b 0.5)")               # data=a, actual=b, value=0.5
        end
        good = qa(s, "!(match &self (ChemRule a b \$w) \$w)")[1]
        bad = qa(s, "!(match &self (ChemRule a x \$w) \$w)")[1]
        @test good ≈ 2.0 atol = 1e-6     # rose 1.0 → 2.0 (gain +0.05/step, 20 steps)
        @test bad ≈ 0.0 atol = 1e-6      # fell 1.0 → 0.0 (clamped at w_min)
        @test good > bad
        # replace-in-place: still exactly 2 rules (no duplicate accumulation)
        @test qa(s, "!(soup-rule-count)") == [2]
    end

    @testset "bridges — ECAN coupling (load with ecan + ActPC-Chem)" begin
        s = new_core_space()
        ef = e -> to_sexpr(eval_metta(from_sexpr(e), s))
        _register_atom_ops!(ef)
        load_stdlib!(s)
        run_metta("!(import! &self (library ecan))", s)
        run_metta("!(import! &self (library ActPC-Chem))", s)
        run_metta("!(import! &self (library ActPC-Chem bridges))", s)
        run_metta("!(add-atom &self (ChemRule a b 5.0))", s)
        # rule reactivity → ECAN attention: firing on `a` boosts the rule's STI from 0
        run_metta("!(boost-successful-rules! a)", s)
        @test run_metta("!(get-sti (ChemRule a b 5.0))", s)[1] > 0.0
        # the full neighbor-integrated tick runs end-to-end (chain→step→boost→decay)
        run_metta("!(add-atom &self (ChemRule b c 2.0))", s)
        r = run_metta("!(chem-cognitive-tick! a)", s)
        @test r !== nothing && !isempty(r)
    end
end
