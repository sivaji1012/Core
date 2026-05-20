"""
Eval — MeTTa interpreter for Core.

Evaluates MeTTa expressions against a CoreSpace using:
  1. GROUNDED_REGISTRY — direct Julia function dispatch
  2. Rule lookup — (= head body) rewriting
  3. MORK exec atoms — space_metta_calculus! for MM2 expressions
  4. Special forms — match, let, if, collapse, superpose
"""

# Global default space (lazily initialised)
const _DEFAULT_SPACE = Ref{CoreSpace}()
function default_space() :: CoreSpace
    isassigned(_DEFAULT_SPACE) || (_DEFAULT_SPACE[] = new_core_space())
    _DEFAULT_SPACE[]
end

"""
    eval_metta(expr, space=default_space()) → Any

Evaluate a MeTTa expression (Julia value) against a CoreSpace.
Returns the reduced result or the expression itself if no rule fires.
"""
function eval_metta(expr::Any, space::CoreSpace = default_space()) :: Any
    # Variable — return as-is (bindings handled by caller)
    expr isa Symbol && startswith(string(expr), "\$") && return expr

    # Grounded literal (number, bool)
    (expr isa Number || expr isa Bool) && return expr

    # Symbol — check if it's a 0-arg rule head
    if expr isa Symbol
        rules = core_rules(space, expr)
        !isempty(rules) && return eval_metta(rules[1][2], space)
        return expr
    end

    # Non-expression — return as-is
    !(expr isa Vector) && return expr
    isempty(expr) && return expr

    head = expr[1]
    args = expr[2:end]

    # ── Special forms ─────────────────────────────────────────────────────────
    # Per MeTTa spec §Minimal MeTTa Instructions and cross-verified against
    # Mettatron eval/mod.rs, CeTTa grounded.c, hyperon-experimental interpreter.rs
    # PRIMUS_Core/interpreter/SpecialForms.jl (adopted + stripped of MeTTaTerm)

    head === :match       && return _eval_match(args, space)
    head === Symbol("match") && return _eval_match(args, space)
    head === :let         && return _eval_let(args, space)
    head === Symbol("let*") && return _eval_let_star(args, space)
    head === :if          && return _eval_if(args, space)
    head === :collapse    && return _eval_collapse(args, space)
    head === :superpose   && return _eval_superpose(args, space)
    head === :case        && return _eval_case(args, space)
    head === :switch      && return _eval_case(args, space)
    head === :chain       && return _eval_chain(args, space)
    head === :function    && return _eval_function(args, space)
    head === :return      && return _eval_return(args, space)
    head === :eval        && return _eval_eval(args, space)
    head === :evalc       && return _eval_eval(args, space)   # context ignored for now
    head === :unify       && return _eval_unify(args, space)
    head === :quote       && return _eval_quote(args)
    head === :unquote     && return _eval_unquote(args, space)
    head === :empty       && return nothing
    head === Symbol("noreduce-eq") && return _eval_noreduce_eq(args)  # no eval of args
    head === :noeval               && return isempty(args) ? nothing : args[1]  # return unevaluated
    head === :do          && return _eval_do(args, space)
    head === :begin       && return _eval_do(args, space)
    head === Symbol("import!")   && return _eval_import!(args, space)
    head === Symbol("bind!")     && return _eval_bind!(args, space)
    head === Symbol("add-atom")    && return _eval_add_atom(args, space)
    head === Symbol("remove-atom") && return _eval_remove_atom(args, space)
    head === Symbol("get-atoms")   && return core_atoms(space)
    head === Symbol("new-space")   && return new_core_space()
    # WILLIAM space-aware primitives (session 3c — Core wiring)
    head === Symbol("william-heavy-hitters") && return _eval_william_heavy_hitters(args, space)
    head === Symbol("william-threshold")     && return _eval_william_threshold(args, space)
    head === Symbol("get-type-space") && return _eval_get_type_space(args, space)
    head === Symbol("add-reduct")     && return _eval_add_reduct(args, space)
    head === Symbol("for-each-in-atom") && return _eval_for_each(args, space)

    # ── Grounded dispatch ─────────────────────────────────────────────────────
    if head isa Symbol && is_grounded(string(head))
        evaled_args = [eval_metta(a, space) for a in args]
        str_args = to_sexpr.(evaled_args)
        raw = try GROUNDED_REGISTRY[string(head)](str_args)
              catch e; @warn "grounded call failed" name=head exception=e; nothing; end
        raw === nothing && return expr
        return raw isa String ? from_sexpr(raw) :
               raw isa Vector{String} ? from_sexpr.(raw) : raw
    end

    # ── Rule rewriting ────────────────────────────────────────────────────────
    if head isa Symbol
        evaled_args = [eval_metta(a, space) for a in args]
        rules = core_rules(space, head)
        for (head_params, body) in rules
            bindings = _unify_args(head_params, evaled_args)
            bindings === nothing && continue
            result = eval_metta(_apply_bindings(body, bindings), space)
            return result
        end
        # No rule matched — return as reduced expression
        return vcat([head], evaled_args)
    end

    expr
end

"""
    run_metta(source::String, space=default_space()) → Vector{Any}

Parse and evaluate a MeTTa source string.
Lines starting with `!` are executed; others are added as atoms.
"""
function run_metta(source::String, space::CoreSpace = default_space()) :: Vector{Any}
    results = Any[]
    # Use the proper parser to handle multi-line expressions and comments
    exprs = try parse_metta(source) catch; Any[] end
    for expr in exprs
        if expr isa Vector && !isempty(expr) && expr[1] === :!
            # Execution directive — evaluate the inner expression
            push!(results, eval_metta(expr[2], space))
        else
            core_add!(space, expr)
        end
    end
    results
end

"""
    run_file(path, space=default_space()) → Vector{Any}

Load and evaluate a .metta file. Atoms are added to space; `!` forms are executed.
"""
function run_file(path::String, space::CoreSpace = default_space()) :: Vector{Any}
    isfile(path) || error("File not found: $path")
    run_metta(read(path, String), space)
end

# ── Special form implementations ──────────────────────────────────────────────

function _eval_match(args::Vector, space::CoreSpace)
    length(args) < 2 && return nothing
    sp_arg   = args[1]
    pattern  = args[2]
    template = length(args) >= 3 ? args[3] : pattern
    # Resolve space reference
    s = sp_arg === Symbol("&self") ? space : space
    candidates = core_match(s, pattern)
    results = Any[]
    for cand in candidates
        b = _unify(pattern, cand)
        b === nothing && continue
        push!(results, eval_metta(_apply_bindings(template, b), space))
    end
    isempty(results) ? [] : (length(results) == 1 ? results[1] : results)
end

function _eval_let(args::Vector, space::CoreSpace)
    length(args) < 3 && return nothing
    var  = args[1]
    val  = eval_metta(args[2], space)
    body = args[3]
    bindings = var isa Symbol && startswith(string(var), "\$") ?
               Dict{Symbol, Any}(Symbol(string(var)[2:end]) => val) :
               Dict{Symbol, Any}()
    eval_metta(_apply_bindings(body, bindings), space)
end

function _eval_if(args::Vector, space::CoreSpace)
    length(args) < 3 && return nothing
    cond = eval_metta(args[1], space)
    (cond === true || cond === :True || cond == "True") ?
        eval_metta(args[2], space) : eval_metta(args[3], space)
end

function _eval_collapse(args::Vector, space::CoreSpace)
    isempty(args) && return []
    result = eval_metta(args[1], space)
    result isa Vector ? result : [result]
end

function _eval_superpose(args::Vector, space::CoreSpace)
    isempty(args) && return nothing
    items = args[1] isa Vector ? args[1] : [args[1]]
    [eval_metta(item, space) for item in items]
end

function _eval_add_atom(args::Vector, space::CoreSpace)
    length(args) < 2 && return nothing
    core_add!(space, args[2])
    args[2]
end

function _eval_remove_atom(args::Vector, space::CoreSpace)
    length(args) < 2 && return nothing
    core_remove!(space, args[2])
    args[2]
end

# ── Unification helpers ───────────────────────────────────────────────────────

"""Unify two expressions, returning bindings Dict or nothing on failure."""
function _unify(pattern::Any, value::Any) :: Union{Dict{Symbol,Any}, Nothing}
    bindings = Dict{Symbol, Any}()
    _unify!(pattern, value, bindings) ? bindings : nothing
end

function _unify!(pat::Any, val::Any, b::Dict{Symbol,Any}) :: Bool
    # Handle both $x and __var_x forms for variables
    pat_str = pat isa Symbol ? string(pat) : ""
    is_var  = startswith(pat_str, "\$") || startswith(pat_str, "__var_")
    if pat isa Symbol && is_var
        vname = startswith(pat_str, "__var_") ?
                Symbol("\$" * pat_str[7:end]) :
                Symbol(pat_str[2:end])
            existing = get(b, vname, nothing)
        existing !== nothing && return existing == val
        b[vname] = val
        return true
    end
    pat == val && return true
    (pat isa Vector && val isa Vector) || return false
    length(pat) == length(val) || return false
    all(i -> _unify!(pat[i], val[i], b), eachindex(pat))
end

"""Unify a list of patterns against a list of values."""
function _unify_args(params::Vector, args::Vector) :: Union{Dict{Symbol,Any}, Nothing}
    length(params) == length(args) || return nothing
    _unify(params, args)
end

"""Apply variable bindings to an expression."""
function _apply_bindings(expr::Any, b::Dict{Symbol,Any}) :: Any
    isempty(b) && return expr
    if expr isa Symbol
        s = string(expr)
        if startswith(s, "\$")
            return get(b, Symbol(s[2:end]), expr)
        elseif startswith(s, "__var_")
            return get(b, Symbol("\$" * s[7:end]), expr)
        end
    end
    expr isa Vector && return Any[_apply_bindings(e, b) for e in expr]
    expr
end

# ── Missing special form implementations ─────────────────────────────────────

function _eval_let_star(args::Vector, space::CoreSpace)
    # (let* (($v1 e1) ($v2 e2) ...) body)
    length(args) < 2 && return nothing
    bindings_list = args[1]
    body = args[2]
    b = Dict{Symbol,Any}()
    pairs = bindings_list isa Vector ? bindings_list : [bindings_list]
    for pair in pairs
        pair isa Vector && length(pair) >= 2 || continue
        var  = pair[1]
        val  = eval_metta(_apply_bindings(pair[2], b), space)
        vname = _var_name(var)
        vname !== nothing && (b[vname] = val)
    end
    eval_metta(_apply_bindings(body, b), space)
end

function _eval_case(args::Vector, space::CoreSpace)
    # (case val ((pat result) ...))
    length(args) < 2 && return nothing
    val   = eval_metta(args[1], space)
    pairs = args[2] isa Vector ? args[2] : args[2:end]
    for pair in pairs
        pair isa Vector && length(pair) >= 2 || continue
        pat    = pair[1]
        result = pair[2]
        b = _unify(pat, val)
        b === nothing && continue
        return eval_metta(_apply_bindings(result, b), space)
    end
    nothing
end

function _eval_chain(args::Vector, space::CoreSpace)
    # (chain atom $var template) — per MeTTa spec §Minimal MeTTa Instructions
    # Evaluate atom, bind result to $var, then evaluate template with binding.
    length(args) < 3 && return nothing
    evaled   = eval_metta(args[1], space)
    var      = args[2]
    template = args[3]
    vname = _var_name(var)
    if vname !== nothing
        eval_metta(_apply_bindings(template, Dict{Symbol,Any}(vname => evaled)), space)
    else
        eval_metta(template, space)
    end
end

# Sentinel type for function/return control flow
struct _ReturnValue
    val :: Any
end

function _eval_function(args::Vector, space::CoreSpace)
    # (function body) — evaluate body; if result is (return val), unwrap val
    isempty(args) && return nothing
    result = eval_metta(args[1], space)
    result isa _ReturnValue && return result.val
    # If it's a list starting with :return, unwrap
    if result isa Vector && !isempty(result) && result[1] === :return
        return length(result) >= 2 ? result[2] : nothing
    end
    result
end

function _eval_return(args::Vector, space::CoreSpace)
    # (return val) — wraps value for function to unwrap
    isempty(args) && return _ReturnValue(nothing)
    _ReturnValue(eval_metta(args[1], space))
end

function _eval_eval(args::Vector, space::CoreSpace)
    # (eval atom) — force one evaluation step
    isempty(args) && return nothing
    inner = eval_metta(args[1], space)
    eval_metta(inner, space)
end

function _eval_unify(args::Vector, space::CoreSpace)
    # (unify atom pattern then else) — 4-arg canonical form
    length(args) < 4 && return nothing
    a = eval_metta(args[1], space)
    b = eval_metta(args[2], space)
    bindings = _unify(a, b)
    if bindings !== nothing
        eval_metta(_apply_bindings(args[3], bindings), space)
    else
        eval_metta(args[4], space)
    end
end

function _eval_quote(args::Vector)
    # (quote atom) — return atom unevaluated
    isempty(args) ? nothing : args[1]
end

function _eval_unquote(args::Vector, space::CoreSpace)
    # (unquote (quote atom)) → evaluate the quoted atom
    isempty(args) && return nothing
    inner = args[1]
    if inner isa Vector && !isempty(inner) && inner[1] === :quote
        length(inner) >= 2 ? eval_metta(inner[2], space) : nothing
    else
        eval_metta(inner, space)
    end
end

function _eval_do(args::Vector, space::CoreSpace)
    # (do e1 e2 ... eN) / (begin ...) — evaluate all, return last
    isempty(args) && return nothing
    result = nothing
    for expr in args
        result = eval_metta(expr, space)
    end
    result
end

function _eval_import!(args::Vector, space::CoreSpace)
    # (import! &self "path/to/file.metta") — load file into space
    length(args) < 2 && return nothing
    path_arg = args[2]
    path = path_arg isa String ? path_arg : string(path_arg)
    isfile(path) || return [:Error, [:import!, path_arg], Symbol("FileNotFound")]
    run_file(path, space)
    path_arg
end

function _eval_get_type_space(args::Vector, space::CoreSpace)
    # (get-type-space &self atom) → lookup : atom Type in space
    length(args) < 2 && return Symbol("%Undefined%")
    atom = eval_metta(args[2], space)
    atom_s = to_sexpr(atom)
    # Search for (: atom Type) in space
    matches = core_match(space, [Symbol(":"), atom, Symbol("\$t")])
    isempty(matches) ? Symbol("%Undefined%") :
        (matches[1] isa Vector && length(matches[1]) >= 3 ? matches[1][3] : Symbol("%Undefined%"))
end

function _eval_add_reduct(args::Vector, space::CoreSpace)
    # (add-reduct &self expr) — evaluate expr, add result as atom
    length(args) < 2 && return nothing
    val = eval_metta(args[2], space)
    core_add!(space, val)
    val
end

function _eval_for_each(args::Vector, space::CoreSpace)
    # (for-each-in-atom list fn) — apply fn to each element
    length(args) < 2 && return nothing
    lst  = eval_metta(args[1], space)
    fn   = args[2]
    items = lst isa Vector ? lst : [lst]
    for item in items
        eval_metta([fn, item], space)
    end
    nothing
end

function _eval_noreduce_eq(args::Vector)
    # Compare atoms structurally WITHOUT evaluating — args arrive unevaluated
    length(args) < 2 && return false
    to_sexpr(args[1]) == to_sexpr(args[2]) ? :True : :False
end

function _eval_bind!(args::Vector, space::CoreSpace)
    # (bind! name expr) — add (= name result) to space
    length(args) < 2 && return nothing
    name = args[1]
    val  = eval_metta(args[2], space)
    core_add!(space, [:(=), name, val])
    val
end

# ── Variable name extraction ──────────────────────────────────────────────────

function _var_name(var::Any) :: Union{Symbol, Nothing}
    var isa Symbol || return nothing
    s = string(var)
    startswith(s, "\$")      && return Symbol(s[2:end])
    startswith(s, "__var_")  && return Symbol("\$" * s[7:end])
    nothing
end

# ── WILLIAM space-aware special forms ────────────────────────────────────────

function _eval_william_heavy_hitters(args::Vector, space::CoreSpace)
    # Resolve first arg: &self or explicit space → use current space
    s = length(args) >= 1 && eval_metta(args[1], space) === Symbol("&self") ? space :
        length(args) >= 1 && eval_metta(args[1], space) isa CoreSpace ?
            eval_metta(args[1], space) : space
    min_gain = length(args) >= 2 ?
        Float64(something(tryparse(Float64, string(eval_metta(args[2], space))), 0.7)) : 0.7
    k = length(args) >= 3 ?
        Int(round(Float64(something(tryparse(Float64, string(eval_metta(args[3], space))), 20.0)))) : 20
    _william_heavy_hitters(s, min_gain, k)
end

function _eval_william_threshold(args::Vector, space::CoreSpace)
    s = length(args) >= 1 && eval_metta(args[1], space) === Symbol("&self") ? space :
        length(args) >= 1 && eval_metta(args[1], space) isa CoreSpace ?
            eval_metta(args[1], space) : space
    _william_threshold(s)
end

export eval_metta, run_metta, run_file, default_space
export register_core_primitives!
