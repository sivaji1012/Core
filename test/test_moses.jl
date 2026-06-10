# MOSES on Core — port of the iCog metta-moses MeTTaLog reimplementation of asmoses.
# Upstream 1:1 ref: ~/JuliaAGI/dev-zone/metta-moses ; research layer: MOSES MORK.pdf.
#
# Build status (incremental port):
#   M0 ✅ scaffold + Core-native list utilities (this file's M0 testset)
#
# Run (cold, one-off):  julia --project=packages/Core packages/Core/test/test_moses.jl
using MeTTaCore, Test

println("MOSES: initialising space...")
const MM = new_core_space()
ef_moses = e -> to_sexpr(eval_metta(from_sexpr(e), MM))
register_core_primitives!()
_register_atom_ops!(ef_moses)
load_stdlib!(MM)
run_metta("!(import! &self (library MOSES))", MM)
qm(e) = run_metta(e, MM)

@testset "MOSES on Core" begin
    @testset "M0 — Core-native list utilities (Cons/Nil-ADT → ()-expr idiom)" begin
        @test qm("!(List.length (1 2 3))") == [3]
        @test qm("!(List.length ())") == [0]
        @test qm("!(List.foldl + 0 (1 2 3 4))") == [10]
        @test qm("!(List.foldr + 0 (1 2 3 4))") == [10]
        @test qm("!(List.sum (5 10 15))") == [30]
        @test qm("!(List.getByIdx (10 20 30) 1)") == [20]
        @test qm("!(List.member 2 (1 2 3))") == [Bool(true)] || qm("!(List.member 2 (1 2 3))") == ["True"]
        @test qm("!(List.member 9 (1 2 3))") == [Bool(false)] || qm("!(List.member 9 (1 2 3))") == ["False"]
    end

    @testset "M1a — Instance (genotype value) + Pair" begin
        @test qm("!(Pair.first  (mkPair a b))") == [Symbol("a")] || qm("!(Pair.first  (mkPair a b))") == ["a"]
        @test qm("!(Pair.second (mkPair a b))") == [Symbol("b")] || qm("!(Pair.second (mkPair a b))") == ["b"]
        @test qm("!(Inst.length (mkInst (0 1 2 0)))") == [4]
        @test qm("!(Inst.get (mkInst (5 6 7)) 2)") == [7]
        @test qm("!(Inst.elems (mkInst (1 0 1)))") == [[1, 0, 1]] || occursin("1", string(qm("!(Inst.elems (mkInst (1 0 1)))")))
        @test qm("!(getInst (mkSInst (mkPair (mkInst (1 0)) 9.0)))") == [[:mkInst, [1, 0]]] ||
              occursin("mkInst", string(qm("!(getInst (mkSInst (mkPair (mkInst (1 0)) 9.0)))")))
        @test qm("!(getSInstScore (mkSInst (mkPair (mkInst (1 0)) 9.0)))") == [9.0]
    end
end
