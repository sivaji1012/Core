using Test
using MeTTaCore

# Boot: register all primitives and load stdlib once for all tests
register_all_primitives!()
const TEST_SPACE = new_core_space()
load_stdlib!(TEST_SPACE)

# Helper: fresh space with stdlib loaded (for isolated tests)
fresh() = load_stdlib!(new_core_space())

# Helper: eval in shared space
em(expr) = eval_metta(expr, TEST_SPACE)

# Bool result helpers (MeTTa returns True/False as various forms)
is_true(r)  = r ∈ [true, "True", :True]
is_false(r) = r ∈ [false, "False", :False]
is_num(r, n) = r == n || r == string(n) || r == Float64(n) || r == string(Float64(n))

@testset "Core MeTTa Compatibility Suite" begin

# ─────────────────────────────────────────────────────────────────────────────
@testset "1. Atom construction and deconstruction" begin
    s = fresh()
    @test em([Symbol("cons-atom"), 0, [1,2,3]]) isa Vector || occursin("0", string(em([Symbol("cons-atom"), 0, [1,2,3]])))
    @test em([Symbol("car-atom"), [1,2,3]]) == 1
    @test occursin("2", string(em([Symbol("cdr-atom"), [1,2,3]])))
    @test em([Symbol("size-atom"), [:a,:b,:c]]) == 3 || em([Symbol("size-atom"), [:a,:b,:c]]) == "3"
    @test em([Symbol("index-atom"), [1,2,3], 1]) == 2 || em([Symbol("index-atom"), [1,2,3], 1]) == "2"
    @test em([Symbol("index-atom"), [1,2,3], 0]) == 1 || em([Symbol("index-atom"), [1,2,3], 0]) == "1"
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "2. Arithmetic" begin
    s = fresh()
    @test em([:+, 3, 4]) == 7
    @test em([:-, 10, 3]) == 7
    @test em([:*, 6, 7]) == 42
    @test em([:/, 10, 2]) == 5 || em([:/, 10, 2]) == 5.0
    @test em([:%, 10, 3]) == 1
    @test eval_metta([Symbol("pow-math"), 2, 3], s) |> r -> is_num(r, 8)
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "3. Comparison" begin
    s = fresh()
    @test is_true(em([Symbol("<"), 3, 5]))
    @test is_false(em([Symbol(">"), 3, 5]))
    @test is_true(em([Symbol(">="), 5, 5]))
    @test is_true(em([Symbol("<="), 3, 5]))
    @test is_true(em([Symbol("=="), 3, 3]))
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "4. Math (-math suffix)" begin
    s = fresh()
    @test eval_metta([Symbol("sqrt-math"), 9], s)   |> r -> is_num(r, 3)
    @test eval_metta([Symbol("abs-math"), -5], s)   |> r -> is_num(r, 5)
    @test eval_metta([Symbol("ceil-math"), 5.2], s) |> r -> is_num(r, 6)
    @test eval_metta([Symbol("floor-math"), 5.8], s)|> r -> is_num(r, 5)
    @test eval_metta([Symbol("round-math"), 5.4], s)|> r -> is_num(r, 5)
    @test eval_metta([Symbol("sin-math"), 0], s)    |> r -> is_num(r, 0)
    @test eval_metta([Symbol("cos-math"), 0], s)    |> r -> is_num(r, 1)
    @test is_false(eval_metta([Symbol("isnan-math"), 0.0], s))
    @test is_false(eval_metta([Symbol("isinf-math"), 0.0], s))
    @test eval_metta([Symbol("min-atom"), (2,6,7,4,9,3)], s) |> r -> is_num(r, 2)
    @test eval_metta([Symbol("max-atom"), (2,6,7,4,9,3)], s) |> r -> is_num(r, 9)
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "5. Set operations (-atom suffix)" begin
    s = fresh()
    @test begin r = eval_metta([Symbol("union-atom"), [:a,:b], [:c,:d]], s)
        occursin("a", string(r)) && occursin("c", string(r)) end
    @test begin r = eval_metta([Symbol("intersection-atom"), [1,2],[2,3]], s)
        occursin("2", string(r)) end
    @test begin r = eval_metta([Symbol("unique-atom"), [:a,:b,:c,:d,:d]], s)
        !occursin("d d", string(r)) end
    @test begin r = eval_metta([Symbol("subtraction-atom"), [:a,:b,:b,:c], [:b,:c]], s)
        occursin("a", string(r)) && !occursin("b", string(r)) end
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "6. Higher-order list ops" begin
    s = fresh()
    @test eval_metta([Symbol("foldl-atom"), [1,2,3,4], 0,
        Symbol("\$acc"), Symbol("\$x"), [:+, Symbol("\$acc"), Symbol("\$x")]], s) == 10
    @test occursin("2", string(eval_metta(
        [Symbol("map-atom"), [1,2,3], Symbol("\$x"), [:+, Symbol("\$x"), 1]], s)))
    @test begin r = eval_metta(
        [Symbol("filter-atom"), [1,2,3,4,5], Symbol("\$x"), [Symbol(">"), Symbol("\$x"), 3]], s)
        occursin("4", string(r)) && !occursin("3", string(r)) end
    @test begin r = eval_metta([Symbol("union-atom"), [:a,:b,:b,:c], [:b,:c,:c,:d]], s)
        occursin("a", string(r)) && occursin("d", string(r)) end
    @test begin r = eval_metta([Symbol("intersection-atom"), [:a,:b,:c], [:b,:c,:d]], s)
        occursin("b", string(r)) && !occursin("a", string(r)) end
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "7. Special forms — chain / function / return" begin
    s = fresh()
    @test eval_metta([:chain, [:+, 2, 3], Symbol("\$x"), [:*, Symbol("\$x"), 2]], s) == 10
    @test eval_metta([:function, [:return, 99]], s) == 99
    @test eval_metta([:eval, [:+, 2, 3]], s) == 5
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "8. Special forms — let / let* / case" begin
    s = fresh()
    @test eval_metta([:let, Symbol("\$x"), 5, [:+, Symbol("\$x"), 1]], s) == 6
    @test eval_metta([Symbol("let*"),
        [[Symbol("\$x"), 3], [Symbol("\$y"), [:+, Symbol("\$x"), 1]]],
        [:+, Symbol("\$x"), Symbol("\$y")]], s) == 7
    @test begin
        r = eval_metta([:case, :foo, Any[Any[:foo, :matched], Any[:bar, :other]]], s)
        r === :matched || r == "matched"
    end
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "9. Special forms — unify / match" begin
    s = fresh()
    @test eval_metta([:unify, :foo, :foo, :yes, :no], s) === :yes
    @test eval_metta([:unify, :foo, :bar, :yes, :no], s) === :no
    core_add!(s, [:isa, :dog, :animal])
    core_add!(s, [:isa, :cat, :animal])
    r = eval_metta([:match, Symbol("&self"), [:isa, Symbol("\$x"), :animal], Symbol("\$x")], s)
    @test r !== nothing
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "10. Quote / noreduce-eq" begin
    s = fresh()
    @test begin r = eval_metta([:quote, [:+, 1, 2]], s)
        r isa Vector && r[1] === :+ end
    @test eval_metta([:unquote, [:quote, [:+, 1, 2]]], s) == 3
    @test is_true(eval_metta([Symbol("noreduce-eq"), [:+,1,2], [:+,1,2]], s))
    @test is_false(eval_metta([Symbol("noreduce-eq"), [:+,1,2], 3], s))
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "11. Alpha-equivalence (=alpha)" begin
    s = fresh()
    @test is_true(eval_metta([Symbol("=alpha"),
        [:Father, Symbol("\$X")], [:Father, Symbol("\$Y")]], s))
    @test is_false(eval_metta([Symbol("=alpha"),
        [:Father, Symbol("\$X")], [:Son, Symbol("\$X")]], s))
    @test is_true(eval_metta([Symbol("=alpha"),
        [:f, Symbol("\$a"), Symbol("\$b")], [:f, Symbol("\$x"), Symbol("\$y")]], s))
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "12. Type system" begin
    s = fresh()
    @test occursin("Number", string(eval_metta([Symbol("get-type"), 1], s)))
    @test occursin("Symbol", string(eval_metta([Symbol("get-type"), :foo], s)))
    @test begin r = eval_metta([Symbol("match-types"), :Number, :Number, :yes, :no], s)
        r === :yes || r == "yes" end
    @test begin r = eval_metta([Symbol("match-types"), :Number, :Bool, :yes, :no], s)
        r === :no || r == "no" end
    @test begin r = eval_metta([Symbol("match-types"), Symbol("%Undefined%"), :Number, :yes, :no], s)
        r === :yes || r == "yes" end
    @test begin r = eval_metta([Symbol("get-metatype"), :True], s)
        string(r) ∈ ["Symbol", "Grounded"] end
    @test occursin("Expression", string(eval_metta([Symbol("get-metatype"), [:a,:b]], s)))
    @test begin r = eval_metta([Symbol("first-from-pair"), [:A, :B]], s)
        r === :A || r == "A" end
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "13. if / if-equal from stdlib" begin
    s = fresh()
    @test eval_metta([:if, :True, :yes, :no], s)  === :yes
    @test eval_metta([:if, :False, :yes, :no], s) === :no
    @test begin r = eval_metta([Symbol("if-equal"), 1, 1, :Equal, :NotEqual], s)
        r === :Equal || r == "Equal" end
    @test begin r = eval_metta([Symbol("if-equal"), :a, :b, :Equal, :NotEqual], s)
        r === :NotEqual || r == "NotEqual" end
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "14. is-function from stdlib" begin
    s = fresh()
    @test is_true(eval_metta([Symbol("is-function"), [Symbol("->"), :Atom, :Atom]], s))
    @test is_false(eval_metta([Symbol("is-function"), :Atom], s))
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "15. State atoms (new-state / get-state)" begin
    s = fresh()
    st = eval_metta([Symbol("new-state"), :idle], s)
    @test occursin("State", string(st))
    val = eval_metta([Symbol("get-state"), st], s)
    @test val === :idle || val == "idle"
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "16. bind! and custom rules" begin
    s = fresh()
    eval_metta([Symbol("bind!"), :myconst, 42], s)
    core_add!(s, [:(=), [:double, Symbol("\$x")], [:*, Symbol("\$x"), 2]])
    @test eval_metta([:double, 5], s) == 10
    core_add!(s, [:(=), [:factorial, 0], 1])
    core_add!(s, [:(=), [:factorial, Symbol("\$n")],
                   [:*, Symbol("\$n"), [:factorial, [:-, Symbol("\$n"), 1]]]])
    @test eval_metta([:factorial, 5], s) == 120
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "17. Parser (parse_metta)" begin
    exprs = parse_metta("(fact a)\n(fact b)\n!(+ 2 3)")
    @test length(exprs) == 3
    @test exprs[3] isa Vector && exprs[3][1] === :!
    @test exprs[1] == [:fact, :a]
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "18. run_metta / run_file" begin
    s = fresh()
    results = run_metta("(= (sq \$x) (* \$x \$x))\n!(sq 7)", s)
    @test any(r -> r == 49 || r == "49", results)
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "19. Superpose / collapse" begin
    s = fresh()
    r = eval_metta([:superpose, [:a, :b, :c]], s)
    @test r !== nothing
    r2 = eval_metta([:collapse, [:superpose, [:A, :B, :C]]], s)
    @test occursin("A", string(r2))
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "20. CoreSpace — space operations" begin
    s = fresh()
    core_add!(s, [:fact, :x])
    @test !isempty(core_match(s, [:fact, Symbol("\$v")]))
    core_remove!(s, [:fact, :x])
    @test isempty(core_match(s, [:fact, :x]))
    @test !isempty(core_atoms(s))
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "21. MORK exec-atom calculus" begin
    s = new_core_space()
    core_add!(s, [:fact, :a])
    core_add!(s, [:fact, :b])
    core_add!(s, "(exec (t 0) (, (fact \$x)) (, (derived \$x)))")
    n = core_calculus!(s, 100)
    @test n >= 1
    @test any(a -> a isa Vector && length(a) >= 2 && a[1] === :derived, core_atoms(s))
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "22. Custom grounded functions" begin
    register_grounded!("triple", args -> string(parse(Int, args[1]) * 3))
    s = fresh()
    @test eval_metta([Symbol("triple"), 7], s) ∈ [21, "21"]
    delete!(GROUNDED_REGISTRY, "triple")
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "23. format-args" begin
    s = fresh()
    r = eval_metta([Symbol("format-args"), "(Hello {}!)", [:World]], s)
    @test occursin("World", string(r))
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "24. do / begin sequencing" begin
    s = fresh()
    r = eval_metta([:do, [:+,1,1], [:+,2,2], [:+,3,3]], s)
    @test r == 6 || r == "6"
end

# ─────────────────────────────────────────────────────────────────────────────
@testset "25. stdlib list functions" begin
    s = fresh()
    # id from stdlib
    @test eval_metta([:id, :hello], s) === :hello
    # noeval
    @test eval_metta([Symbol("noeval"), [:+, 1, 2]], s) == [:+, 1, 2]
end

end # testset "Core MeTTa Compatibility Suite"

println("\n✓ Core package tests passed.")
