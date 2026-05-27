# Fly connectome → multi-space architecture

Maps the *Drosophila* central-brain information-flow model (Nature 2024, Fig 6)
onto PRIMUS's App+Common multi-space substrate (Whitepaper §9 Fig 4 + the
byte-prefix regions shipped 2026-05-27). Grounded directly in Fig 6:
panel **c** (neuron classes with inputs in the central brain), panel **d/b**
(seed modalities), panel **e** (class columns), panel **f** (neurotransmitters).

## The shape: multiple spaces *under* `central`, plus seed + output roles

Region labels + counts below are **grounded in the real FAFB v783 data**
(`classification.csv`: 139,256 neurons; the `flow` column = afferent/intrinsic/
efferent maps directly onto the three space roles; the `class` column gives the
sub-regions). `connections_princeton.csv` = 5,342,447 edges (per-neuropil;
~3.7M unique pairs when summed over neuropil).

```
common:/                              ← shared substrate (the whole brain)
  connectome edges : (syn $pre $post $cnt)   ← from connections_princeton.csv (5.34M)
  ontology         : (neuron $id $flow $super_class $class $nt)

  central/    ── flow=intrinsic (118,464) — the PROCESSING regions, by `class` ──
    central/optic_lobe_intrinsic:/    (77,382 — the optic lobes)
    central/kenyon_cell:/             (5,177 — mushroom body intrinsic)
    central/cx:/                      (2,878 — central complex)
    central/alpn:/  central/alln:/    (antennal lobe projection / local)
    central/lhln:/  central/lhcent:/  (lateral horn)
    central/mbon:/  central/dan:/     (MB output / dopaminergic)
    central/_unclassified:/           (30,355 — intrinsic, no fine class yet)

  seed/       ── flow=afferent (19,300) — INPUT modalities, by `class` ──
    seed/visual:/         (11,426)    seed/mechanosensory:/ (2,674)
    seed/olfactory:/      (2,281)     seed/an:/ (ascending, 2,276)
    seed/gustatory:/      (408)       seed/hygrosensory:/   (74)
    seed/thermosensory:/  (29)

  out/        ── flow=efferent (1,491) — effector OUTPUTS, by super_class ──
    out/descending:/ (1,305)   out/motor:/ (106)   out/endocrine:/ (80)
```

Three space **roles** over one shared connectome, read straight off the data's
`flow` field: **seed** (afferent) → **central** (intrinsic, multiple spaces) →
**out** (efferent).

## Mapping to App+Common (the committed federation model)

| Fly element | Space role | Rationale |
| --- | --- | --- |
| The connectome (`syn` edges) + ontology | **Common** (`common:/`) | Shared wiring, read by every modality's flow; never copied per modality |
| Each central processing class (Kenyon, MBON, AL-LN, CX) | **Common sub-region** (`central/*`) | Convergence zones — shared, but region-scoped for per-center analysis (Fig 6c/e densities) |
| Each sensory modality (olfactory, visual, …) | **App** (`seed/*`) | Independent afferent stream; holds its seed set + its own traversal state (`reached`/`rank`) |
| Effector classes (motor, descending, …) | **App** (`out/*`) | Where flow terminates; per-class rank density |

## How information flow uses it (Fig 6a model)

1. **Seed** a modality: mark its afferent neurons `reached` in `seed/<mod>:/`.
2. **Propagate** over the shared connectome in `common:/`: a neuron joins
   `reached` at step k+1 when
   `count{(syn R P): reached R} / count{(syn _ P)} ≥ 0.3`
   (the panel-a threshold; deterministic core of the probabilistic ramp).
   Counting = prefix-aware **CountSink**; iteration = **exec-to-fixed-point**.
3. **Rank** = the step a neuron was first reached (Fig 6b: Rank 1…5).
4. Run **per modality** — each in its own `seed/*` region, so the seven flows
   don't cross-contaminate and their rank distributions are directly
   comparable (Fig 6d/e).

## Why multi-space (not one flat space)

- **Per-modality isolation**: the seven seed flows run in disjoint prefix
  regions → compare ranks across modalities without interference. This is the
  prefix-region substrate's reason for existing.
- **Shared connectome**: `common:/` holds the wiring once; every flow reads it
  (no per-modality copy).
- **Region-scoped analysis**: `central/*` and `out/*` regions let us measure
  rank density per class/center directly (Fig 6c/e/f) with prefix-scoped
  queries.

## Data (on disk, 2026-05-27)

`docs/research/fruit fly/FAFB v783/` (Codex export, gzipped):
- `connections_princeton.csv.gz` (66 MB gz) — edges:
  `pre_root_id, post_root_id, neuropil, syn_count, nt_type` (5,342,447 rows).
- `classification.csv.gz` (913 KB) — `root_id, flow, super_class, class, …`
  (139,256) → seed/central/out region assignment.
- `neurons.csv.gz` (1.7 MB) — `root_id, nt_type, …` (Fig 6f neurotransmitters).
- (Skip: `fafb_v783_princeton_synapse_table.csv.gz` 2.6 GB raw synapses,
  `synapse_coordinates` 303 MB, `connections_*_no_threshold` 203–263 MB.)
`docs/research/fruit fly/BANC v626/` — `connections_princeton.csv.gz` (26 MB) +
`neurons.csv_2.gz` — for a later brain-vs-nerve-cord comparison.

## Status

Design grounded in Fig 6 + App+Common + the real FAFB v783 taxonomy
(2026-05-27). Not yet implemented. Build path: data-agnostic info-flow model
(synthetic Stage 1) → FAFB subset (one `class` or neuropil, measured) → full
FAFB (5.34M edges, the perf stress test). Ingest via `space_load_csv!`
(gunzip + column-filter first — `space_load_csv!` loads whole-file into memory,
so subset/aggregate the 5.34M before a full load). See memory
`connectome-infoflow-plan` and `docs/specs/MORK_PATHMAP_SUBSTRATE_LEDGER.md`.
