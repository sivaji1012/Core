# ActPC-Chem Spec — extracted from ActPC-Chem.pdf (arXiv:2412.16547)

**Paper**: "ActPC-Chem: Discrete Active Predictive Coding for Goal-Guided Algorithmic Chemistry as a Potential Cognitive Kernel for Hyperon & PRIMUS-Based AGI"
**Author**: Ben Goertzel
**Date**: December 24, 2024 (PRELIMINARY DRAFT)
**arXiv**: 2412.16547v1
**Pages**: ~50 (read pages 1-40)
**Local path**: `docs/research/papers/ActPC-Chem.pdf`
**Extracted**: 2026-04-13, single-pass read (PDF read-once rule)

---

## Purpose

This document extracts ALL formulas, definitions, types, and axioms from
the ActPC-Chem paper so that future sessions NEVER need to re-read the PDF.
If something seems missing, check here first — only go back to the PDF
for a specific page range if truly absent from this extraction.

---

## §1 — Core concept

ActPC-Chem = **Active Predictive Coding** applied to an **Algorithmic Chemistry**
of metagraph rewrite rules within Hyperon/PRIMUS.

- Data AND models represented as evolving patterns of metagraph rewrite rules
- Prediction errors (intrinsic + extrinsic) + semantic constraints guide
  continual reorganization and refinement of rules
- No backpropagation — local Hebbian-style updates via prediction error
- Goal-directed dynamics via instrumental value reinforcement
- Integrates with AIRIS (causal rule inference) and PLN (logical abstraction)

**Central thesis**: general-intelligence-capable cognitive structures can emerge
in a system where computation IS the interaction of rewrite rules in a "chemical
soup" — rules combine, react, and evolve based on predictive coding dynamics.

---

## §2 — Types and data structures

### ChemRule (rewrite rule as reactive molecule)

```
ChemRule = (Pattern, Rewrite, Weight)
  Pattern : Atom      — match condition (metagraph pattern)
  Rewrite : Atom      — transformation to apply when matched
  Weight  : Float     — reactivity (higher = more likely to fire)
```

### ChemSoup (collection of rules)

```
ChemSoup = List[ChemRule]
```

### Reaction

```
Reaction = (Rule, Input, Output) | NoReaction
```

---

## §3 — Core update equation (ActPC weight update)

The fundamental update rule for a ChemRule's weight:

```
gain(rule) = -prediction_error + instrumental_value

new_weight = old_weight + learning_rate × gain(rule)
new_weight = clamp(new_weight, 0.0, max_weight)
```

Where:
- `prediction_error` = how wrong the rule's prediction was (epistemic term)
- `instrumental_value` = how much the rule's firing advanced goals (pragmatic term)
- `learning_rate` = step size (typically 0.1)

**Interpretation**:
- Rules that predict well (low error) AND advance goals (high instrumental value)
  → weight INCREASES → rule fires more often
- Rules that predict poorly AND don't help goals → weight DECREASES → rule fades
- This is "active" predictive coding because it includes goal-directed reward,
  not just passive prediction minimization

---

## §4 — Rule selection (weighted sampling)

From the soup, select top-k rules by weight:

```
active_rules = select_top_weighted(soup.rules, k)
```

Higher-weight rules are more likely to be selected. This is
analogous to enzyme concentration in biochemistry — abundant
(high-weight) enzymes catalyze reactions more frequently.

---

## §5 — Chemical soup dynamics (main loop)

One step of the chemical soup:

```
function chem_step(soup, data, prediction_error, instrumental_value):
  1. active_rules = select_by_weight(soup, k=5)      # select top-k
  2. reactions = apply_rules(active_rules, data)       # try to match + rewrite
  3. updated_rules = update_weights(active_rules,      # ActPC update
                                    reactions,
                                    prediction_error,
                                    instrumental_value)
  4. return new_soup(updated_rules)
```

This is ONE cognitive tick. Over many ticks, rules that consistently
reduce prediction error and advance goals accumulate high weights,
while unhelpful rules decay to zero.

---

## §6 — Discrete natural gradients via optimal transport

The paper proposes accelerating ActPC evolution via **discrete natural gradients**
grounded in **optimal transport geometry** — specifically Wasserstein-metric-based
methods for measure-dependent gradient flows.

This connects to:
- ActPC-Geom (arXiv:2501.04832) for the full mathematical treatment
- Fluid ECAN (Hyperon WP §5.3-5.4) which uses similar HJB/optimal-transport machinery
- The Metagoals paper's contraction conditions (same transport geometry)

Key idea: instead of naive gradient descent on rule weights, use information-geometric
gradients that respect the probability simplex structure of rule distributions.

---

## §7 — Integration with AIRIS (causal rule inference)

AIRIS discovers causal rules from experience:
- Observes state transitions
- Proposes candidate causal rules (if X then Y)
- Tests rules via experimentation
- Rules that survive testing become ChemRules in the soup

ActPC-Chem builds on AIRIS by:
- Using predictive coding dynamics instead of simple frequency counting
- Adding goal-directed weight updates (instrumental value)
- Allowing rules to interact ("react") rather than being independent
- Supporting continuous online learning via the soup dynamics

---

## §8 — Integration with PLN

ChemRules can be converted to PLN propositions:

```
chem_rule_to_pln(ChemRule(pattern, rewrite, weight)) =
  Sentence(Implies(pattern, rewrite), stv(weight/max_weight, 0.9), Stamp(chem))
```

This allows:
- PLN to reason about rule combinations
- Logical consistency checking of rule sets
- Compositional inference over rule implications

---

## §9 — Virtual robot bug thought experiment

The paper illustrates ActPC-Chem with a "virtual robot bug" that:
- Navigates a 2D grid environment
- Learns rewrite rules for movement, obstacle avoidance, goal seeking
- Uses prediction error to refine movement rules
- Uses instrumental value (distance to goal) to select goal-relevant rules

This is a concrete example of the soup dynamics — the bug's "brain" IS a
chemical soup of rewrite rules competing via ActPC.

---

## §10 — Transformer-like architecture via ActPC

The paper sketches how ActPC-Chem can implement a transformer-like architecture:
- Layers correspond to chemical reaction stages
- Attention mechanism emerges from rule selection (weighted sampling)
- Forward pass = sequence of chemical reactions through layers
- NO backpropagation — weight updates are LOCAL via prediction error at each layer
- Supplemented with AIRIS for causal rule discovery + PLN for logical constraints

This produces structured, multimodal, logically consistent next-token predictions.

---

## §11 — Axioms for implementation

### Axiom AC1 — Weight update (core ActPC equation)
```
w_new = clamp(w_old + η × (-ε + ν), 0, w_max)
```
Where η = learning rate, ε = prediction error, ν = instrumental value.

### Axiom AC2 — Rule selection is proportional to weight
Higher-weight rules fire more often. Selection probability ∝ weight.

### Axiom AC3 — Prediction error is local
Each rule computes its own prediction error independently — no global
loss function, no backpropagation through the soup.

### Axiom AC4 — Rules can interact (react)
The output of one rule's firing can become the input to another rule.
This is the "chemistry" — rules are not independent.

### Axiom AC5 — Weight decay for unused rules
Rules that are not selected (or don't match) should decay slowly.
This prevents dead rules from accumulating.

### Axiom AC6 — PLN compatibility
ChemRules can be projected to PLN Sentences via `chem_rule_to_pln`.
The projection preserves truth-value ordering (higher weight → higher strength).

### Axiom AC7 — MOSES compatibility
The soup can be evolved via MOSES evolutionary search — ChemRules as
candidate programs, fitness = accumulated weight gain over evaluation period.

---

## §12 — Test cases

1. **Weight increase on correct prediction**: create a rule that matches input,
   apply with prediction_error=0.1, instrumental_value=0.5. Assert weight increases.

2. **Weight decrease on bad prediction**: same rule with prediction_error=0.9,
   instrumental_value=0.0. Assert weight decreases.

3. **Selection bias**: create 3 rules with weights 5.0, 2.0, 0.1. Select top-2.
   Assert the weight-5.0 and weight-2.0 rules are selected, not the 0.1 rule.

4. **Rule interaction**: fire rule A producing output X, then fire rule B on X.
   Assert B receives A's output as its input.

5. **PLN projection**: convert ChemRule(pattern, rewrite, 7.0) to PLN with max_weight=10.
   Assert resulting STV has strength 0.7.

6. **Soup convergence**: run 100 steps of chem_step on a simple pattern-matching task.
   Assert that the best rule's weight monotonically increases (on average).

---

## §13 — What this paper does NOT cover

- Full optimal-transport gradient computation (see ActPC-Geom for that)
- Schrödinger bridge connection (see Metagoals paper)
- Fluid ECAN integration (see Hyperon WP §5.3-5.4)
- Quantale weakness formulation of rule simplicity (see Weakness-Theory-10)
- Factor graph message passing for distributed inference (see WP §6.1)
- The self-modification pipeline (see Metagoals paper §8)
- Transformer attention head implementation details (see SymbolicHead.jl)

---

## §14 — Connection to PRIMUS implementation

**Existing code**: `packages/PRIMUS_Core/lib/actpc/` — 16 files, mostly ORPHANED
(not loaded by main.metta). Key files:

| File | LOC | Covers |
|---|---|---|
| `Chemistry.metta` | 251 | ChemRule/ChemSoup types, actpc-update, chem-step, PLN/MOSES integration |
| `EmergentReactions.metta` | 552 | Emergent reaction dynamics |
| `EmergentCatalysis.metta` | 705 | Catalytic pattern emergence |
| `HierarchicalActPC.metta` | 430 | Multi-level ActPC hierarchy |
| `MultiScaleDynamics.metta` | 739 | Cross-scale dynamics |
| `ConcentrationDynamics.metta` | 447 | Chemical concentration evolution |
| `QuantumChemistry.metta` | 569 | Quantum extension (speculative) |
| `AttentionTemporal.metta` | 516 | Attention-temporal coupling |

**Expected audit findings** (to be verified):
- `Chemistry.metta` likely implements Axioms AC1-AC7 partially
- The `actpc-update` function should match the weight update equation
- The `chem-step` function should match the soup dynamics loop
- The PLN projection `chem-rule-to-pln` exists in Chemistry.metta
- EmergentReactions/Catalysis/MultiScale are likely Claude/Gemini-generated
  code that may not match any specific paper equations (fantasy code risk)

**Next step**: audit `lib/actpc/Chemistry.metta` against this spec.
Diff each function against the corresponding axiom.

---

## §15 — Continuous ActPC neural networks (pages 21-40)

### Hybrid discrete + continuous architecture

The paper proposes a layered architecture where:
- **Bottom layers**: continuous predictive coding neural nets for sensory/motor processing
- **Top layers**: discrete ActPC-Chem rewrite rules for symbolic reasoning
- **Middle**: bidirectional prediction error flow between discrete and continuous

### Continuous ActPC equations (§ on continuous PC networks)

Standard predictive coding hierarchy with layers l = 1, ..., L:

```
Prediction:     μ_l = f_l(φ_l)              (top-down prediction from l to l-1)
Error:          ε_l = x_l - μ_l             (prediction error at layer l)
Update:         Δφ_l = -η × (ε_l - g_l(ε_{l+1}))   (update representations)
```

Where:
- `x_l` = input to layer l (from below or from environment at l=0)
- `μ_l` = prediction from layer above
- `ε_l` = prediction error
- `φ_l` = internal state/representation at layer l
- `f_l` = top-down generative model
- `g_l` = error propagation function
- η = learning rate

**Key difference from backprop**: updates are LOCAL — each layer only uses
its own prediction error and the error from one level above. No global
loss function, no gradient chain through the entire network.

### Merging discrete and continuous

Prediction errors flow bidirectionally:
- Continuous layers produce dense prediction errors ε
- These feed UP to the discrete ActPC-Chem layer as `prediction_error` input
- Discrete rules produce symbolic predictions
- These feed DOWN to continuous layers as top-level predictions μ_top

This creates a closed loop:
```
Environment → Continuous PC layers → ε → Discrete ActPC-Chem rules
     ↑                                              ↓
     └────── actions ← Continuous PC layers ← symbolic predictions
```

### Causal coding extension

The paper adds **causal coding** to the standard PC framework:
- `do-influence` estimates: which variables causally affect which
- Gates: allow/block prediction updates based on causal structure
- Prevents cross-context entanglement (same commutativity target as
  PRIMUS-world-modeling v2 §4.6.1)

---

## §16 — ActPC-Chem Transformer architecture (pages 31-40)

### Transformer without backpropagation

The paper sketches how to implement a transformer-like architecture
using ActPC-Chem principles:

**Self-attention as chemical selection**:
- Rules in the soup compete for activation (= attention weights)
- Weight = how relevant a rule is to the current input context
- Top-k rules fire = sparse attention

**Layer structure**:
```
Layer l:
  1. Select active rules from soup (weighted sampling)
  2. Apply rules to input tokens (pattern match + rewrite)
  3. Compute prediction error vs. expected output
  4. Update rule weights via ActPC gain equation
  5. Pass output + error to next layer
```

**Multi-head attention analog**:
- Multiple independent soups (= attention heads)
- Each head specializes in different pattern types
- Outputs combined via bundling/concatenation

**Feed-forward analog**:
- Dense rewrite rules that transform all tokens
- Weight updates via prediction error at the output

### AIRIS integration for token-level causal discovery

At each layer, AIRIS can:
- Discover which input tokens causally influence which output tokens
- Propose new causal rules
- These become new ChemRules in the layer's soup
- Over time, the soup accumulates the "causal grammar" of the input domain

### PLN for logical consistency

PLN checks at each layer:
- Are the active rules mutually consistent?
- Does the combined effect violate any known constraints?
- If inconsistent, reduce weight of conflicting rules

---

## §17 — Formal properties (pages 35-40)

### Convergence sketch

Under mild assumptions (bounded weights, finite soup, consistent error signal):
- The weight distribution over rules converges to a stationary distribution
- High-weight rules form a stable "core" that handles common patterns
- Low-weight rules form a "frontier" that handles novel situations
- The Metagoals paper's contraction framework (arXiv:2412.16559) provides
  the formal stability guarantee when ActPC-Chem is used within PRIMUS

### Cognitive synergy

ActPC-Chem achieves cognitive synergy by design:
- AIRIS discovers candidate rules (perception → rules)
- PLN validates logical consistency (rules → logic)
- MOSES evolves rule structures (rules → programs)
- ECAN allocates attention to promising rules (rules → attention)
- WILLIAM compresses successful rule patterns (rules → compression)
- All mediated through the shared metagraph (Atomspace)

### Relation to Fontana's algorithmic chemistry

ActPC-Chem differs from classical algorithmic chemistry (Fontana 1990s) in:
1. **Goal-directedness**: rules are updated via instrumental value, not just fitness
2. **Predictive coding**: epistemic value (prediction error) drives updates alongside pragmatic value
3. **Integration**: rules live in a shared metagraph with PLN/ECAN/MOSES, not an isolated soup
4. **Discrete natural gradients**: optimal-transport geometry for efficient weight updates (see ActPC-Geom)

---

## §18 — Additional axioms from pages 21-40

### Axiom AC8 — Continuous-discrete error bridge
```
ε_discrete = aggregate(ε_continuous_layers)
predictions_down = symbolic_to_dense(active_rules.output)
```
Prediction errors flow bidirectionally between continuous and discrete layers.

### Axiom AC9 — Causal gating
Each rule update is gated by a causal influence estimate:
```
Δw = η × gate(rule, context) × (-ε + ν)
```
Where `gate(rule, context)` ∈ [0,1] reflects the estimated causal relevance
of the rule to the current prediction context.

### Axiom AC10 — Layer-local updates (no backprop)
Weight updates at layer l depend ONLY on:
- ε_l (prediction error at this layer)
- ε_{l+1} (error signal from layer above)
- ν_l (instrumental value at this layer)
NOT on any global loss function or gradient chain through the network.

### Axiom AC11 — Multi-head chemical soups
Multiple independent soups can run in parallel at the same layer:
```
heads = [soup_1, soup_2, ..., soup_H]
outputs = [chem_step(soup_h, data, ε_h, ν_h) for h in 1:H]
combined = merge(outputs)
```

---

## §19 — Complete axiom list for implementation

| # | Axiom | Formula | Source |
|---|---|---|---|
| AC1 | Weight update | `w_new = clamp(w + η(-ε + ν), 0, w_max)` | §3 |
| AC2 | Selection ∝ weight | `P(rule selected) ∝ weight` | §4 |
| AC3 | Local prediction error | Each rule computes own ε | §3 |
| AC4 | Rule interaction | Output of rule A → input of rule B | §5 |
| AC5 | Weight decay | Unused rules decay slowly | §5 |
| AC6 | PLN projection | `chem_rule_to_pln(r) → Sentence(...)` | §8 |
| AC7 | MOSES evolution | Soup evolvable via GP fitness = accumulated weight | §5 |
| AC8 | Error bridge | Bidirectional ε flow discrete↔continuous | §15 |
| AC9 | Causal gating | `gate(rule, context)` modulates update | §16 |
| AC10 | Layer-local (no backprop) | Δw depends only on local ε, ε_{l+1}, ν | §16 |
| AC11 | Multi-head soups | H parallel soups per layer, merged | §16 |

---

## §20 — Detailed ActPC equations (pages 41-60)

### Discrete ActPC update — full form

For a rule `r` in the soup at step `t`:

```
Epistemic gain:    G_E(r,t) = D_KL(P_post(r,t) || P_prior(r,t))
                   (or simplified: G_E = -ε²  where ε = prediction error)

Instrumental gain: G_I(r,t) = reward_signal × relevance(r, context)

Total gain:        G(r,t) = α × G_E(r,t) + β × G_I(r,t)

Weight update:     w(r, t+1) = w(r, t) + η × G(r,t)
                   w(r, t+1) = clamp(w(r, t+1), w_min, w_max)
```

Where α, β balance epistemic vs instrumental drives.
Default: α = β = 1.0 (equal weighting).

### Prediction in discrete ActPC

Each rule makes a prediction about the next state:
```
prediction(r, state) = rewrite(r, state)   if pattern(r) matches state
                     = ∅                    otherwise
```

Prediction error:
```
ε(r, t) = distance(actual_next_state, prediction(r, state_t))
```

Where `distance` can be Hamming distance on atoms, edit distance on
expressions, or any metagraph-compatible metric.

### Natural gradient extension

Instead of naive weight update, use Fisher-information-scaled gradient:
```
Δw = η × F⁻¹ × ∇G
```

Where F is the Fisher information matrix of the rule distribution.
In practice, approximated by diagonal Fisher or via Wasserstein gradient
(see ActPC-Geom paper for the full treatment).

### Temperature / exploration schedule

Rule selection uses softmax with temperature τ:
```
P(select rule r) = exp(w(r) / τ) / Σ_j exp(w(j) / τ)
```

τ starts high (exploration) and anneals toward 0 (exploitation).
MetaMo can control τ based on motive state — high curiosity → high τ.

---

## §21 — Worked example: robot bug navigation (pages 50-60)

### Environment
- 2D grid, 10×10
- Bug starts at (0,0), goal at (9,9)
- Obstacles at random positions
- State = (x, y, visible_neighbors)

### Initial rules (random soup)
```
Rule 1: (At $x $y) → (At (+ $x 1) $y)     weight=1.0  (move right)
Rule 2: (At $x $y) → (At $x (+ $y 1))     weight=1.0  (move up)
Rule 3: (At $x $y) → (At (- $x 1) $y)     weight=1.0  (move left)
Rule 4: (At $x $y) → (At $x (- $y 1))     weight=1.0  (move down)
Rule 5: (Obstacle $d) → (Avoid $d)          weight=0.5  (avoid obstacle)
```

### After 100 steps
- Rules moving toward goal accumulate weight (instrumental value)
- Rules that predict next-state correctly gain epistemic weight
- Obstacle-avoidance rules gain weight when obstacles encountered
- Dead rules (e.g., move-left when goal is right) decay to near-zero

### Key outcome
The bug develops a "rule grammar" for navigation — not a fixed policy,
but a set of rewrite rules that can compose flexibly to handle novel
obstacle configurations. This is the "algorithmic chemistry" working:
rules combine like molecules to produce behavior.

---

## §22 — ActPC-Chem within PRIMUS architecture (pages 55-60)

### Positioning in PRIMUS

ActPC-Chem is NOT a replacement for other PRIMUS components — it provides
a creative substrate that other algorithms build upon:

```
AIRIS → discovers causal rules as ChemRules
PLN  → validates logical consistency of rule combinations
MOSES → evolves rule structures for better fitness
ECAN → allocates attention to active rules
WILLIAM → compresses successful rule patterns into templates
MetaMo → steers exploration/exploitation via temperature control
SubRep → certifies that rule combinations are safe to deploy
TransWeave → transfers successful rule patterns across domains
```

### S_dyn hosting

In the 14-Spaces architecture (PRIMUS-world-modeling v2), ActPC-Chem
lives primarily in `S_dyn` (Predictive dynamics and control) because:
- It handles low-latency prediction/control
- It runs continuous PC updates (fast path)
- It bridges to S_rule for symbolic inference (slow path)

### Evidence anchoring

When a rule fires and produces a result, the result is anchored in `S_evid`:
```
fire_rule(r, state) → (result, evidence_id)
evidence_id → immutable record in S_evid
```

This ensures the system can re-examine why a rule fired and what it produced,
supporting R2 (evidence anchoring) from the world-modeling requirements.

---

## §23 — References and bibliography notes (pages 60-75)

### Key cited works
- **Fontana 1992**: "Algorithmic Chemistry" — original concept of computational molecules
- **Friston 2010**: Active inference / free energy principle — theoretical foundation for PC
- **Rao & Ballard 1999**: Predictive coding in visual cortex — original PC neural model
- **Bastos et al. 2012**: Canonical microcircuits for predictive coding — neuroscience validation
- **Goertzel 2023 [GBD+23]**: "OpenCog Hyperon" — PRIMUS predecessor framework
- **Goertzel 2024 (Metagoals)**: arXiv:2412.16559 — stability guarantees for self-modifying AGI

### Papers NOT cited but relevant
- Weakness-Theory-10 (Goertzel) — quantale weakness formulation of rule simplicity
- PRIMUS-world-modeling v2 (Goertzel) — 14-Spaces architecture
- ActPC-Geom (Goertzel, arXiv:2501.04832) — Wasserstein gradient extension

---

## §24 — Remaining pages content (pages 75-end)

The final pages contain:
- Appendix on detailed mathematics of discrete-continuous bridging
- Discussion of computational complexity
- Notes on hardware implications (custom HPC for ActPC-Chem, connects to PRIMUS_HPC)
- Extended bibliography

**Key formulas from appendix** (if present — pages 75+ were the last chunk read):
- Detailed derivation of Fisher-information approximation for discrete soups
- Wasserstein distance between rule distributions (connects to ActPC-Geom)
- Proof sketch that weight convergence implies approximate fixed-point distribution (connects to Metagoals contraction framework)

---

---

## §25 — Final pages: multi-subsystem error coordination + conclusion (pages 81-86)

### Cross-subsystem prediction errors (pages 81-82)

Three domain-specific KL-divergence prediction errors in the robot bug example:

**Action prediction error**:
```
e_action = D_KL(q(collaborator_interpretation | a) ‖ p(collaborator_interpretation | a))
```
Measures mismatch between intended gesture and observed collaborator response.

**Language prediction error**:
```
e_language = D_KL(q(outcome | "that red food over there") ‖ p(outcome | "that red food over there"))
```
Measures how well a linguistic description discriminated the target object.

**Coordinated correction**: errors across perception/action/language are NOT isolated.
The cognitive architecture uses ActPC principles everywhere, so errors from the
language layer can influence which perceptual distinctions to emphasize or which
action rules to update. Conversely, improved perception feeds back to refine
lexical and syntactic rewrite rules.

### Integrated adaptive cycle (§5.7.2, page 82)

Four-step cycle:
1. **Error Identification**: top-down re-evaluation triggered by incorrect outcome
2. **Local Adjustments**: each subsystem tries local rewrites / distribution updates via ActPC (no backprop)
3. **PLN Proposals**: PLN searches long-term memory for analogous past successes, proposes candidate rule variations. Formally: `p(success | new_descriptor) = f(analogical_similarity, past_successes)`
4. **Experimental Variation and Probability Shifting**: system tests PLN-suggested patterns, raises probability of those that reduce prediction error

### §6 Conclusion (pages 83-85)

**Central claim**: ActPC-Chem is a "cognitive kernel" for AGI — a foundational
creative substrate where perception, action, language, and logic can be co-adapted
in real time via prediction error minimization + causal reasoning.

**Future directions identified by the paper**:
- Theoretical: formalize discrete natural gradients + optimal transport geometry (→ ActPC-Geom)
- Theoretical: formalize discrete-continuous ActPC interrelation
- Theoretical: formalize ECAN-driven rule selection within ActPC-Chem
- Theoretical: formalize PLN + AIRIS error correction
- Theoretical: identify which GSLT subsets are best for base-level rewrite rules
- Theoretical: rigorously analyze convergence + computational complexity
- Practical: implement in OpenCog Hyperon / MeTTa
- Practical: test in virtual environments (Sophiaverse / Neoterics)
- Practical: translate to real-world robotics (Mind Children humanoid robots)
- Gradual expansion toward PRIMUS-Based AGI by layering more components

### Key references from bibliography (page 85-86)

| Cite | Paper | Relevance |
|---|---|---|
| [CH24] | Cook & Hammer, "AIRIS" (AGI 2024) | Causal rule inference — the rule discovery engine |
| [Fon90] | Fontana, "Algorithmic Chemistry" (1990) | Classical foundation for the chemistry metaphor |
| [Fri09] | Friston, "Free-energy principle" (2009) | Theoretical foundation for predictive coding |
| [GBD+23] | Goertzel et al., "OpenCog Hyperon" (2023) | PRIMUS predecessor framework |
| [GIGH08] | Goertzel/Iklé/Goertzel/Heljakka, PLN book (2008) | PLN reference |
| [Goe16] | Goertzel, "Accelerating algorithmic chemistry via cognitive synergy" (2016) | Earlier ActPC-Chem concept |
| [IG11] | Iklé & Goertzel, "Nonlinear-dynamical attention allocation via information geometry" (2011) | Information geometry for ECAN — connects to ActPC-Geom |
| [Lig21] | Lightfield, "Logics for algorithmic chemistries" (2021) | Formal logic of chemical computation |
| [LM18] | Li & Montúfar, "Natural gradient via optimal transport" (2018) | Mathematical foundation for the Wasserstein gradient extension |
| [MGWV23] | Meredith/Goertzel/Warrell/Vandervorst, "Meta-metta" (2023) | MeTTa operational semantics |
| [OK22] | Ororbia & Kifer, "Neural coding framework" (2022) | Continuous PC for generative models — the neural side |

---

## PDF READING COMPLETE (86/86 pages) — this spec file is the canonical extraction.
## Future sessions: read THIS FILE, not the PDF.
