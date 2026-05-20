"""
MeTTaCore — Standalone MeTTa substrate built directly on MORK.

Zero dependency on PRIMUS_Core or PRIMUS_Metagraph.
Redesigned pure-Julia MeTTa engine using MORK.Space as atom store.

Architecture:
  MORK.Space  (byte-trie, PathMap substrate)
      ↓
  CoreSpace   (AbstractAtomSpace wrapper — match, add, remove, rules)
      ↓
  Parser      (S-expression parser: string → Julia values)
      ↓
  Primitives  (grounded Julia functions: arithmetic, math, I/O)
  AtomOps     (grounded atom/list ops: cons/car/cdr/foldl/map/filter)
      ↓
  Eval        (MeTTa interpreter: rule rewriting + special forms)
      ↓
  stdlib/     (pure .metta files: if, let, list ops, types — hot-reloadable)

Design principles (per MeTTa spec + CeTTa/Mettatron/hyperon cross-check):
  - Only operations that MUST control evaluation order are grounded in Julia
  - Everything expressible as (= pattern body) lives in stdlib/*.metta
  - MeTTa atoms are S-expression strings ↔ MORK byte-paths (no UUID atoms)
  - stdlib files are loaded at init — no recompile needed to change them
"""
module MeTTaCore

using MORK
using MORK: Space, new_space,
            space_add_all_sexpr!, space_dump_all_sexpr,
            space_val_count, space_metta_calculus!, space_metta_calculus_at!,
            sexpr_to_expr, expr_serialize, remove_val_at!, read_zipper,
            space_query_multi, ExecError,
            register_grounded!, is_grounded, GROUNDED_REGISTRY

include("space/CoreSpace.jl")
include("parser/Parser.jl")
include("primitives/Primitives.jl")
include("primitives/AtomOps.jl")
include("eval/Eval.jl")

# stdlib directory relative to this package root
const _STDLIB_DIR = joinpath(@__DIR__, "..", "stdlib")

"""
    load_stdlib!(space::CoreSpace)

Load all stdlib/*.metta files into the given space.
Pure MeTTa rules — hot-reloadable, introspectable, no recompile needed.
"""
function load_stdlib!(space::CoreSpace)
    # Load in dependency order: types first, then core (uses types), then list/math
    for fname in ["types.metta", "core.metta", "list.metta", "math.metta"]
        path = joinpath(_STDLIB_DIR, fname)
        isfile(path) || continue
        try
            src = read(path, String)
            # CRITICAL: use Core's parser (parse_metta + core_add!), NOT
            # MORK.space_add_all_sexpr!. MORK's parser encodes $x as anonymous
            # NewVar bytes (de Bruijn), losing variable names on serialisation.
            # Core's parser stores variables as __var_x (named ground symbols)
            # which survive the MORK byte-trie round-trip correctly.
            exprs = parse_metta(src)
            for expr in exprs
                # Skip execution directives (!) in stdlib files
                expr isa Vector && !isempty(expr) && expr[1] === :! && continue
                core_add!(space, expr)
            end
        catch e
            @warn "load_stdlib!: failed to load $fname" exception=e
        end
    end
    space
end

"""
    register_all_primitives!(eval_fn=nothing)

Register all grounded primitives into MORK.GROUNDED_REGISTRY.
Pass `eval_fn` (a String→String callback) to enable foldl/map/filter.
"""
function register_all_primitives!(eval_fn::Union{Function,Nothing} = nothing)
    register_core_primitives!()
    _register_atom_ops!(
        eval_fn !== nothing ? eval_fn :
            (s -> begin
                sp = default_space()
                r = eval_metta(from_sexpr(s), sp)
                to_sexpr(r)
            end)
    )
end

export CoreSpace, new_core_space
export core_add!, core_remove!, core_match, core_rules, core_atoms
export core_calculus!, core_calculus_at!
export to_sexpr, from_sexpr, to_sexpr_query, _tokenise
export parse_metta, parse_sexpr
export eval_metta, run_metta, run_file, default_space
export register_core_primitives!, register_all_primitives!, load_stdlib!
export register_grounded!, is_grounded, GROUNDED_REGISTRY

end # module MeTTaCore
