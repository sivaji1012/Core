# Fly connectome → multi-space architecture

Maps the *Drosophila* central-brain information-flow model (Nature 2024, Fig 6)
onto PRIMUS's App+Common multi-space substrate (Whitepaper §9 Fig 4 + the
byte-prefix regions shipped 2026-05-27). Grounded directly in Fig 6:
panel **c** (neuron classes with inputs in the central brain), panel **d/b**
(seed modalities), panel **e** (class columns), panel **f** (neurotransmitters).

## The shape: multiple spaces *under* `central`, plus seed + output roles

```
common:/                              ← shared substrate (the whole central brain)
  connectome edges : (syn $pre $post $cnt)        ← the wiring; read by ALL flows
  ontology         : (neuron $id $class $modality $nt)

  central/    ── the central-brain PROCESSING classes (Fig 6c legend) ──
    central/kenyon_cells:/             (mushroom body intrinsic)
    central/mushroom_body_output:/     (MBONs)
    central/antennal_lobe_lns:/        (olfactory local neurons)
    central/central_complex:/          (navigation / integration)

  seed/       ── afferent INPUT modalities (Fig 6d + b — the 7 seeds) ──
    seed/thermosensory:/   seed/ascending:/   seed/olfactory:/
    seed/ocellar:/         seed/mech_jo:/     seed/visual_projection:/
    seed/gustatory:/

  out/        ── effector / OUTPUT classes (Fig 6c/e) ──
    out/motor:/    out/descending:/    out/endocrine:/    out/vcn:/
```

Three space **roles** over one shared connectome:
**seed** (sensory afferents) → **central** (processing, multiple spaces) →
**out** (effectors).

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

## Status

Design (reconstructed + grounded in Fig 6 + App+Common, 2026-05-27). Not yet
implemented. Build path: synthetic Stage 1 → C. elegans / EBRAINS-region →
FlyWire FAFB (Codex `Connections (Filtered)`, 68 MB) via `space_load_csv!`.
See memory `connectome-infoflow-plan` and `docs/specs/MORK_PATHMAP_SUBSTRATE_LEDGER.md`.
