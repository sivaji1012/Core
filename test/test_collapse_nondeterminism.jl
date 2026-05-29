# test/test_collapse_nondeterminism.jl
#
# Prototype branch test — EXPECTED to be GREEN.
#
# Thesis: `collapse (bin)` should return ALL results of `(bin)` when
# multiple `(= (bin) …)` rules are present, not just the first. Before
# this branch the rewriter returned on the first matching rule, so
# `_eval_collapse` silently lost cardinality — diagnosed by the other
# Claude as "the substrate had the cardinality, the API hid it."
#
# After threading stream-eval through the rewriter and simplifying
# `_eval_collapse` to a 3-line delegate, the cardinality flows through.
# Each assertion here is one way of asking the same question.

using Test
using MeTTaCore
using MeTTaCore: new_core_space, register_for_space!, load_stdlib!,
                 run_metta, core_add!, parse_sexpr, eval_metta_stream,
                 reset_multi_result_log!, multi_result_log

# Helper: build a fresh space with two `(bin)` rules.
function _fresh_bin_space()
    S = new_core_space()
    register_for_space!(S)
    load_stdlib!(S)
    core_add!(S, parse_sexpr("(= (bin) 0)"))
    core_add!(S, parse_sexpr("(= (bin) 1)"))
    S
end

@testset "collapse non-determinism (PROTOTYPE — expected green on branch)" begin

    @testset "stream returns both results" begin
        S = _fresh_bin_space()
        # eval_metta_stream is the canonical surface; it should see both
        # rules fire and return Vector{Any} of length 2.
        stream = eval_metta_stream(parse_sexpr("(bin)"), S)
        @test length(stream) == 2
        @test Set(stream) == Set([0, 1])
    end

    @testset "(collapse (bin)) returns both results" begin
        S = _fresh_bin_space()
        # `_eval_collapse` is now a 3-line delegate to `eval_metta_stream`.
        # The historical workaround for `(collapse (match ...))` /
        # `(collapse (superpose ...))` should NOT need to fire here —
        # `(bin)` is just a head-symbol with two rules.
        result = run_metta("!(collapse (bin))", S)
        @test length(result) == 1                  # one top-level expression evaluated
        inner = result[1]
        @test inner isa AbstractVector
        @test length(inner) == 2
        @test Set(inner) == Set([0, 1])
    end

    @testset "(superpose) still works after collapse simplification" begin
        S = new_core_space()
        register_for_space!(S)
        load_stdlib!(S)
        result = run_metta("!(superpose (1 2 3))", S)
        @test length(result) == 1
        @test result[1] isa AbstractVector
        @test Set(result[1]) == Set([1, 2, 3])
    end

    @testset "(collapse (match …)) still works after collapse simplification" begin
        S = new_core_space()
        register_for_space!(S)
        load_stdlib!(S)
        core_add!(S, parse_sexpr("(Parent Bob Ann)"))
        core_add!(S, parse_sexpr("(Parent Pam Ann)"))
        result = run_metta("!(collapse (match &self (Parent \$x Ann) \$x))", S)
        @test length(result) == 1
        inner = result[1]
        @test inner isa AbstractVector
        @test length(inner) == 2
        @test Set(inner) == Set([:Bob, :Pam])
    end

    @testset "multi-result log captures the cardinality discovery" begin
        # When the loud adapter `eval_metta` is called on `(bin)` (single-
        # result contract), it should LOG the unwrap to MULTI_RESULT_LOG.
        # That log is the real output of the prototype — it's the
        # inventory of callsites quietly assuming determinism.
        S = _fresh_bin_space()
        reset_multi_result_log!()
        _ = eval_metta(parse_sexpr("(bin)"), S)   # adapter, will see length=2
        log = multi_result_log()
        @test length(log) >= 1
        if !isempty(log)
            entry = log[1]
            @test entry.count == 2
            @test Set(entry.results) == Set([0, 1])
        end
    end
end
