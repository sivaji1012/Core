"""
WilliamPrimitives — WILLIAM pattern mining primitives for MeTTaCore.

Wires the three grounded operations needed by the ambient cognitive loop:

  compression-score      — structural complexity heuristic ∈ [0,1] (GROUNDED_REGISTRY)
  william-threshold      — adaptive gain threshold by space load (special form)
  william-heavy-hitters  — top-k atoms by compression gain (special form)

`compression-score` has no space dependency → registered via MORK.GROUNDED_REGISTRY.
`william-threshold` and `william-heavy-hitters` receive the space from the eval
context via special-form dispatch in Eval.jl (same pattern as `get-atoms`).

Pure MeTTa rules (MDL gain, LGG via AUSink, NCD, pattern counting via
CountSink/HeadSink) live in stdlib/william.metta.
"""

# ── Structural complexity ─────────────────────────────────────────────────────

"""
    _william_structural_complexity(x) → Int

Recursive structural complexity of a MeTTa atom: 1 for scalars,
1 + sum(children) for compound expressions.
Mirrors the heuristic in PRIMUS_Core's WilliamAdapter.
"""
function _william_structural_complexity(x)
    if x isa Vector
        return 1 + sum(_william_structural_complexity(c) for c in x; init=0)
    elseif x isa Tuple
        return 1 + sum(_william_structural_complexity(c) for c in x; init=0)
    elseif x isa AbstractString
        # parse back to check arity
        parsed = try from_sexpr(x) catch; x end
        parsed === x && return 1
        return _william_structural_complexity(parsed)
    else
        return 1
    end
end

# ── compression-score (GROUNDED_REGISTRY — no space needed) ──────────────────

"""Register `compression-score` into MORK.GROUNDED_REGISTRY."""
function _register_william_primitives!()
    MORK.register_grounded!("compression-score", args -> begin
        isempty(args) && return 0.0
        c = _william_structural_complexity(args[1])
        # Sigmoid-like: complexity > 5 starts yielding high gain.
        Float64(1.0 - 1.0 / (1.0 + c / 5.0))
    end)
end

# ── william-threshold (needs space — called as special form) ─────────────────

"""
    _william_threshold(space) → Float64

Adaptive gain threshold ∈ [0.5, 0.9] that rises logarithmically with
the number of atoms in `space`.  Scales from 0.5 (empty space) to 0.9
(100k+ atoms), ensuring only high-gain patterns are flagged in large spaces.
"""
function _william_threshold(space::CoreSpace) :: Float64
    n = length(core_atoms(space))
    clamp(0.5 + 0.1 * log10(max(1, n)), 0.5, 0.9)
end

# ── william-heavy-hitters (needs space — called as special form) ─────────────

"""
    _william_heavy_hitters(space, min_gain, k) → Vector{Any}

O(N) scan of atoms in `space`; scores each by structural complexity gain;
returns the top-`k` above `min_gain` threshold, sorted descending.

Cap: scans at most 1000 atoms (shuffle-sampled when space is larger) to
keep ambient-tick latency bounded.
"""
function _william_heavy_hitters(space::CoreSpace,
                                 min_gain::Float64 = 0.7,
                                 k::Int = 20) :: Vector{Any}
    all_atoms = core_atoms(space)
    atoms = length(all_atoms) > 1000 ?
        all_atoms[rand(1:length(all_atoms), 1000)] : all_atoms

    candidates = Tuple{Float64, Any}[]
    for atom in atoms
        c = _william_structural_complexity(atom)
        gain = 1.0 - 1.0 / (1.0 + c / 5.0)
        if gain >= min_gain
            push!(candidates, (gain, atom))
        end
    end

    sort!(candidates, by=first, rev=true)
    return [x[2] for x in first(candidates, min(k, length(candidates)))]
end
