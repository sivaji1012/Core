# MeTTaCore

A standalone, pure-Julia MeTTa interpreter built directly on [MORK](https://github.com/trueagi-io/MORK) — the MeTTa Optimal Reduction Kernel.

Zero dependency on legacy PRIMUS_Core or PRIMUS_Metagraph. This is the redesigned substrate for running MeTTa cognitive programs.

## Architecture

```
MORK.Space  (byte-trie, PathMap substrate)
    ↓
CoreSpace   (AbstractAtomSpace — add, match, remove, rules)
    ↓
Parser      (S-expression parser → plain Julia values)
    ↓
Primitives  (grounded Julia: arithmetic, math, atom ops, type system)
AtomOps     (grounded: cons/car/cdr, foldl, map, filter, set ops)
    ↓
Eval        (MeTTa interpreter: rule rewriting + special forms)
    ↓
stdlib/     (pure .metta files — hot-reloadable, no recompile)
```

## What's grounded vs pure MeTTa

Per cross-verification with hyperon-experimental, CeTTa, Mettatron, and PeTTa:

**Grounded in Julia** (must control evaluation or access host):
- Arithmetic: `+` `-` `*` `/` `%` `^`
- Math: `sqrt-math` `abs-math` `sin-math` `cos-math` `floor-math` `ceil-math` etc.
- Comparison: `<` `>` `<=` `>=` `==`
- Atom ops: `cons-atom` `car-atom` `cdr-atom` `size-atom` `index-atom` `min-atom` `max-atom`
- Higher-order: `foldl-atom` `map-atom` `filter-atom` (need eval callback)
- Set ops: `unique-atom` `union-atom` `intersection-atom` `subtraction-atom`
- Space: `add-atom` `remove-atom` `get-atoms` `match` `new-space`
- Control: `chain` `function` `return` `case` `let` `eval` `unify` `collapse` `superpose`
- Equality: `=alpha` `noreduce-eq`
- Types: `get-type` `get-metatype` `match-types` `type-cast`
- State: `new-state` `get-state` `change-state!`
- I/O: `println!` `format-args`

**Pure MeTTa in `stdlib/`** (hot-reloadable, no recompile):
- `if` `if-equal` `if-error` `return-on-error` `noeval` `id`
- `foldl-atom` wrapper, `is-function`
- `length` `append` `reverse` `zip` `sort` `member`
- Math aliases (`sqrt`, `abs`, `sin`…), `square`, `clamp`, `even?`
- Type declarations (`: car-atom (-> Expression Atom)` etc.)
- HE-MeTTa compatibility: `assertAlphaEqual`, `evalc`, `noreduce-eq` surface

## Dependencies

- [MORK](https://github.com/sivaji1012/MORK) — byte-trie MeTTa kernel
- [PathMap](https://github.com/sivaji1012/PathMap) — prefix-tree substrate

## Quick start

```julia
using MeTTaCore

# Register all primitives + load stdlib
register_all_primitives!()
s = new_core_space()
load_stdlib!(s)

# Add rules
core_add!(s, [:(=), [:factorial, 0], 1])
core_add!(s, [:(=), [:factorial, Symbol("\$n")],
               [:*, Symbol("\$n"), [:factorial, [:-, Symbol("\$n"), 1]]]])

# Evaluate
eval_metta([:factorial, 5], s)   # → 120

# Run MeTTa source
results = run_metta("""
(= (double \$x) (* \$x 2))
!(double 21)
""", s)
# → [42]
```

## MeTTa compatibility

87/87 tests from the [MeTTa vs PeTTa comparison suite](https://github.com/tezena/PeTTa-and-MeTTa-comparisons) pass.

## Testing

```julia
using Pkg
Pkg.test("MeTTaCore")
```

## License

MIT
