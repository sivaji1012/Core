#!/usr/bin/env bash
# extract_banc_subset.sh — companion to extract_fafb_subset.sh.
#
# Produces the BANC v626 (brain-and-nerve-cord) connectome in the SAME TSV
# format as fafb_pairs.tsv so the two can be loaded into ONE atomspace.
#
# WHY one atomspace, not multi-space: FAFB v783 (brain) + BANC v626 (VNC) are
# two reconstructions of ONE living being — Drosophila melanogaster. Splitting
# them across separate atomspaces is a software-engineering artifact, not a
# biological boundary. Shared root_ids in both reconstructions identify the
# same neuron; descending neurons (brain→VNC) and ascending neurons (VNC→brain)
# only function correctly when both halves of the nervous system are in the
# same connected graph. See docs/specs/flywire_connectome_spec.md §11.
#
# INPUT  (gitignored real data — see docs/specs/flywire_connectome_spec.md §11):
#   docs/research/fruit fly/BANC v626/connections_princeton.csv.gz  (3.78M rows)
#   docs/research/fruit fly/BANC v626/neurons.csv_2.gz              (115K rows)
# OUTPUT (small, reproducible; written to $OUT, default /tmp):
#   banc_pairs.tsv              — connectome aggregated to unique (pre,post,Σsyn)
#   banc_motor_neurons.txt      — root_ids classified as motor neurons (optional seed set)
#   banc_descending_neurons.txt — root_ids classified as descending (brain→VNC bridge)
#   banc_ascending_neurons.txt  — root_ids classified as ascending  (VNC→brain bridge)
#
# DELIBERATELY NOT INCLUDED (vs FAFB script):
#   - No deterministic oracle (the cross-dataset flow oracle is more subtle —
#     would need combined-graph awk pass; deferred to integration step).
#   - No K-bounded subgraph atom files (the unified graph is the value; per-K
#     subgraphs only made sense when validating the FAFB Fig-6 specific cut).
#   - No "modality" seed (BANC is the VNC, not sensory periphery — its neurons
#     don't decompose into the 7 FAFB sensory modalities. Motor / descending /
#     ascending are the analogous functional classes).
#
# USAGE:  ./extract_banc_subset.sh
#         (no args — produces the canonical aggregated outputs)
set -euo pipefail

DATA="${DATA:-$HOME/PRIMUS/docs/research/fruit fly/BANC v626}"
OUT="${OUT:-/tmp}"
CONN="$DATA/connections_princeton.csv.gz"
NEUR="$DATA/neurons.csv_2.gz"

[ -f "$CONN" ] || { echo "missing $CONN" >&2; exit 1; }
[ -f "$NEUR" ] || { echo "missing $NEUR" >&2; exit 1; }

# 1. Aggregate per-neuropil edges -> unique (pre,post,Σsyn).
#    BANC's connections_princeton.csv.gz schema matches FAFB's exactly:
#      pre_root_id,post_root_id,neuropil,syn_count,nt_type
#    so this awk is identical to the FAFB pipeline. ~30s on the 3.78M rows.
if [ ! -s "$OUT/banc_pairs.tsv" ]; then
  echo "[1/2] aggregating BANC connectome -> $OUT/banc_pairs.tsv ..." >&2
  zcat "$CONN" | tail -n +2 | \
    awk -F, '{c[$1 SUBSEP $2]+=$4}
             END{for(k in c){split(k,a,SUBSEP); print a[1]"\t"a[2]"\t"c[k]}}' \
    > "$OUT/banc_pairs.tsv"
fi
echo "      unique edges: $(wc -l < "$OUT/banc_pairs.tsv")" >&2

# 2. Extract VNC-functional neuron classes from neurons.csv_2.gz.
#    BANC's classification differs from FAFB's: 21 columns, capitalized headers,
#    most fields blank for unclassified neurons. We pull the ones we can use as
#    seed sets for cross-dataset flow analysis later.
#
#    Schema (positionally — cols are comma-separated, header at line 1):
#      1: Root ID
#      2: Top in/out region
#      3: Community labels
#      4: Predicted NT type
#     11: Super Class
#     12: Class
#     13: Sub Class
#     14: Hemilineage
#     15: Nerve
#     16: Soma side
#     17: Primary Cell Type
echo "[2/2] extracting VNC functional classes from $NEUR ..." >&2

# Motor neurons — `Super Class` contains "motor" or `Class` contains "motor"
zcat "$NEUR" | tail -n +2 | \
  awk -F, 'tolower($11) ~ /motor/ || tolower($12) ~ /motor/ {print $1}' \
  | sort -u > "$OUT/banc_motor_neurons.txt"
echo "      motor neurons:      $(wc -l < "$OUT/banc_motor_neurons.txt")" >&2

# Descending neurons — class or sub_class contains "descending" (brain→VNC bridge)
zcat "$NEUR" | tail -n +2 | \
  awk -F, 'tolower($12) ~ /descending/ || tolower($13) ~ /descending/ {print $1}' \
  | sort -u > "$OUT/banc_descending_neurons.txt"
echo "      descending neurons: $(wc -l < "$OUT/banc_descending_neurons.txt")" >&2

# Ascending neurons — class or sub_class contains "ascending" (VNC→brain bridge)
zcat "$NEUR" | tail -n +2 | \
  awk -F, 'tolower($12) ~ /ascending/ || tolower($13) ~ /ascending/ {print $1}' \
  | sort -u > "$OUT/banc_ascending_neurons.txt"
echo "      ascending neurons:  $(wc -l < "$OUT/banc_ascending_neurons.txt")" >&2

echo "" >&2
echo "DONE. BANC edges + functional neuron classes ready in $OUT/" >&2
echo "" >&2
echo "Next: combined-load FAFB + BANC into one PathMap btm. Bytes are identical" >&2
echo "encoding; shared root_ids unify automatically. Example:" >&2
echo "  bulk_load_syn!(s, \"$OUT/fafb_pairs.tsv\")     # FAFB first" >&2
echo "  bulk_load_syn!(s, \"$OUT/banc_pairs.tsv\")     # BANC into same trie" >&2
echo "  act_save(act_from_zipper(s.btm, ...), \"/tmp/fly.act\")  # one .act for both" >&2
