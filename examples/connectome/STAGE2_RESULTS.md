# Connectome info-flow — Stage 2 (real FAFB v783 data)

Stage 2 swaps the synthetic Stage-1 graph for the **real adult-fly connectome**
(FlyWire FAFB v783, Dorkenwald et al. *Nature* 2024) and confirms the *unchanged*
[InfoFlow.metta](InfoFlow.metta) model reproduces a native reference oracle
**exactly** on real data — single-step and multi-step.

## What ran

1. **Aggregate** the edge list (`connections_princeton.csv.gz`, 5,342,447
   per-neuropil rows) into **3,732,460 unique `(pre, post, Σsyn)` pairs** (~41 s,
   pure `awk`). This is the weighted directed connectome the model consumes.
2. **Reference oracle** — the deterministic Fig-6a rule (`reached at step k+1
   iff Σsyn(reached→p) / Σsyn(*→p) ≥ 0.3`) computed natively over the *full* real
   graph from a sensory seed (`extract_fafb_subset.sh`). This is the ground truth
   the MeTTa run must match.
3. **Tractable subcircuit** — extract the step-bounded subgraph (all in-edges of
   every node reached through step K, so denominators are exact) as
   `(syn pre post cnt)` atoms, seed the afferent modality as `(reached <id> 0)`,
   and run the **same** `flow-step` on the warm MettaJam server.

## Result — thermosensory modality (29 afferent seeds)

| Run | Subgraph edges | MeTTa output | Oracle | Diff | Wall time |
|-----|---:|---|---|---|---:|
| **K=1** (one step) | 1,226 | rank-1 = **46** | 46 | **0** | ~52–81 s |
| **K=2** (iterate to fixed point) | 2,974 | rank-1 = **46**, rank-2 = **45** | 46 / 45 | **0 / 0** | ~380 s |

The MeTTa `reached`/`rank` sets are **identical to the oracle, node-for-node**
(`comm` diff = ∅ in both directions). The multi-step run confirms the
iterate-to-fixed-point logic on real data: rank-2 membership correctly depends
on the rank-1 set marked in the prior step, and `flow-step` halts when no new
neuron crosses the 0.3 threshold.

Oracle layer sizes on the full real graph (thermosensory): step 1 = 46,
2 = 45, 3 = 81, 4 = 109, 5 = 45. (Deterministic ≥0.3 reaches fewer per step than
the paper's stochastic-ramp averaging — expected; the oracle, not the paper's
147/498/… counts, is the pass criterion for *this* deterministic model.)

## A real substrate bug, found and fixed

The first K=1 run returned **45**, not 46 — one node (`…612305506`) with a
*single* in-edge from a seed neuron had `reached-in = 0` despite `total-in = 7`
and `reached? pre = True`. Root cause was in the evaluator, not the model:

- The interpreter represents both expressions and nondeterministic result
  streams as raw Julia `Vector`. `_eval_match` returned a **single** result
  *unwrapped* (`results[1]`); when that lone result was itself a tuple
  `($r $c)`, `_eval_collapse` mistook it for the results-list and iterated its
  two fields instead of treating it as one pair → `foldl-atom` summed garbage.
- Stage-1 synthetic nodes all had ≥2 in-edges, so `collapse` always saw a real
  multi-element list — the bug was invisible until a real single-in-edge neuron.

Fix ([Eval.jl](../../src/eval/Eval.jl)): added `_eval_match_all` (gathers the
full results vector, no single-result unwrap); `collapse` over `match`/`superpose`
now uses it, so a lone expression-valued result stays a 1-element stream.
Regression test added (`runtests.jl` testset 19); **119/119 pass**.

## Tractability boundary (→ Stage 3)

`core_match` is an **O(N) full trie-walk** with a shape pre-filter — it does not
narrow on a bound argument position (CoreSpace.jl flags the structural-trie-match
primitive as future work). The backward-scan model therefore costs
**O(candidates × total_atoms) per step**: ~1.2 k edges ran in ~80 s, ~3 k edges
in ~380 s. The full central-brain graph (tens of thousands of edges) or the whole
FAFB (3.73 M) is the **Stage-3 perf stress test**, and is the concrete workload
that triggers the deferred *structural-match / constant-factor* item in
`docs/specs/MORK_PATHMAP_SUBSTRATE_LEDGER.md`. Two scaling paths:
reverse-keying alone does **not** help (Core walks all atoms regardless of which
position is bound); the real fixes are (a) a trie-narrowing structural `match`
primitive in MORK, or (b) reformulating the per-step aggregation as a forward
push through `SumSink`/`CountSink` over the exec calculus.

## Reproduce

```bash
# (gitignored real data must be present under docs/research/fruit fly/FAFB v783/)
cd packages/Core/examples/connectome
./extract_fafb_subset.sh thermosensory 1          # → /tmp/fafb_thermosensory_k1_*.{metta,tsv}
cat <(sed -n '26,68p' InfoFlow.metta) \
    /tmp/fafb_thermosensory_k1_edges.metta /tmp/fafb_thermosensory_k1_seed.metta \
    <(echo '!(flow-step 1)') <(echo '!(collapse (match &self (reached $n 1) $n))') > /tmp/run.metta
curl -s -X POST http://127.0.0.1:7702/metta_stateless \
     -H 'Content-Type: text/plain' --data-binary @/tmp/run.metta
# diff the (reached $n $rank) set against /tmp/oracle_thermosensory.tsv → expect ∅
```

Citation for any published result: Dorkenwald, Matsliah, Sterling, Schlegel et al.
& The FlyWire Consortium, *Nature* **634**, 124–138 (2024), DOI
10.1038/s41586-024-07558-y. See `docs/specs/flywire_connectome_spec.md`.
