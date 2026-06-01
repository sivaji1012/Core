# MetaMo on Core — adopted from the icoglabs MetaMo MeTTa reference, dialect-
# adapted into lib/metamo/ (PLN-style multi-file library). One shared space.
#
# Build status (incremental adoption — see lib/metamo/metamo.metta):
#   M1 ✅ foundation (config/state/accessors/helpers) + OpenPsi appraisal Ψ (eq #4)
#   M2/M3/M4 ⏳ decision 𝔻 → pseudo-bimonad F=𝔻∘Ψ → dynamics (eqs #5–#11)
# Tests below are extended as each layer lands.

using MeTTaCore, Test

println("MetaMo: initialising space...")
MS = new_core_space()
ef_mm = e -> to_sexpr(eval_metta(from_sexpr(e), MS))
register_core_primitives!()
_register_atom_ops!(ef_mm)
load_stdlib!(MS)
run_metta("!(import! &self (library metamo))", MS)
qmm(e) = run_metta(e, MS)

const _ST = "(motivation (0.25 0.75 0.5 0.5 0.5 0.5 0.5 0.5) (0.125 0.25 0.375 0.5 0.625 0.75))"
_q(e) = qmm(replace(e, "\$st" => _ST))

@testset "MetaMo on Core" begin
    @testset "M1 — scalar helpers (pure MeTTa, replacing upstream py-call)" begin
        @test qmm("!(expNum 0.0)") == [1.0]
        @test qmm("!(sigmoidNum 0.0)") == [0.5]
    end

    @testset "M1 — named accessors (getGoal/getModulator/getStimulus)" begin
        @test _q("!(getGoal \$st gInd)") == [0.25]
        @test _q("!(getGoal \$st gTrans)") == [0.75]
        @test _q("!(getModulator \$st valence)") == [0.125]
        @test _q("!(getModulator \$st threshold)") == [0.625]
        @test qmm("!(getStimulus (stimulus (0.2 0.8 0.1 0.2)) risk)") == [0.1]
    end

    @testset "M1 — OpenPsi appraisal Ψ (eq #4): G unchanged, M' blended in [0,1]" begin
        r = _q("!(openPsiAppraise \$st (stimulus (0.2 0.8 0.1 0.2)))")
        @test length(r) == 1
        appraised = r[1]                       # (motivation (G...) (M'...))
        @test appraised[1] == :motivation
        goals = appraised[2]
        mods = appraised[3]
        @test goals == Any[0.25, 0.75, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]   # G unchanged
        @test length(mods) == 6
        @test all(m -> m isa Number && 0.0 <= m <= 1.0, mods)          # bounded
        # Deterministic regression values (verified against the upstream math).
        @test isapprox(mods[1], 0.6769958; atol = 1e-5)   # valence
        @test isapprox(mods[4], 0.8928319; atol = 1e-5)   # resolution
        @test isapprox(mods[6], 0.7223979; atol = 1e-5)   # securing
    end
end

println("\n✓ MetaMo Core tests complete")
