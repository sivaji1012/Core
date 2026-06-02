# ECAN regression suite — executes the examples/ecan/*.metta acceptance files
# under Test, so the attention-economy substrate (AV, funds, wages, two-tier rent,
# AF membership, spreading + Hebbian learning, decay/normalization, governance,
# fluid dynamics, self-evolving adaptation) is guarded in CI.
#
# Each example file is a self-contained MeTTa program of `!(assertEqual …)`
# directives; per the MeTTa spec assertEqual returns () on success and an
# (Error … AssertionFailed) expression on mismatch. We run each file in a FRESH
# space (the files seed conflicting global state — funds, AF, tick) and fail the
# testset if any directive returns an Error expression.

using MeTTaCore, Test

const ECAN_DIR = joinpath(@__DIR__, "..", "examples", "ecan")

# Fast acceptance files — full mechanism coverage, always run.
const ECAN_FILES = [
    "CoreAV", "Funds", "Wages", "Rent", "Stimulate", "AFState",
    "BulkOps", "Spreading", "Governance", "Fluid", "Adaptive",
]

# Stability runs heartbeat!×100 (two 50-tick convergence runs) through the
# tree-walking interpreter — minutes per run. It's a long-running convergence
# probe, not a unit acceptance test, so it's opt-in: ECAN_SLOW_TESTS=1.
const ECAN_SLOW_FILES = ["Stability"]

# Run one example file in a fresh space; return the list of Error expressions
# (assertion failures + any runtime errors like BadArgType). Empty ⇒ all passed.
function run_ecan_example(fname)
    S = new_core_space()
    register_core_primitives!()
    _register_atom_ops!(e -> to_sexpr(eval_metta(from_sexpr(e), S)))
    load_stdlib!(S)
    results = run_file(joinpath(ECAN_DIR, fname * ".metta"), S)
    filter(results) do r
        s = strip(to_sexpr(r))
        occursin("AssertionFailed", s) || startswith(s, "(Error")
    end
end

println("ECAN: running examples/ecan acceptance suite...")
@testset "ECAN acceptance suite (examples/ecan/*.metta)" begin
    for f in ECAN_FILES
        @testset "$f" begin
            fails = run_ecan_example(f)
            for x in fails
                @info "ECAN $f assertion/runtime error" expr = to_sexpr(x)
            end
            @test isempty(fails)
        end
    end

    if get(ENV, "ECAN_SLOW_TESTS", "") == "1"
        for f in ECAN_SLOW_FILES
            @testset "$f (slow)" begin
                fails = run_ecan_example(f)
                for x in fails
                    @info "ECAN $f assertion/runtime error" expr = to_sexpr(x)
                end
                @test isempty(fails)
            end
        end
    else
        @info "ECAN slow tests skipped (set ECAN_SLOW_TESTS=1 to run Stability)"
    end
end

println("\n✓ ECAN acceptance suite complete")
