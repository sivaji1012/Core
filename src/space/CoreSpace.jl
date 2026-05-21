"""
CoreSpace — MORK.Space-backed atom space.

Every atom is stored as a byte-path in a MORK PathMap trie.
S-expression strings are the interchange format between Julia and MORK.
"""

# ── Atom ↔ S-expression conversion ───────────────────────────────────────────

"""
Convert any Julia value to a MORK-compatible S-expression string.

Variables (Symbol starting with '\$') are encoded as ground symbols `__var_NAME`
so they survive the MORK byte-trie round-trip. MORK's native \$x syntax
anonymises variable names (de Bruijn); __var_x preserves them.

For query patterns, call `to_sexpr_query` which uses \$x directly.
"""
function to_sexpr(x::Any) :: String
    if x isa Symbol
        s = string(x)
        startswith(s, "\$") && return "__var_" * s[2:end]
        return s
    end
    x isa String  && return x
    x isa Bool    && return x ? "True" : "False"   # must precede Number (Bool <: Integer)
    x isa Number  && return string(x)
    x isa Tuple   && return "($(join(to_sexpr.(x), " ")))"   # Tuple same as Vector
    x isa Vector  && return "($(join(to_sexpr.(x), " ")))"
    string(x)
end

"""
Convert a pattern to S-expression, keeping \$x as MORK wildcards.
Use for `core_match` queries — do NOT use for storage (variable names lost).
"""
function to_sexpr_query(x::Any) :: String
    if x isa Symbol
        s = string(x)
        # __var_x is the storage form of $x — convert back so MORK treats it as wildcard
        startswith(s, "__var_") && return "\$" * s[7:end]
        return s   # $x stays as-is — MORK parses it as a wildcard variable
    end
    x isa String  && return x
    x isa Bool    && return x ? "True" : "False"   # must precede Number (Bool <: Integer)
    x isa Number  && return string(x)
    x isa Vector  && return "($(join(to_sexpr_query.(x), " ")))"
    string(x)
end

"""Parse a MORK S-expression string into a Julia value."""
from_sexpr(s::AbstractString) :: Any = from_sexpr(String(s))
function from_sexpr(s::String) :: Any
    s = strip(s)
    isempty(s) && return nothing
    s == "True"  && return true
    s == "False" && return false

    n = tryparse(Int, s);     n !== nothing && return n
    n = tryparse(Float64, s); n !== nothing && return n

    # MORK variable encoding: __var_NAME → Symbol("$NAME")
    startswith(s, "__var_") && return Symbol("\$" * s[7:end])
    # Legacy $x form (from MORK parser)
    startswith(s, "\$") && return Symbol(s)

    if startswith(s, "(") && endswith(s, ")")
        inner  = s[2:end-1]
        tokens = _tokenise(inner)
        isempty(tokens) && return []
        return Any[from_sexpr(t) for t in tokens]
    end

    Symbol(s)
end

export _tokenise
_tokenise(s::AbstractString) = _tokenise(String(s))
function _tokenise(s::String) :: Vector{String}
    tokens = String[]; depth = 0; start = 1; i = 1
    while i <= length(s)
        c = s[i]
        if     c == '(';       depth += 1
        elseif c == ')';       depth -= 1
               if depth == 0; push!(tokens, strip(s[start:i])); start = i + 1; end
        elseif isspace(c) && depth == 0
            tok = strip(s[start:i-1])
            !isempty(tok) && push!(tokens, tok)
            start = i + 1
        end
        i += 1
    end
    tok = strip(s[start:end])
    !isempty(tok) && push!(tokens, tok)
    tokens
end

# ── CoreSpace ─────────────────────────────────────────────────────────────────

"""
    CoreSpace

MeTTa atom space backed by a real MORK.Space byte trie.
Atoms are stored as S-expression byte-paths via space_add_all_sexpr!.
"""
mutable struct CoreSpace
    inner        :: Space
    rule_cache   :: Dict{Symbol, Vector{Tuple{Vector{Any}, Any}}}
    named_spaces :: Dict{Symbol, Any}   # bind! registry — scoped to this context
end

"""Create a new empty CoreSpace."""
new_core_space() = CoreSpace(new_space(),
    Dict{Symbol, Vector{Tuple{Vector{Any}, Any}}}(),
    Dict{Symbol, Any}())

# ── Atom operations ───────────────────────────────────────────────────────────

"""Add an atom to the space. Accepts any Julia value (converted to S-expr)."""
function core_add!(s::CoreSpace, atom::Any)
    sexpr = to_sexpr(atom)
    isempty(sexpr) && return nothing
    try space_add_all_sexpr!(s.inner, sexpr)
    catch e; @warn "core_add! failed" atom=sexpr exception=e; end
    # Per-head cache invalidation: adding (= (head args) body) can only affect
    # lookups for `head` — other heads' cached rules are unchanged.
    # Full flush (empty!) only when the affected head can't be identified.
    if atom isa Vector && length(atom) == 3 && atom[1] === Symbol("=")
        head_expr = atom[2]
        head_sym  = head_expr isa Vector && !isempty(head_expr) ? head_expr[1] :
                    head_expr isa Symbol ? head_expr : nothing
        head_sym isa Symbol ? delete!(s.rule_cache, head_sym) : empty!(s.rule_cache)
    end
    nothing
end

"""Remove an atom from the space by its S-expression form."""
function core_remove!(s::CoreSpace, atom::Any)
    sexpr = to_sexpr(atom)
    isempty(sexpr) && return nothing
    try
        e = sexpr_to_expr(sexpr)
        remove_val_at!(s.inner.btm, e.buf)
    catch e; @warn "core_remove! failed" atom=sexpr exception=e; end
    empty!(s.rule_cache)   # removing anything could affect rule lookups
    nothing
end

"""
    core_match(s, pattern) → Vector{Any}

Query the trie for atoms matching `pattern`. Variables (\$x) act as wildcards.
Returns a list of matching atoms as Julia values.
"""
function core_match(s::CoreSpace, pattern::Any) :: Vector{Any}
    sexpr = to_sexpr_query(pattern)   # keep $x as MORK wildcards
    isempty(sexpr) && return Any[]
    results = Any[]
    try
        comma_expr = sexpr_to_expr("(, $sexpr)")
        space_query_multi(s.inner.btm, comma_expr, (bindings, path) -> begin
            try
                buf  = path isa MORK.Expr ? path.buf : collect(UInt8, path)
                str  = expr_serialize(buf)
                push!(results, from_sexpr(str))
            catch; end
            true
        end)
    catch e; @warn "core_match failed" pattern=sexpr exception=e; end
    results
end

"""
    core_rules(s, head_sym) → Vector{Tuple{Vector{Any}, Any}}

Scan the trie for `(= (head_sym args...) body)` rule atoms.
Returns list of (head_args, body) tuples.
"""
function core_rules(s::CoreSpace, head_sym::Symbol) :: Vector{Tuple{Vector{Any}, Any}}
    # Fast path: return cached rules (invalidated by core_add!/core_remove!)
    cached = get(s.rule_cache, head_sym, nothing)
    cached !== nothing && return cached

    rules = Tuple{Vector{Any}, Any}[]
    pats = [
        "(= ($head_sym) \$body_)",
        "(= ($head_sym \$v0) \$body_)",
        "(= ($head_sym \$v0 \$v1) \$body_)",
        "(= ($head_sym \$v0 \$v1 \$v2) \$body_)",
        "(= ($head_sym \$v0 \$v1 \$v2 \$v3) \$body_)",
        "(= ($head_sym \$v0 \$v1 \$v2 \$v3 \$v4) \$body_)",
    ]
    seen = Set{String}()
    for pat in pats
        try
            comma_expr = sexpr_to_expr("(, $pat)")
            space_query_multi(s.inner.btm, comma_expr, (bindings, path) -> begin
                try
                    buf  = path isa MORK.Expr ? path.buf : collect(UInt8, path)
                    key  = bytes2hex(buf)
                    key in seen && return true
                    push!(seen, key)
                    atom = from_sexpr(expr_serialize(buf))
                    if atom isa Vector && length(atom) == 3 && atom[1] === :(=)
                        head_part = atom[2]
                        body      = atom[3]
                        if head_part isa Vector && !isempty(head_part) &&
                           head_part[1] === head_sym
                            push!(rules, (head_part[2:end], body))
                        end
                    end
                catch; end
                true
            end)
        catch; end
    end
    s.rule_cache[head_sym] = rules   # cache result
    rules
end

"""Return all atoms in the space as Julia values."""
function core_atoms(s::CoreSpace) :: Vector{Any}
    [from_sexpr(strip(line))
     for line in split(space_dump_all_sexpr(s.inner), '\n')
     if !isempty(strip(line))]
end

"""Forward MORK exec-atom calculus (runs MM2 exec atoms)."""
core_calculus!(s::CoreSpace, steps::Int = typemax(Int)) =
    space_metta_calculus!(s.inner, steps)

core_calculus_at!(s::CoreSpace, loc::AbstractString, steps::Int = typemax(Int)) =
    space_metta_calculus_at!(s.inner, loc, steps)
