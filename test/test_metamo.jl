# MetaMo on Core — adopted from the icoglabs MetaMo MeTTa reference, dialect-
# adapted into lib/metamo/ (PLN-style multi-file library). One shared space.
#
# Build status (incremental adoption — see lib/metamo/metamo.metta):
#   M1 ✅ foundation (config/state/accessors/helpers) + OpenPsi appraisal Ψ (eq #4)
#   M2 ✅ MAGUS decision 𝔻 (eq #5/#10/#11)   M3 ✅ pseudo-bimonad F=𝔻∘Ψ (eq #6)
#   M4 ✅ dynamics: safe region/contraction (eq #7/#8) + blend (eq #9) + drift
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

    @testset "M2 — vector helpers (pure MeTTa)" begin
        @test qmm("!(clipVector (0.2 1.5 -0.3 0.7) 0.0 1.0)") == [Any[0.2, 1.0, 0.0, 0.7]]
        @test qmm("!(scaleArray (0.5 1.0 2.0) 10.0)") == [Any[5.0, 10.0, 20.0]]
        @test qmm("!(positivePart -0.4)") == [0.0]
        @test qmm("!(meanAtIndices (0.2 0.4 0.6 0.8) (1 3))")[1] ≈ 0.6
    end

    @testset "M2 — MAGUS decision 𝔻 (eq #5/#10/#11)" begin
        # gEthic's relevant modulators = (threshold securing) = (0.625 0.75) → avg 0.6875
        @test _q("!(magusRelevantModulator \$st gEthic)")[1] ≈ 0.6875

        # Two candidates: 'good' (positive goal correlations, zero risk) should
        # outscore 'bad' (negative correlations, high risk).
        good = "(action good (0.0 0.0 1.0 1.0 1.0 1.0 1.0 1.0) 0.0 (0.0 0.0 0.05 0.05 0.05 0.05 0.05 0.05))"
        bad = "(action bad (0.0 0.0 -1.0 -1.0 -1.0 -1.0 -1.0 -1.0) 1.0 (0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0))"
        sgood = qmm(replace("!(magusScore \$st \$g)", "\$st" => _ST, "\$g" => good))[1]
        sbad = qmm(replace("!(magusScore \$st \$b)", "\$st" => _ST, "\$b" => bad))[1]
        @test sgood isa Number && sbad isa Number
        @test sgood > sbad
        # magusDecide picks 'good'; result is (decisionResult good ΔG_good)
        dec = qmm(replace("!(magusDecide \$st (\$g \$b))", "\$st" => _ST, "\$g" => good, "\$b" => bad))[1]
        @test dec[1] == :decisionResult
        # decisionAction returns the full chosen action; actionId extracts its id.
        @test qmm(replace("!(actionId (decisionAction (magusDecide \$st (\$g \$b))))", "\$st" => _ST, "\$g" => good, "\$b" => bad)) == [:good]
    end

    @testset "M3 — bimonad vector helpers (vectorAdd/listDifference/norm)" begin
        @test qmm("!(vectorAdd (1.0 2.0 3.0) (0.5 0.5 0.5))") == [Any[1.5, 2.5, 3.5]]
        @test qmm("!(listDifference (1.0 2.0) (0.25 0.5))") == [Any[0.75, 1.5]]
        @test qmm("!(norm (3.0 4.0))")[1] ≈ 5.0
    end

    @testset "M3 — pseudo-bimonad step F = 𝔻 ∘ Ψ (eq #6)" begin
        good = "(action good (0.0 0.0 1.0 1.0 1.0 1.0 1.0 1.0) 0.0 (0.0 0.0 0.05 0.05 0.05 0.05 0.05 0.05))"
        bad = "(action bad (0.0 0.0 -1.0 -1.0 -1.0 -1.0 -1.0 -1.0) 1.0 (0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0))"
        stim = "(stimulus (0.2 0.8 0.1 0.2))"
        sub(e) = replace(e, "\$st" => _ST, "\$g" => good, "\$b" => bad, "\$s" => stim)

        tr = qmm(sub("!(metamoStep \$st \$s (\$g \$b))"))[1]
        @test tr[1] == :transitionResult
        # chosen action = good (𝔻 picks it)
        @test qmm(sub("!(actionId (transitionAction (metamoStep \$st \$s (\$g \$b))))")) == [:good]
        # next state: motivation with 8 clipped goals + 6 appraised modulators
        nextst = qmm(sub("!(transitionState (metamoStep \$st \$s (\$g \$b)))"))[1]
        @test nextst[1] == :motivation
        @test length(nextst[2]) == 8 && all(g -> 0.0 <= g <= 1.0, nextst[2])
        @test length(nextst[3]) == 6 && all(m -> 0.0 <= m <= 1.0, nextst[3])

        # Principle 1 — lax-distributive-law check returns a Bool (Core yields
        # True/False as Julia true/false here).
        lax = qmm(sub("!(checkLaxDistributiveLaw \$st \$s (\$g \$b))"))
        @test length(lax) == 1 && lax[1] ∈ (true, false, :True, :False)
    end

    @testset "M4 — dynamics index-conditional helpers (pure MeTTa)" begin
        @test qmm("!(setAtIndex (1.0 2.0 3.0) 1 9.0)") == [Any[1.0, 9.0, 3.0]]
        # boost caution indices (4 5) by 0.25, capped at 1.0
        @test qmm("!(boostAtIndices (0.1 0.2 0.3 0.4 0.5 0.6) (4 5) 0.25 1.0)") ==
              [Any[0.1, 0.2, 0.3, 0.4, 0.75, 0.85]]
        @test qmm("!(blendArrays (0.0 0.0) (1.0 1.0) 0.25)") == [Any[0.25, 0.25]]
        # floor goals[0] at 0.3 (0.1 → 0.3); norm stays under G_MAX so no scale-down
        @test qmm("!(projectGoalsToSafe (0.1 0.5 0.5 0.5 0.5 0.5 0.5 0.5) 0 0.3 2.0)") ==
              [Any[0.3, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]]
    end

    @testset "M4 — safe region (eq #7) + boundary pressure (Principle 4)" begin
        # gInd 0.5 ≥ θ_safe 0.3 and ‖G‖ small → inside R.
        safe = "(motivation (0.5 0.75 0.2 0.2 0.2 0.2 0.2 0.2) (0.5 0.5 0.5 0.5 0.5 0.5))"
        # gInd 0.32 just 0.02 inside θ_safe → in the η=0.1 boundary band.
        near = "(motivation (0.32 0.0 0.0 0.0 0.0 0.0 0.0 0.0) (0.5 0.5 0.5 0.5 0.5 0.5))"
        # gInd 0.1 < θ_safe → outside R.
        unsafe = "(motivation (0.1 0.75 0.5 0.5 0.5 0.5 0.5 0.5) (0.5 0.5 0.5 0.5 0.5 0.5))"
        s(e, x) = qmm(replace(e, "\$x" => x))

        @test s("!(isInSafeRegion \$x)", safe)[1] ∈ (true, :True)
        @test s("!(isInSafeRegion \$x)", unsafe)[1] ∈ (false, :False)
        @test s("!(boundaryPressure \$x)", safe) == [0.0]
        @test s("!(boundaryPressure \$x)", near)[1] ≈ 0.8       # 1 - 0.02/0.1
        @test s("!(boundaryPressure \$x)", unsafe) == [1.0]
        @test s("!(isInBoundaryBand \$x)", near)[1] ∈ (true, :True)

        # Damping leaves ΔG untouched in the interior, shrinks it near the boundary.
        @test s("!(applyHomeostaticDamping \$x (0.1 0.1))", safe) == [Any[0.1, 0.1]]
        # pressure 1.0, gInd 0.1 → factor 0.9 → 0.1·0.9 = 0.09
        damped = s("!(applyHomeostaticDamping \$x (0.1 0.1))", unsafe)[1]
        @test all(d -> isapprox(d, 0.09; atol = 1e-9), damped)

        # Hard projection floors gInd at θ_safe and raises caution modulators.
        proj = s("!(projectToSafeRegion \$x)", unsafe)[1]
        @test proj[1] == :motivation
        @test proj[2][1] ≈ 0.3
        @test proj[3][5] ≈ 0.6 && proj[3][6] ≈ 0.6              # caution +0.1
    end

    @testset "M4 — incremental blend (eq #9) + self-model drift (Principle 5)" begin
        tgt = "(motivation (1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0) (1.0 1.0 1.0 1.0 1.0 1.0))"
        # α = ALPHA_0·(1−0.25) + BETA_0·0.75 = 0.075 + 0.1125 = 0.1875
        @test _q("!(calculateBlendFactor \$st)")[1] ≈ 0.1875
        # goals[0]' = (1−0.1875)·0.25 + 0.1875·1.0 = 0.390625
        blended = qmm(replace("!(metamoBlend \$st \$t)", "\$st" => _ST, "\$t" => tgt))[1]
        @test blended[1] == :motivation
        @test blended[2][1] ≈ 0.390625
        @test length(blended[2]) == 8 && length(blended[3]) == 6
        # No movement (state→state) → zero drift → within any positive bound.
        @test _q("!(checkSelfModelDrift \$st \$st 2.0 1.0)")[1] ∈ (true, :True)
    end

    @testset "M4 — fully-stabilized governance step (metamoGovern)" begin
        good = "(action good (0.0 0.0 1.0 1.0 1.0 1.0 1.0 1.0) 0.0 (0.0 0.0 0.05 0.05 0.05 0.05 0.05 0.05))"
        bad = "(action bad (0.0 0.0 -1.0 -1.0 -1.0 -1.0 -1.0 -1.0) 1.0 (0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0))"
        stim = "(stimulus (0.2 0.8 0.1 0.2))"
        sub(e) = replace(e, "\$st" => _ST, "\$g" => good, "\$b" => bad, "\$s" => stim)

        tr = qmm(sub("!(metamoGovern \$st \$s (\$g \$b))"))[1]
        @test tr[1] == :transitionResult
        @test qmm(sub("!(actionId (transitionAction (metamoGovern \$st \$s (\$g \$b))))")) == [:good]
        # Stabilized: the next state is guaranteed inside the safe region R.
        safe = qmm(sub("!(isInSafeRegion (transitionState (metamoGovern \$st \$s (\$g \$b))))"))
        @test safe[1] ∈ (true, :True)
    end
end

println("\n✓ MetaMo Core tests complete")
