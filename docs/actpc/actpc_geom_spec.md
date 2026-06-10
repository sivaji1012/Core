# ActPC-Geom Spec — extracted from ActPC-Geom.pdf (arXiv:2501.04832)

**Paper**: "ActPC-Geom: Towards Scalable Online Neural-Symbolic Learning via Accelerating Active Predictive Coding with Information Geometry & Diverse Cognitive Mechanisms"
**Author**: Ben Goertzel
**Date**: January 8, 2025
**arXiv**: 2501.04832v1
**Pages**: 149
**Local path**: `docs/research/papers/FabricPC Hyperon Predictive coding/ActPC-Geom.pdf`
**Extraction**: 2026-04-13, incremental 15-page chunks
**Fidelity re-audit**: 2026-06-08 (full 149-page re-read)

---

## ⚠️ Fidelity audit note (2026-06-08)

A full re-read found the original extraction was *mostly faithful in spirit but
incomplete and structurally inaccurate*. Corrections applied in this revision:

1. **Removed the "WGAN" misattribution.** "WGAN" appears nowhere in the 149 pages. The
   paper's neural approximator is a generic net trained on a reconstruction loss (§4).
2. **Removed the fabricated "humanoid robotics / social interaction" applications.** The
   paper has no application sections; robotics is mentioned only in passing as motivation.
3. **Added the omitted paper §3** (metric tensor, Wasserstein natural-gradient ODE, PC
   error, §3.6 pseudocode) — see new [§4 below].
4. **Added the omitted paper §4 compression taxonomy** (4 methods incl. Wasserstein-Gaussian
   kernel, Nyström, random Fourier features, autoencoder, embedding prediction) — new [§5].
5. **Re-tagged AG4 and AG6 as PRIMUS cross-references, NOT paper extractions** (the
   KL-Wasserstein-gradient identity and the dual-channel φ_A/φ_G map do not appear in the
   PDF). Likewise the "Connection to Fluid ECAN / HJB / Navier-Stokes" block is a PRIMUS
   mapping, not extracted text.
6. **Fixed the §2 free-energy form** (the paper uses unweighted `Σ‖z^l − ẑ^l‖²`, not a
   σ²-weighted Gaussian free energy).
7. **Relabeled sections to the paper's real numbering** (verified TOC below). The original
   spec's running "§N" counter did not track the paper's own §-structure.

New axioms added: **AG38–AG45**. Two prior "axioms" (AG4, AG6) are kept but flagged
`[NOT IN PDF — PRIMUS mapping]`.

---

## Real paper structure (verified TOC, pp. 2–6 + body)

```
1   Introduction ...................................................... 7
  1.1 Addressing Scalability Challenges with Cognitive Solutions ...... 8
  1.2 ActPC-Geom Transformers ........................................ 9
  1.3 Neural-Symbolic Synergies ...................................... 9
  1.4 Potential for Aggressive Optimization ......................... 10
PART I — Enhancing and Accelerating ActPC with Information Geometry .. 10
2   Background ....................................................... 10
  2.1 Active Predictive Coding (ActPC) (2.1.1–2.1.4) ................. 10
  2.2 Information Geometry and Wasserstein Distance .................. 16
    2.2.1 Riemannian viewpoint and "Otto calculus" .................. 16
    2.2.2 Measure-dependent Laplacian ............................... 17
3   ActPC-Geom: Upgrading ActPC with Wasserstein Geometry ............ 18
  3.1 Setup; 3.2 Wasserstein Geometry (Ground Metric, Metric Tensor) . 18
  3.3 Wasserstein Natural Gradient Update; 3.4 PC Error .............. 20
  3.5 Summary of Core Equations; 3.6 Crude Pseudocode; 3.7 Concl. .... 21
4   Neural Approximators for Measure-Dependent Operators ............. 23
  4.1 Stochastic Low-Rank Decomposition of the Inverse ML ............ 24
  4.2 Compressed Representations (Direct ℓ2 / Autoencoder /
        Kernel Methods / Approximating Kernel PCA) ................... 25
  4.3 Predicting the Embedding Vector; 4.4 Overall Methodology ....... 30
5   Replacing KL with Wasserstein for ActPC Prediction Error ......... 32
  5.1 Optimal Transport as a Cognitively Relevant Least Action Princ.  32
        (5.1.1 action / 5.1.2 perception / 5.1.3 logic / 5.1.4 neuro)
  5.2 KL vs Wasserstein; 5.3 External↔Internal; 5.4 Continuity/Scale;
  5.5 Convex-Like Properties; 5.6 Scalable Wasserstein Computation ... 40
PART II — Cognitive Enhancements .................................... 49
6   Compositional Hypervector Embedding (6.1–6.3) ................... 49
7   Neural Architecture for Learning Fuzzy FCA Lattices (7.1–7.4) ... 61
8   Toward ActPC-Geom Based Transformers (8.1–8.5) ................. 67
9   Embedding Associative Long-Term Memory in ActPC Transformers .... 84
10  Symbolic/Subsymbolic Transformers via ActPC-Geom + ActPC-Chem ... 89
11  From Compositional Hypervectors to System-Level ActPC Reasoning . 94
PART III — Pathways to Optimized Implementation ................... 109
12  Efficient Concurrent Hybrid ActPC via Galois Connections ...... 110
13  Gesturing Toward a Specialized HPC Architecture ............... 124
References ........................................................ 134
Appendices A–E ................................................... 136
```

> The section headers below are annotated with the paper's real §/page in parentheses.

---

## §1 — Core concept (pages 1-10)

ActPC-Geom extends ActPC-Chem by integrating **information geometry** —
specifically **Wasserstein-metric-based methods** for measure-dependent gradient flows.

Key proposal: replace KL-divergence in ActPC's predictive error with the
**Wasserstein metric**, providing more robust integrated behavior across
the neural-symbolic network.

### Main contributions listed in abstract:
1. Neural approximators for inverse measure-dependent Laplacians required for information geometry calculations
2. Approximate kernel PCA embeddings for low-rank approximations of these neural approximators
3. Compositional hypervector embeddings from kPCA embeddings (complement to kPCA vectors)
4. Fuzzy FCA lattice-derived algebraic configuration for hypervectors
5. Hopfield-net-type dynamics in many layers for associative long-term memory
6. Galois connections for efficient concurrent processing of hybrid ActPC/ActPC-Chem networks

### Paper structure (from TOC, pages 2-6):
- **Part I**: Enhancing ActPC with Information Geometry (§1-§4)
  - Background on ActPC + Information Geometry + Wasserstein
  - Riemannian viewpoint, Otto calculus, measure-dependent Laplacian
  - WGAN-style natural gradient approximation
  - Approximate kernel PCA embeddings
- **Part II**: Diverse Neural-Symbolic Cognitive Mechanisms (§5-§8)
  - Compositional hypervector integration
  - Fuzzy concept lattice configuration
  - Hopfield associative memory in ActPC layers
  - Galois-fusion for concurrent symbolic+neural execution
- **[Correction]** The paper has **no** dedicated application sections (the original spec
  claimed "humanoid robotics, social interaction" — not present). Robotics appears only as
  passing motivation (sparse rewards, p. 11; novelty-seeking mobile robots, p. 36).

---

## §2 — Background: ActPC basic equations (paper §2.1, pp. 10–15)

### Canonical ActPC equations (paper §2.1.2, p. 13–14)

The paper uses an **unweighted** sum-of-squared-prediction-errors objective (NOT a
σ²-weighted Gaussian free energy — that was a spec-author embellishment):
```
L_pred = Σ_l ‖z^l − ẑ^l‖²                                          (paper §2.1.2)
```
where `ẑ^l = g^l(z^{l+1}, W^l)` is the top-down prediction of layer-l state from layer l+1.

**Local error** (the quantity each layer actually uses):
```
e^l = z^l − ẑ^l = z^l − g^l(z^{l+1}, W^l)                          (AG38, p. 14)
```

**Two coupled local updates** (state then weights, gradient descent on `L_total`):
```
z^l ← z^l − η_z ∇_{z^l} L_total           (activation / inference step)
W^l ← W^l − η_W ∇_{W^l} L_total           (weight / learning step)
```

**Weight-gradient expansion** (paper §2.1.2, p. 14):
```
∂‖e^l‖²/∂W^l = 2 e^l · ∂z^l/∂W^l − 2 e^l · ∂g^l(z^{l+1}, W^l)/∂W^l   (AG38, p. 14)
```

All updates are **local** — layer l only needs its own `e^l` and the neighboring layer
state. (The earlier `ε_l = x_l − f_θl(x_{l+1})` form is an equivalent paraphrase.)

### Discrete ActPC (rewrite rules)
Same as ActPC-Chem paper:
```
w_new = clamp(w + η(-ε + ν), 0, w_max)
```

### Combined discrete + continuous
- Bottom layers: continuous PC networks (perception, motor control)
- Top layers: discrete rewrite rule soups (symbolic reasoning)
- Bidirectional error flow between discrete and continuous

---

## §3 — Information geometry and Wasserstein distance (paper §2.2, pp. 16–17)

### Riemannian viewpoint (§2.2.1)

The space of probability distributions P over model parameters forms a
**Riemannian manifold** when equipped with the Fisher information metric:

```
g_ij(θ) = E_p(x|θ)[∂log p(x|θ)/∂θ_i × ∂log p(x|θ)/∂θ_j]
```

The **natural gradient** follows the steepest descent on this manifold:
```
Δθ = -η × G⁻¹(θ) × ∇_θ L
```
Where G(θ) is the Fisher information matrix.

### Otto calculus (§2.2.1)

Otto's key insight: the Wasserstein-2 distance on probability measures
can be viewed as a Riemannian distance on the "infinite-dimensional manifold"
of probability densities.

The **Wasserstein-2 distance**:
```
W₂(μ, ν) = (inf_γ ∫ ‖x-y‖² dγ(x,y))^{1/2}
```
Where γ ranges over all couplings of μ and ν.

### Measure-dependent Laplacian (§2.2.2, p. 17)

The paper writes the **continuous** measure-dependent Laplacian compactly as:
```
Δ_p φ = ∇·(p ∇φ)                                                  (paper §2.2.2, p. 17)
```
(equivalently `Δ_μ f = Δf + ∇log ρ · ∇f` for density ρ — an expansion, not the paper's form).

The **Otto tangent metric** that this operator induces (p. 16):
```
⟨φ, ψ⟩_p = ∫ p(x) ∇φ(x)·∇ψ(x) dx     with tangent identity   δp = −∇·(p ∇φ)   (AG39, p. 16)
```

**The discrete graph form that ActPC-Geom actually uses** (p. 17, 19, cited to [LM18]):
```
L(p)_{ij} = ω_{ij} (p_i + p_j),   i ≠ j        (AG40, pp. 17/19)
```
i.e. a weighted graph Laplacian on the support of the measure, with edge weights from the
ground metric ω. This — not the continuous PDE form — is the operator that gets inverted
and approximated in §4.

> **[NOT IN PDF — PRIMUS mapping]** The identity
> `grad_W KL(ρ‖π) = −div(ρ ∇log(ρ/π)) = −Δ_ρ log(ρ/π)` (spec AG4) is standard
> optimal-transport background but does **not** appear in this paper. Kept below as AG4 and
> flagged accordingly.

### Why Wasserstein over KL

KL-divergence problems:
- Undefined when supports don't overlap
- Asymmetric
- Sensitive to representation (reparameterization changes KL)

Wasserstein advantages:
- Always defined (uses ground metric)
- Metrizes weak convergence
- Respects geometry of the sample space
- "Earth mover's distance" — physically intuitive

---

## §4 — ActPC-Geom: upgrading ActPC with Wasserstein geometry (paper §3, pp. 18–23)

> **This section was entirely missing from the original spec.** It is the mathematical core
> of the paper. There is **no "WGAN"** anywhere in it.

### §3.2.2 — Metric tensor (p. 20)

The central object linking parameter space to distribution geometry. For parameters `ξ`
mapping (via Jacobian `J_ξ`) to a distribution `p(·|ξ)`:
```
G(ξ) = J_ξ^⊤ L(p(ξ))^† J_ξ                                        (AG41, p. 20)
```
where `L(p(ξ))^†` is the pseudo-inverse of the measure-dependent (graph) Laplacian AG40.

### §3.3 — Wasserstein natural-gradient update (p. 20)

Continuous-time gradient flow and its discrete step:
```
dξ/dt = − G(ξ)^{-1} ∇_ξ F(p(ξ))                                   (AG42, p. 20)
ξ_{k+1} = ξ_k − η G(ξ_k)^{-1} ∇_ξ F(p(ξ_k))
```
(The earlier loose form `Δθ = −η Δ_μ⁻¹(∇F)`, AG1, is a paraphrase of this.)

### §3.4 — Predictive-coding error
The free-energy / prediction-error `F(p(ξ))` is the §2 local PC objective `Σ_l ‖z^l − ẑ^l‖²`,
now minimized along the Wasserstein-natural-gradient direction rather than Euclidean.

### §3.6 — Crude pseudocode sketch (pp. 21–22)

The paper gives explicit (informal) pseudocode `ACTPC_WASSERSTEIN_UPDATE`:
```
function ACTPC_WASSERSTEIN_UPDATE(ξ, data):
    p        ← current_distribution(ξ)
    L_p      ← build_measure_dependent_laplacian(p, ω)   # L(p)_ij = ω_ij (p_i + p_j)
    L_p_inv  ← pseudo_inverse(L_p)                        # or neural / low-rank approx (§4)
    J_xi     ← jacobian(p, ξ)
    G_xi     ← J_xi^T · L_p_inv · J_xi                    # metric tensor (AG41)
    grad_F   ← gradient_of_PC_error(ξ, data)
    ξ        ← ξ − η · solve(G_xi, grad_F)                # natural-gradient step (AG42)
    return ξ
```

---

## §5 — Neural approximators for measure-dependent operators (paper §4, pp. 23–31)

> **Replaces the original spec's "WGAN" section.** The paper's approximator is a generic
> neural net trained on a reconstruction loss; it then surveys **four** compression methods
> for making `L(p)^†` cheap. The original spec collapsed all of this into one false "WGAN" line.

**Core idea (p. 23):** learn a net `f_θ` that maps cheap distribution features to a
compressed approximation of the inverse Laplacian, with reconstruction loss:
```
L^†_approx = ‖ L(p̃)^† − f_θ(features) ‖²                          (AG43, p. 23)
```

### §4.1 — Stochastic low-rank decomposition of the inverse (p. 24)
Random projection + Nyström/SVD to a rank `r ≪ n`; cost `O(r³)` instead of `O(n³)`.

### §4.2 — Compressed representations (pp. 25–30)
- **§4.2.1 Direct ℓ₂ projection** (p. 26): `z_k = W_proj · vec_k ∈ R^d`.
- **§4.2.2 Learned autoencoder for factor triples** (p. 26): encoder/decoder
  `Enc_φ / Dec_φ` with reconstruction loss `‖vêc_k − vec_k‖²`.
- **§4.2.3–4.2.4 Kernel methods / approximating kernel PCA** (pp. 26–30):
  - **Wasserstein-Gaussian kernel** (a central, previously-missing formula):
    ```
    κ(L̂_i, L̂_j) = exp( −α · W₂(L̂_i, L̂_j)² )                     (AG44, p. 27)
    ```
  - **Nyström approximation** (p. 28):
    ```
    K_approx = K_{R,S} · K_{S,S}^† · K_{S,R}                       (AG45, p. 28)
    ```
  - **Random Fourier features** (pp. 28–29, [RR07]):
    ```
    φ(x) = √(1/D) [cos(ω_1^⊤x + b_1); …; cos(ω_D^⊤x + b_D)]
    κ(x,y) ≈ φ(x)^⊤ φ(y)
    ```

### §4.3 — Predicting the embedding vector (p. 30)
True embedding `z_k = g(vec_k)`; predicted `ẑ_k = f_θ(f_k)`; low-frequency recalibration
minimizes `‖z_true − f_θ(f_t)‖²` over θ.

### §4.4 / online counterpart
The online/approximate ground metric (used again in §8.3) is the same Jacobian sandwich with
the approximated inverse:
```
Ĝ(ξ_t) = J_{ξ_t}^⊤ L̂^† J_{ξ_t}                                    (cf. AG41, AG22)
```

> **[NOT IN PDF — PRIMUS mapping]** The following two blocks were presented in the original
> spec as if extracted from §4; they are PRIMUS cross-references, not paper content. Retained
> here, clearly fenced.
>
> - **Connection to Fluid ECAN** — the Wasserstein gradient-flow framework is *proposed in
>   PRIMUS* as the math behind Fluid ECAN (Hyperon WP §5.3–5.4): the HJB equation as a
>   Wasserstein gradient flow of a value function; incompressible Navier-Stokes from
>   Otto-calculus attention-mass conservation; ActPC-Geom supplying the neural-Laplacian
>   computational method. **None of this is in the ActPC-Geom paper.**
> - **Kernel attention for Symbolic Heads** — `s_i = ⟨φ(z(q)), φ(z(e_i))⟩`,
>   `α_i = softmax(s_i)`, `c_mem = Σ α_i z(e_i)` maps kPCA scoring onto PRIMUS-WM-v2 App C
>   §C.3 Symbolic Heads. **PRIMUS construct, not in the paper.**

---

## §6 — Compositional hypervectors + Fuzzy FCA (overview; full detail in §9 below)

> The original spec placed an early summary here ("pages 30-35") that anticipated the
> detailed treatment in the paper's §6–§7. The detail lives in the spec's **§9** section
> (paper §6 hypervectors pp. 49–61, paper §7 fuzzy FCA pp. 61–66). This is a pointer only.

### Hypervector integration with kPCA

The paper proposes creating **compositional hypervector embeddings**
as complements to the kPCA vectors:
- kPCA captures statistical/geometric structure
- Hypervectors capture algebraic/compositional structure
- Together they form the "dual-channel" embedding from PRIMUS-WM-v2 App B

### Fuzzy Formal Concept Analysis (FCA)

The algebraic structure of hypervectors is configured using concepts
derived from a **fuzzy FCA lattice**:
- Mine concept lattice from data
- Use lattice structure to configure binding/unbinding operations
- Ensures hypervector algebra reflects actual semantic relationships

### Hopfield-net dynamics

Many ActPC layers can incorporate **Hopfield-net-type attractor dynamics**:
- Enables effective associative long-term memory
- Attractors correspond to stable pattern completions
- Content-addressable retrieval via energy minimization

---

## §7 — Early axiom subset (AG1–AG8) — superseded by the complete table in §12

> Retained for continuity; see §12 for the authoritative AG1–AG45 table (with NOT-IN-PDF flags).

| # | Axiom | Formula | Source |
|---|---|---|---|
| AG1 | Wasserstein natural gradient | `Δθ = -η × Δ_μ⁻¹(∇F)` (paraphrase of AG42) | §3 |
| AG2 | Neural Laplacian approximation | `f_θ(features) ≈ L(p)^†` via trained NN (loss AG43) — **not WGAN** | §4 |
| AG3 | Measure-dependent Laplacian (continuous) | `Δ_p φ = ∇·(p ∇φ)` (paper form; `Δf + ∇log ρ·∇f` is the expansion) | §2.2.2 |
| AG4 | Wasserstein gradient of KL | `grad_W KL(ρ‖π) = -Δ_ρ log(ρ/π)` | **[NOT IN PDF — PRIMUS/OT background]** |
| AG5 | Kernel PCA feature map | `k(a,b) = ⟨φ(z(a)), φ(z(b))⟩` | §4.2.3 |
| AG6 | Dual-channel algebra+geometry | `φ(z) = [φ_A(z_A) ‖ φ_G(z_G)]` | **[NOT IN PDF — PRIMUS HMH map; paper uses AG16]** |
| AG7 | Hopfield attractor dynamics | Energy minimization for pattern completion | §9 |
| AG8 | Fuzzy FCA lattice config | Concept lattice → hypervector algebra | §7 |

---

## §8 — Connection to PRIMUS (NOT extracted — PRIMUS mapping)

> These are PRIMUS cross-references, not claims about the paper's text.

- **Fluid ECAN**: PRIMUS proposes ActPC-Geom's Wasserstein gradient as the math behind WP
  §5.3-5.4 PDEs (not stated in the paper)
- **QuantiMORK Inside Mode**: wavelet tensors + local PC ≈ ActPC-Geom layers inside MORK
- **HMH dual-channel**: PRIMUS-WM-v2 App B algebra+geometry channels ≈ ActPC-Geom kPCA +
  hypervector (the paper's actual two-block form is AG16: `h_i = [scaledEmbed(u_i) | r_i]`)
- **Symbolic Heads**: kernel attention ≈ ActPC-Geom kernel PCA scoring

---

## §9 — KL vs. Wasserstein divergence in ActPC (paper §5, pp. 32–48)

> **Paper §5.1 framing (pp. 32–39), under-covered originally — added here:** optimal
> transport as a *least-action* principle for cognition. Key named concepts:
> the **JKO (Jordan–Kinderlehrer–Otto) scheme** (p. 33), the **Benamou–Brenier** dynamic
> formulation of W₂ (p. 33), Goertzel's "**Minimum Probability Transport Principle**" /
> "Optimal Transport Action" framing (p. 34), and a "hide-from-surprise" critique of the
> Friston free-energy principle (p. 35). §5.1.1 action / 5.1.2 perception / 5.1.3 logic /
> 5.1.4 neuroscience follow.

### §5.1.2–5.1.4: Conceptual advantages of Wasserstein

- **For perception**: Wasserstein handles partially-overlapping or multimodal
  distributions smoothly; fosters compositional extension of categories
  rather than rejection of novelty
- **For logical cognition**: Wasserstein measures how "far" distributions must
  "move" in logical/feature space (vs. KL measuring surprise). Supports
  compositional extension of concepts, domain-specific metrics (edit distance
  for symbolic transformations)
- **For neuroscience**: Brain's transitions between activity states = "transporting
  mass" across neural assemblies. Metabolic/organizational costs ≈ Wasserstein
  transport costs. Proactive reconfiguration vs. reactive surprise minimization

### §5.2: Wasserstein-based cost function

Standard ActPC uses KL:
```
D_KL(q(x), p(x | θ))
```

ActPC-Geom replaces this with Wasserstein:
```
F_Wass(θ) = W_2(q(x), p(x | θ))                                   (AG9)
```
Where W_2(·,·) is the Wasserstein distance. The agent minimizes earth
mover's distance between predicted and actual distributions.

**Advantages**: aligns external mismatch measure (reward cost) with internal
local geometry (transport cost); more stable when supports don't overlap;
more consistent local gradient directions.

**Cost**: Computing W_2 requires O(n³) naive LP or O(n² log n) Sinkhorn,
vs. O(n) for KL.

### §5.3: Closer connection between external cost & internal geometry

If external cost = W_2(predicted, actual) and internal transport uses
the same ground metric ω, then "outer loop" and "inner loop" describe
the same transport geometry in distribution space — smoother, more
direct convergence.

### §5.4: Transfer of continuity and scale properties

**Proposition (Wasserstein Lipschitz ActPC Property)**:
```
|W_2(q, p(r | θ_1)) - W_2(q, p(r | θ_2))| ≤ L ‖θ_1 - θ_2‖       (AG10)
```
for a constant L > 0 and all θ_1, θ_2 ∈ Θ.

Yields two properties:
1. **Local Continuity**: Δ_env(θ) changes at most L‖θ_1 - θ_2‖ over small moves
2. **Scale Matching**: Environment distribution changes at scale δ in ω-distance
   → agent's internal geometry reflects comparable transport costs at that scale

#### §5.4.1: Rigorous scale matching setup

Let:
1. R = space of reward outcomes with ground metric ω: R×R → R_≥0
2. q(r) = environment's true reward distribution
3. p(r|θ) = agent's parametric family, θ ∈ Θ ⊂ R^m
4. W_2(q, p(r|θ)) = Wasserstein distance
5. L̂(p) = internal measure-dependent operator from ω

Scale matching condition:
```
W_2(p(r|θ), p(r|θ+δθ)) = δ                                        (AG11)
```
Where δθ is small enough for linearization. External scale δ in ω-space
is mirrored by internal scale δ in the agent's measure-dependent geometry.

#### §5.4.2: Weakening the Lipschitz condition

**Local Lipschitz** (for θ_1, θ_2 near θ_0):
```
|W_2(q, p(r|θ_1)) - W_2(q, p(r|θ_2))| ≤ L(θ_0) ‖θ_1 - θ_2‖
```

**Hölder continuity** (α-Hölder, 0 < α ≤ 1):
```
|W_2(q, p(r|θ_1)) - W_2(q, p(r|θ_2))| ≤ C ‖θ_1 - θ_2‖^α
```
Sub-linear scale matching when α < 1 — updates remain stable but
direct linear ratio is lost.

#### §5.4.3: Probabilistic Lipschitz

**Partial Lipschitz assumption**: Lipschitz holds for θ_1, θ_2 ∈ Θ' ⊂ Θ
covering ≥ 98% of Θ's measure. Outside Θ', no uniform bound.

Result: Wasserstein Lipschitz ActPC Property holds "almost everywhere"
(probability ≥ 0.98) in parameter space.

### §5.5: Transfer of convex-like properties (Wasserstein Quasi-Convex ActPC Property)

**Global objective**:
```
min_{θ ∈ Θ} W_2(q, p(r | θ))                                      (AG12)
```

If Δ_env(θ) = W_2(q, p(r|θ)) is unimodal or "convex-like" over θ:
1. No local minima → iterative transport-based gradient has no spurious
   local minima for small steps (provided local distribution changes
   reflect the same metric ω)
2. Under unimodality/smoothness, local updates in the agent's
   measure-dependent operator approximate geodesics in distribution space →
   "convex-like" or quasi-convex convergence

### §5.6: Practical challenges of scalable Wasserstein computation

Complexity comparison:
- **KL Divergence**: O(n) for discrete distributions of size n
- **Wasserstein (W_2)**: O(n³) naive LP, or O(n² log n) entropic Sinkhorn

Mitigation strategies:
1. **Incremental Updating**: Reuse partial solutions across small Δθ
2. **Attentional Focusing**: Only compute W_2 on the "hot" region
   relevant to current attention; stale regions updated less aggressively
3. **Neural approximators**: Same kPCA + neural Laplacian from inner loop
   applies to outer loop

---

## §10 — PART II: Cognitive Enhancements (paper §§6–11, pp. 49–109)

### §6: Compositional Hypervector Embedding (pages 49-61)

#### §6.1: Basic concepts of hypervector embedding

Entities represented as high-dimensional vectors (D ~ thousands) over
{±1} or reals. Three core operations:

**Binding** (componentwise multiplication or XOR):
```
c = a ⊙ b,    c_i = a_i × b_i                                     (AG13)
```
Preserves near-orthogonality for distinct pairs. Invertible: c ⊙ a → b.
Semantic: "(A, X) is one composite item" / "role = property, filler = value"

**Bundling** (componentwise addition + majority vote):
```
z_i = sign(x_i + y_i)                                              (AG14)
```
Or simply z = x + y (unthresholded). Result is "superposition" of inputs.
Partial overlap discoverable by dot product.

**Permutation** (index shift/shuffle):
```
π(x)_i = x_{σ(i)}                                                  (AG15)
```
For circular shift: σ(i) = i - 1 mod D. Invertible via σ⁻¹.
Represents positional or structural change.

#### §6.2: Snaider's Modular Composite Representation (MCR)

Combines binding, bundling, permutation for modular compositional structure:
1. Bind each property's base vector with its value: v_{Color=Red} = v_color ⊙ v_red
2. Optionally bind with entity vector: v_{(Apple,Color=Red)} = v_apple ⊙ (v_color ⊙ v_red)
3. Bundle multiple property-value pairs:
```
v_appleComposite = sign(v_apple ⊙ (v_color ⊙ v_red) + v_apple ⊙ (v_shape ⊙ v_round) + v_apple ⊙ (v_edibility ⊙ v_edible))
```
4. Permutation for sequence: v_slot1 = π_1(v_appleComposite), v_slot2 = π_2(v_bananaComposite)

**Retrieval** via partial unbinding + dot product matching.

#### §6.3: Combining hypervector algebra with kernel-PCA-like metric

**Two-block "hybrid" embedding**:
```
h_i = [scaledEmbed(u_i) | r_i]                                     (AG16)
```
Where:
- scaledEmbed(u_i): kPCA sub-block (size ~k or ℓ ≥ k) preserving
  kernel PCA geometry
- r_i ∈ {±1}^{D-ℓ}: random-lift sub-block for MCR operations

**Core ontology concepts** get stable, predefined random signatures r_c
and kPCA embeddings u_c:
```
h_c = [scaledEmbed(u_c) | r_c]
```

**Vector expansion algorithm** (§6.3.4):
1. Given dimension k from kernel PCA, target hypervector dimension D
2. Partition D as (ℓ + R), ℓ ≥ k
3. Optional: orthonormal extension Q ∈ R^{k×ℓ}, u' = u·Q
4. Random signature: r ∈ {±1}^R
5. Final hypervector:
```
h(u) = [u'; r]                                                     (AG17)
```

MCR operations on hybrid vectors:
- **Binding**: on kPCA sub-block scrambles geometry (or skip to preserve);
  on random sub-block = standard MCR
- **Bundling**: across entire vector or only random sub-block
- **Permutation**: only on random sub-block, preserving kPCA geometry

### §7: Neural Architecture for Learning Fuzzy FCA Lattices (pages 61-66)

#### §7.1: Learning Fuzzy FCA Lattices

Fuzzy FCA concept lattice evaluated by how well a neural approximator
can predict system behavior using only concept memberships as input.
If prediction is accurate → discovered concepts are relevant to dynamics.

#### §7.3: Neural architecture

**State vectors**: {x_i} ⊆ R^k for i = 1,...,m (from kPCA of ActPC states)

**Core ontology**: C_core = {C_1,...,C_r} pre-defined concepts

**Architecture pipeline**:
```
x_i →[kPCA]→ FCL Learner F → [f_1(x_i),...,f_n(x_i)] → N → ŷ_i   (AG18)
```

**FCL Learner F**:
- Input: x ∈ R^k
- Output: f(x) ∈ [0,1]^n (fuzzy membership in each concept F_j)
- Per concept F_j: output neuron o_j through sigmoid/softplus
- Core ontology concepts: partially fixed neurons ensuring learned ∧ anchored

**Neural Approximator N**:
- Input: f(x) ∈ [0,1]^n
- Output: ŷ ∈ R^ℓ (predicted system outcomes)

**Co-training loss**:
```
L = Σ_i ‖ŷ_i - y_i‖² + regularization on f_i                     (AG19)
```
End-to-end training: ∇_{θ_F, θ_N} L

**Post-learning hypervector construction**:
```
h(x) = Bind(...Bind(v_{F_j}, f_j(x))...)                          (AG20)
```
Or two-block: Block A = kPCA embedding, Block B = Snaider composition
of (Concept_j ⊙ membership_j) bundled across j.

#### §7.4.1: Ensemble of approximators

Three neural approximators:
- N_0: based on approximate kPCA vectors (in-distribution accuracy)
- N_1: based on fuzzy FCA lattice concepts (out-of-distribution generalization)
- N_2: based on hybrid hypervectors combining kPCA + concepts

### §8: Toward ActPC-Geom Based Transformers (pages 67-84)

#### §8.1: Transformers under PC/ActPC

Each layer (sub-layer) predicts next layer's representation. Information
geometry provides:
- **Ground Metric**: cost of moving between attention configurations via ω
- **Measure-Dependent Operators**: Laplacian encodes how to "transport"
  attention distributions efficiently

Benefits: geometric update (smooth convergence), global coherence
(reduce contradictory/oscillatory updates across layers), potential to
overcome vanishing/exploding gradients.

#### §8.2: Synergy of instruction tuning with PC/ActPC

Under information-geometric approach:
1. Local Distribution: each sub-layer's representation = distribution over tokens/states
2. Reward: certain attention trajectories align better with instructions
3. Geometry-Aware Steps: minimize error + maximize reward via
   measure-dependent gradient flows

Advantages: stable convergence (less catastrophic forgetting), data
efficiency, iterative refinement.

#### §8.3: Online learning in ActPC-Geom transformers

**Step-by-step online learning procedure**:

1. **Initialize ActPC-Transformer**: multiple layers with local PC/ActPC
   update rules managing error signals + distribution representations
2. **Initialize Approximations**: neural net f_θ for inverse Laplacian;
   kPCA embedding matrix; hypervector embedding
3. **Real-Time Loop** (each new token):
   - Local error computation (predicted vs. actual hidden states)
   - Distribution feature extraction: f_t
   - Neural approximator:
```
L̂_t^† = decode(f_θ(f_t))                                         (AG21)
```
   - Local parameter update:
```
ξ_{t+1} = ξ_t - η Ĝ(ξ_t)^{-1} ∇_ξ F(ξ_t)                       (AG22)
where Ĝ(ξ_t) = J^T_{ξ_t} L̂_t^† J_{ξ_t}
```

#### §8.4: In-context learning + online weight updating synergy

**Two-timescale dynamic**:

Fast timescale — ephemeral activation-space inference:
```
z^ℓ ← z^ℓ - η_z [∇_{z^ℓ}(Local PC error)]                       (AG23)
```

Slow timescale — real-time local weight updates:
```
W^ℓ_{t+1} = W^ℓ_t - η_W [G(W^ℓ_t)]^{-1} ∇_{W^ℓ} E^ℓ            (AG24)
```
Where E^ℓ is local error energy at layer ℓ, and [G(W^ℓ_t)]^{-1} is derived
from kPCA + neural approximator modeling distribution geometry.

**Emergent properties**:
- Blending in-context learning with weight consolidation
- Less catastrophic interference (local + small updates)
- Continuous life-long learning
- Emergent "deliberative" cognition (iterative inference + weight modification)
- Potential for deliberative metacognition

#### §8.5: Online learning performance requirements

**Target ratio**: 2:1 to 10:1 ephemeral activation updates to parameter updates.

**Example workflow for 10:1 ratio**:
1. Ephemeral iterations: 10 refinement steps in activation space (~200-300 ms)
2. Local parameter update: identify top sub-layers with largest mismatch,
   run measure-dependent geometry, apply updates (~50 ms)
3. Continue to next token

**Strategies to achieve feasible ratio**:
- Localize to most-engaged nodes/links (sparse weight updates, ~1-5% of params)
- Error-driven focus (skip near-zero mismatch layers)
- Random or priority sampling of parameters
- "One-shot" or "few-shot" weight corrections after ephemeral convergence

### §9: Embedding Associative Long-Term Memory in ActPC Transformers (pages 84-89)

#### §9.1: Transformers vs. Hebbian/Hopfieldian learning

Standard transformers lack "retrieve old patterns from deep memory" —
they rely on context window. PC relates more closely to Hebbian learning:
activations reconfigure iteratively, weights adapt in near-real-time.

#### §9.2: Augmenting with lateral Hopfield-like layers

Core idea: add lateral (intra-layer) connections that let partial
activation patterns "pull each other in" — mini Hopfield attractor dynamic.

**Where to add**: within standard transformer blocks (after/alongside
Multi-Head Self-Attention, FeedForward, Residual connections, LayerNorm)

**Mechanism**: 
1. Layer sees input x
2. Lateral net ("Hopfield block") runs micro-iterations, refining x → x*
   (stable attractor = stored pattern)
3. Pattern completion = "retrieval" from layer's long-term memory

**Asymmetric Hopfield**: connection i→j can differ from j→i.
More biologically plausible, capable of broader knowledge representation,
but may lose guaranteed global minima. PC's error-correction can offset this.

### §10: Symbolic/Subsymbolic Transformers via ActPC-Geom + ActPC-Chem (pages 89-94)

#### §10.1: Neural-symbolic ActPC-GeomChem transformer architecture

Each layer ("block") comprises:
- **Discrete Transformer-like Block**: algorithmic chemistry of rewrite rules,
  learned via discrete ActPC + discrete measure-dependent Laplacian
- **Continuous Transformer-like Block**: standard multi-head attention +
  feedforward, updated via continuous ActPC + measure-dependent geometry +
  neural approximator + kernel-PCA embedding
- **Cross-Links**: shared probability model, activation bridge between
  discrete (symbolic representations) and continuous (hidden vectors)

**Combined distribution**:
```
P = P_discrete × P_continuous                                      (AG25)
```
Measure-dependent operator on joint space captures cost-of-transport
for both rewriting and continuous updates.

#### §10.4: Shared information geometry

**Hybrid ground metric** for unified partial order:
```
ω((d_1,c_1), (d_2,c_2)) = α d_discrete(d_1,d_2) + β d_continuous(c_1,c_2)   (AG26)
```
Where α, β are tunable weights. This yields a single Wasserstein
distance W_2(p_S, p_optimal) that treats discrete and continuous
expansions identically.

### §11: Compositional Hypervectors → System-Level Reasoning (pages 94-109)

Detailed thought experiment: "The home country of the sport associated
with Giorgio Chinaglia is...?" (Answer: UK, not Italy)

#### §11.5: Binding and bundling in practice

**Storing facts as hypervectors**:
```
v_{Chinaglia→soccer} = Bind(v_Chinaglia, Bind(v_AssociatedSport, v_Soccer))
v_{Soccer→UK} = Bind(v_Soccer, Bind(v_HomeCountry, v_UK))
```

**Question vector**:
```
v_Q = Bundle(v_Chinaglia, v_AssociatedSport, v_HomeCountry)
```

#### §11.6: Aggregator functionality

**Aggregator input/output**:
- Input: candidate expansions {v_{candidate,1}, ..., v_{candidate,k}} + context v_Q
- Scoring:
```
score_i = v_Q · v_{candidate,i}                                    (AG27)
dist_i = ‖v_Q - v_{candidate,i}‖                                  (AG28)
```
- Output: refined set of expansions that reduce overall predictive error

**Unbinding step** (to verify alignment):
```
v_{Chinaglia2Soccer2UK} ⊙ Bind(v^{-1}_Chinaglia, v^{-1}_AssociatedSport)
≈ Bind(v_HomeCountry, v_UK)                                        (AG29)
```
If remainder aligns with question's property slots → accept.

#### §11.7: Intelligent search of multiple partial unbindings

Aggregator performs heuristic/beam search in hypervector space:
1. Initial candidates scored by basic overlap with v_Q
2. Top candidates undergo partial unbinding with different property combinations
3. Residual vectors compared to question's property slots
4. Search frontier maintained; best-aligned routes kept
5. Converge when unbinding exactly matches needed property

---

## §11 — PART III: Pathways to Optimized Implementation (paper §§12–13, pp. 109–134)

### §12: Efficient Concurrent Hybrid ActPC via Galois Connections (pages 110-122)

#### §12.1: Extending deterministic DP theorem to uncertain case

**Dynamic Programming Theorem (DPT-Exact)** (Mu & Oliveira):
```
μ(λX → (in · FX · T°) ▷ S) ⊆ ([T]°) ▷ S                         (AG30)
```
Where:
- μ(λX → ...) = least fixed point of the fold/hylomorphism
- T° = converse of transition relation T
- ▷ S = "shrink" operator (Galois connection, enforces optimality)
- [T]° = fused/closed-form DP solution

**Extended theorem (approximate/stochastic)**:

Replace T with T̃ (stochastic/approximate transition), F with F̃:
```
f̃(X) := (in · F̃X · T̃°) ▷ S
μ(f̃) = μ(λX → (in · F̃X · T̃°) ▷ S)
```

Fused form: ([T̃]°) ▷ S

**Near-inclusion**:
```
μ(f̃) ⊆_ε ([T̃]°) ▷ S                                             (AG31)
```
Meaning:
1. **Probabilistic**: with probability ≥ 1-δ, solutions from μ(f̃) are
   contained in or ε-close to the GC solution
2. **Approximate**: if each local step is ε-close to original T, the
   final DP solution is O(ε)-close to the precise solution

#### §12.2: ActPC as approximate stochastic dynamic programming

In ActPC with RL:
- **State**: network's internal states + environment observations
- **Actions**: emergent from output/policy layers
- **Rewards**: estimated, driving local error minimization
- **Approximate updates**: small iterative updates combining local mismatch
  + global reward signals

Each step in an ActPC RL agent ≈ an approximate DP iteration.

#### §12.3: Leveraging Galois connections

**Easy adjoint (f)**: generating/enumerating candidate outcomes (sub-states,
sub-actions). In ActPC, these are local expansions or next hidden-state predictions.

**Hard adjoint (g)**: "shrinking" or optimizing candidates according to
partial order or cost function. In ActPC, this is the measure-based gradient
or local "policy improvement."

#### §12.6: ActPC in terms of recursion schemes

**Galois-connection-inspired ActPC core loop** (7 steps):

1. **Initialize**: parameter θ, optional focus-of-attention subset
2. **Observe/Predict**: receive state s_t ∈ S, form p(r|θ)
3. **Local Expand (Easy Part)**: fold/hylomorphism enumerates candidate
   sub-states. F̃(X) produces partial expansions (approximate/sampled)
4. **Local Shrink (Hard Part)**: shrink operator S — check which candidates
   yield better predicted reward or lower cost.
   θ ← θ + δθ that "selects" higher-utility sub-states
5. **Apply Parameter Update**: measure-dependent operator (Wasserstein
   gradient) modifies θ. θ_{t+1} = θ_t - η∇_θ...
6. **Act/Output**: pick action a_t, environment transitions to s_{t+1}
7. **Iterate**: over time, approximate expansions + local shrink converge
   (w.h.p.) to near-optimal behavior per extended DP theorem

#### §12.7: Why Galois-inspired implementation enables efficient concurrency

Decomposes global ActPC loop into smaller local steps:
1. Local expansions: each CPU thread proposes new candidates independently
2. Local shrinks: each thread applies order-based optimization on its subset
3. Monotonic w.r.t. partial order → concurrency straightforward if merges
   are partial-order-aware

Potential speedup: 2-10x (frequent merges) to 50-90x (infrequent,
local expansions/shrinks) on 100-core server.

#### §12.8: Unified partial order across discrete + continuous

**Wasserstein-based partial order**:
```
S_1 ≤ S_2 ⟺ W(p_{S_1}, p_optimal) ≤ W(p_{S_2}, p_optimal)       (AG32)
```

Each sub-state S (discrete or continuous) mapped to probability
distribution p_S. "Better" = closer to p_optimal in Wasserstein distance.

**Hybrid ground metric**:
```
ω((d_1,c_1), (d_2,c_2)) = α d_discrete(d_1,d_2) + β d_continuous(c_1,c_2)   (= AG26)
```
Unifies discrete rewriting expansions and continuous expansions in a
single aggregator/shrink operator.

### §13: Specialized HPC Architecture for ActPC-Geom (pages 124-134)

#### §13.1: HPC infrastructure requirements

Pipeline must efficiently run:
- Continuous ActPC (neural net predictive coding)
- Discrete ActPC-Chem (algorithmic rewriting)
- Wasserstein/info-geometry error minimization
- Approximate kPCA + hypervector embeddings
- Sophisticated hypervector manipulations (heuristic search for partial unbindings)
- Fuzzy FCA concept-lattice auto-learning

#### §13.2: Architecture modules

1. **Fuzzy Feature Learning Module (F)**: neural net mapping states S → f(S) ∈ R^N
   (fuzzy membership vector in [0,1]^N). Co-trained with utility net.

2. **Hypervector Embedding & Compositional Algebra (H)**:
```
v(S) = Bundling(..., Bind(v_{Feature j}, MemVal(S,j)), ...)        (AG33)
```
   Adaptive: if F changes, H needs incremental re-embedding.

3. **Neural Utility/Prediction Module (U)**: takes v(S) or dimension-reduced
   version, outputs ŷ(S) ∈ R^m. Mismatch measured via Wasserstein.

4. **Discrete Rewriting Subsystem (ActPC-Chem)**: proposes expansions
   {v_{c_1},...} in hypervector form.

5. **Continuous Subsystem (ActPC)**: neural net layers producing expansions
   in hypervector form.

6. **Aggregator / Galois Concurrency Manager (A)**: merges expansions from
   discrete + continuous sides, references hypervector measure-based geometry,
   picks minimal Wasserstein-based error expansions.

#### §13.3: HPC execution outline

```
1. State S arrives
2. F maps S ↦ f(S)
3. H binds fuzzy features → v(S)
4. U sees v(S), outputs ŷ(S)
5. Measure mismatch Loss(ŷ(S), y(S)) [Wasserstein]
6. Discrete/Continuous expansions produce {S'} → v(S'). Aggregator merges.
7. Partial/full HPC-based updates to F, H, U (and rewrite rules)
```

#### §13.4: Multilayer concurrency model

- **Cluster level**: N HPC nodes, each with 2-4 CPU sockets + 4-8 GPUs,
  InfiniBand interconnect, distributed storage
- **Node level**: CPUs handle discrete rewriting + aggregator concurrency;
  GPUs handle continuous ActPC + fuzzy-FCA training + large hypervector ops
- **Sub-node**: rewriting threads → fuzzy feature net → hypervector module →
  candidate v_candidate. Aggregator threads merge by ℓ_2 distance or
  partial unbinding, prune suboptimal expansions

#### §13.6: Further directions

- **Custom hardware**: specialized on-chip components for discrete rewriting,
  fuzzy concept learning, hypervector ops, aggregator concurrency
- **Decentralized deployment**: splaying modules across SingularityNET/NuNet/MettaCycle
  networks; rho calculus + MeTTa smart contracts for concurrency management

---

## §12 — Appendices A–E: Proof Sketches (pp. 136–149)

### Appendix A: Proof sketches for local continuity & scale matching

#### A.1: Local continuity proof

By Lipschitz assumption: |W_2(q,p(r|θ_1)) - W_2(q,p(r|θ_2))| ≤ L‖θ_1 - θ_2‖.
Let Δ_env(θ) = W_2(q,p(r|θ)). Then Δ_env is L-Lipschitz → local continuity
follows immediately.

#### A.2: Scale matching proof (4 steps)

1. **Local Lipschitz ⟹ bounded external cost changes**: ‖δθ‖ produces
   at most L‖δθ‖ change in Δ_env
2. **Distribution shift vs. parameter shift**: define δ := W_2(p(r|θ), p(r|θ+δθ)).
   Since internal operator uses same ω, a δ-sized distribution shift has
   transport cost ≈ δ
3. **Environmental scale vs. internal scale**: environment distribution changes
   at scale δ → Δ_env sees difference ≤ L‖δθ‖. Agent's internal geometry
   also "pays" cost δ for that shift
4. **Conclusion**: environment's notion of distance δ is matched by agent's
   local measure of distribution shift — both rely on same ω

### Appendix B: Probabilistic Lipschitz formalization

Setup: Θ_good ⊂ Θ with μ(Θ_good) ≥ 0.98μ(Θ).
For θ_1, θ_2 ∈ Θ_good: |Δ_env(θ_1) - Δ_env(θ_2)| ≤ L‖θ_1 - θ_2‖.

**Lemma (Intuitive Sketch)**: Let Θ_good ⊂ Θ be open, measure ≥ 0.98μ(Θ).
If each local step ‖θ_{t+1} - θ_t‖ is small enough that you rarely "jump"
from Θ_good across a boundary, then with high probability θ_{t+1} stays in
Θ_good. Over T steps:
```
P(remain in Θ_good for T steps) ≥ (0.98)^T
```

### Appendix C: Wasserstein Quasi-Convex ActPC Property proof sketch

#### C.1: Basic quasi-convexity

If Δ_env(θ) = W_2(q, p(r|θ)) has no bad local minima (unimodal/"Wasserstein-convex"
w.r.t. θ), and internal operator uses same ω, then:
- Local gradient flow follows near "straight-line" geodesics in distribution space
- No spurious local minima unless distribution mapping is badly folded
- Parameter path → arg min_θ W_2(q, p(r|θ))

#### C.2: Convexity with small bumps

If Δ_env is almost unimodal except for "small bumps" (subset Θ_bad of
measure ≤ δ%, amplitude ≤ ε):

**Formalized statement**: *Suppose Δ_env(θ) = W_2(q, p(r|θ)) has Θ_bad ⊂ Θ
of measure ≤ δ%·μ(Θ) where local deviations from geodesic convexity
do not exceed ε. Outside Θ_bad, Δ_env is geodesically convex. If the
internal measure-dependent operator matches the same ground metric ω,
then with probability ≥ (1 - δ%) per step, the system remains in the
unimodal region Θ_good, ensuring near "straight-line geodesics" and
reliable global/near-global convergence.*

### Appendix D: Approximate stochastic DP theorem proof sketch

Original theorem: (in · F(...) · T°) ▷ S ⊆ ([T]°) ▷ S

Replace F with F̃, T with T̃:
```
(in · F̃(...) · T̃°) ▷ S
```

**Key arguments**:
1. **Local monotonicity**: each random/approximate step deviates by at most ε
   in partial order → preserves main fixpoint argument
2. **Fusion**: fold/hylomorphism fusion still works (or works in expectation)
   → get ([T̃]°) as single-step operator

**Conclusion**:
```
μ(λX → (in · F̃X · T̃°) ▷ S) ⊆_ε ([T̃]°) ▷ S                    (AG34)
```
Where ⊆_ε = probability statement or approximate partial order.

**Handling stochasticity**: E‖T̃ - T‖ ≤ ε → with probability ≥ 1-δ,
μ(f̃) is within ε-distance of the standard GC-based DP solution μ(f).

### Appendix E: Monotonicity and bounding conditions for DP theorem

#### E.1: DP theorem context

```
μ(λX → (in · FX · T°) ▷ S) ⊆ ([T]°) ▷ S
```
Requires: fold portion monotone w.r.t. partial order; shrink operator
monotone; combination converges to least fixed point.

#### E.2: Monotonicity required in two places

**Fold/hylomorphism operator**:
```
f(X) = (in · FX · T°) ▷ S
FX_1 ⊆ FX_2 ⟹ f(X_1) ⊆ f(X_2)
```

**Shrink operator**:
```
R_1 ⊆ R_2 ⟹ R_1 ▷ S ⊆ R_2 ▷ S                                   (AG35)
```
Where R ▷ S = R ∩ (S/R°).

#### E.3: Bounding conditions

```
dom(T) ⊆ dom(F(([T]°) ▷ S))                                       (AG36)
```

#### E.4: Well-foundedness

```
in · FS ⊆ S · in                                                   (AG37)
```
No infinite descending chains. Ensures iterative fixpoint is well-defined.

#### E.5: Summary

When monotonicity (in expansions and shrink), bounding, and
well-foundedness hold:
1. Partial-order preservation (each local step doesn't break order)
2. Correctness (incremental fixpoint ⊆ direct/fused approach)
3. Convergence (guaranteed to find minimal/least fixed point solution)

These conditions are straightforward design constraints for practical
HPC or multi-threaded ActPC implementations.

---

## §13 — Complete axiom table (AG1–AG45)

| # | Axiom | Formula | Source |
|---|---|---|---|
| AG1 | Wasserstein natural gradient (paraphrase of AG42) | `Δθ = -η × Δ_μ⁻¹(∇F)` | §3 |
| AG2 | Neural approximator (**not WGAN**) | `f_θ(features) ≈ L(p)^†` via trained NN, loss AG43 | §4 |
| AG3 | Measure-dependent Laplacian (continuous) | `Δ_p φ = ∇·(p∇φ)` (`Δf+∇log ρ·∇f` is the expansion) | §2.2.2 |
| AG4 | Wasserstein gradient of KL | `grad_W KL(ρ‖π) = -Δ_ρ log(ρ/π)` | **NOT IN PDF — OT/PRIMUS bg** |
| AG5 | Kernel PCA feature map | `k(a,b) = ⟨φ(z(a)), φ(z(b))⟩` | §4.2.3 |
| AG6 | Dual-channel algebra+geometry | `φ(z) = [φ_A(z_A) ‖ φ_G(z_G)]` | **NOT IN PDF — PRIMUS; cf. AG16** |
| AG7 | Hopfield attractor dynamics | Energy minimization for pattern completion | §9 |
| AG8 | Fuzzy FCA lattice config | Concept lattice → hypervector algebra | §7 |
| AG9 | Wasserstein cost function | `F_Wass(θ) = W_2(q(x), p(x\|θ))` | §5.2 |
| AG10 | Wasserstein Lipschitz ActPC | `\|W_2(q,p(r\|θ_1)) - W_2(q,p(r\|θ_2))\| ≤ L‖θ_1-θ_2‖` | §5.4 |
| AG11 | Scale matching condition | `W_2(p(r\|θ), p(r\|θ+δθ)) = δ` | §5.4.1 |
| AG12 | Global Wasserstein objective | `min_{θ∈Θ} W_2(q, p(r\|θ))` | §5.5 |
| AG13 | Hypervector binding | `c = a ⊙ b, c_i = a_i × b_i` | §6.1 |
| AG14 | Hypervector bundling | `z_i = sign(x_i + y_i)` | §6.1 |
| AG15 | Hypervector permutation | `π(x)_i = x_{σ(i)}` | §6.1 |
| AG16 | Two-block hybrid embedding | `h_i = [scaledEmbed(u_i) \| r_i]` | §6.3.1 |
| AG17 | Vector expansion | `h(u) = [u'; r]` | §6.3.4 |
| AG18 | FCA architecture pipeline | `x_i → F → [f_j(x_i)] → N → ŷ_i` | §7.3 |
| AG19 | Co-training loss | `L = Σ_i ‖ŷ_i - y_i‖²` | §7.3 |
| AG20 | Post-learning hypervector | `h(x) = Bind(...Bind(v_{F_j}, f_j(x))...)` | §7.3.3 |
| AG21 | Online neural approximator | `L̂_t† = decode(f_θ(f_t))` | §8.3 |
| AG22 | Online parameter update | `ξ_{t+1} = ξ_t - η Ĝ(ξ_t)⁻¹ ∇_ξ F(ξ_t)` | §8.3 |
| AG23 | Activation-space PC update | `z^ℓ ← z^ℓ - η_z[∇_{z^ℓ}(PC error)]` | §8.4 |
| AG24 | Weight-space natural gradient | `W^ℓ_{t+1} = W^ℓ_t - η_W[G(W^ℓ_t)]⁻¹ ∇_{W^ℓ} E^ℓ` | §8.4 |
| AG25 | Combined distribution | `P = P_discrete × P_continuous` | §10.4 |
| AG26 | Hybrid ground metric | `ω((d_1,c_1),(d_2,c_2)) = αd_d(d_1,d_2) + βd_c(c_1,c_2)` | §12.8.1 (p.123) |
| AG27 | Aggregator dot-product score | `score_i = v_Q · v_{candidate,i}` | §11.6 |
| AG28 | Aggregator distance score | `dist_i = ‖v_Q - v_{candidate,i}‖` | §11.6 |
| AG29 | Partial unbinding verification | `v ⊙ Bind(v⁻¹_A, v⁻¹_B) ≈ Bind(v_prop, v_val)` | §11.6.3 |
| AG30 | DP Theorem (exact) | `μ(λX→(in·FX·T°)▷S) ⊆ ([T]°)▷S` | §12.1 |
| AG31 | DP Theorem (approximate) | `μ(f̃) ⊆_ε ([T̃]°) ▷ S` | §12.1 |
| AG32 | Wasserstein partial order | `S_1 ≤ S_2 ⟺ W(p_{S_1},p_opt) ≤ W(p_{S_2},p_opt)` | §12.8 |
| AG33 | HPC hypervector embedding | `v(S) = Bundling(...,Bind(v_{Fj},MemVal(S,j)),...)` | §13.2 |
| AG34 | Stochastic DP conclusion | `μ(λX→(in·F̃X·T̃°)▷S) ⊆_ε ([T̃]°)▷S` | App D |
| AG35 | Shrink monotonicity | `R_1 ⊆ R_2 ⟹ R_1 ▷ S ⊆ R_2 ▷ S` | App E |
| AG36 | Bounding condition | `dom(T) ⊆ dom(F(([T]°)▷S))` | App E |
| AG37 | In-constructor feasibility | `in · FS ⊆ S · in` | App E |
| AG38 | ActPC local error + weight-gradient | `e^l = z^l − g^l(z^{l+1},W^l)`; `∂‖e^l‖²/∂W^l = 2e^l ∂z^l/∂W^l − 2e^l ∂g^l/∂W^l` | §2.1.2 (p.14) |
| AG39 | Otto tangent metric | `⟨φ,ψ⟩_p = ∫ p ∇φ·∇ψ dx`, `δp = −∇·(p∇φ)` | §2.2.1 (p.16) |
| AG40 | Discrete graph Laplacian (used form) | `L(p)_{ij} = ω_{ij}(p_i+p_j), i≠j` [LM18] | §2.2.2 (pp.17/19) |
| AG41 | Metric tensor | `G(ξ) = J_ξ^⊤ L(p(ξ))^† J_ξ` | §3.2.2 (p.20) |
| AG42 | Wasserstein natural-gradient update | `dξ/dt = −G(ξ)^{-1}∇_ξ F`; `ξ_{k+1}=ξ_k − ηG(ξ_k)^{-1}∇_ξ F` | §3.3 (p.20) |
| AG43 | Approximator reconstruction loss | `L^†_approx = ‖L(p̃)^† − f_θ(features)‖²` | §4 (p.23) |
| AG44 | Wasserstein-Gaussian kernel | `κ(L̂_i,L̂_j) = exp(−α W₂(L̂_i,L̂_j)²)` | §4.2.3 (p.27) |
| AG45 | Nyström approximation | `K_approx = K_{R,S} K_{S,S}^† K_{S,R}` | §4.2.4 (p.28) |

---

## §14 — Connection to PRIMUS (updated)

- **Fluid ECAN**: ActPC-Geom's Wasserstein gradient IS the math behind §5.3-5.4 PDEs
- **QuantiMORK Inside Mode**: wavelet tensors + local PC = ActPC-Geom layers inside MORK
- **HMH dual-channel**: App B's algebra+geometry channels = ActPC-Geom's kPCA + hypervector (AG16-AG17)
- **Symbolic Heads**: kernel attention = ActPC-Geom's kernel PCA scoring (AG5)
- **ECAN attention allocation**: §8.5's localized weight updates + priority sampling = OpenCog ECAN stochastic importance sampling [GBIY16]
- **Galois connections**: §12's GC-based concurrency applies directly to Hyperon's MeTTa interpreter (rho calculus [MR05] + metta calculus [Mer25])
- **Fuzzy FCA**: §7's neural architecture for learning concept lattices maps to PRIMUS ontological categories + categorization infrastructure
- **Two-timescale dynamics (AG23-AG24)**: fast activation inference + slow weight consolidation = basis for PRIMUS cognitive kernel architecture

---

## §15 — References cited in paper

- [Ama16] Amari. *Information geometry and its applications*. Springer, 2016.
- [Ami90] Amit. *Attractor neural networks and biological reality*. FGCS 6(2), 1990.
- [Fri09] Friston. *The free-energy principle*. Trends in Cognitive Sciences 13(7), 2009.
- [GBD+23] Goertzel et al. *OpenCog Hyperon: A framework for AGI*. 2023.
- [GBIY16] Goertzel et al. *Controlling combinatorial explosion via synergy with attention allocation*. AGI 2016.
- [Goe21] Goertzel. *Patterns of cognition: cognitive algorithms as Galois connections*. arXiv:2102.10581, 2021.
- [Goe24a] Goertzel. *ActPC-Chem*. arXiv:2412.16547, 2024.
- [Goe24b] Goertzel. *Introducing Hyperseed-1*. 2024.
- [LM18] Li & Montúfar. *Natural gradient via optimal transport*. Information Geometry 1, 2018.
- [Mer25] Meredith. *Metta calculus*. GitHub, 2025.
- [MO12] Mu & Oliveira. *Programming from Galois connections*. JLAP 81(6), 2012.
- [MR05] Meredith & Radestock. *A reflective higher-order calculus*. ENTCS 141(5), 2005.
- [OK22] Ororbia & Kifer. *The neural coding framework*. Nature Communications 13(1), 2022.
- [RR07] Rahimi & Recht. *Random features for large-scale kernel machines*. NeurIPS 2007.
- [RSL+20] Ramsauer et al. *Hopfield networks is all you need*. arXiv:2008.02217, 2020.
- [Sam22] Samal. *LearnFCA*. 2022.
- [SF14a] Snaider & Franklin. *Modular composite representation*. Cognitive Computation 6, 2014.
- [SF14b] Snaider & Franklin. *Vector LIDA*. Procedia Computer Science 41, 2014.

---

## PDF FULLY READ (149/149 pages) — original 2026-04-13, re-audited 2026-06-08.
## 45 axioms (AG1–AG45). AG4 and AG6 are flagged NOT-IN-PDF (PRIMUS/OT background).
## Sections labeled with the paper's real §/page numbering. "WGAN" misattribution and
## fabricated "humanoid robotics / social interaction" applications removed. Paper §3
## (metric tensor, natural-gradient ODE, pseudocode) and §4 (compression taxonomy:
## Wasserstein-Gaussian kernel, Nyström, random Fourier features, autoencoder) added.

---

## IMPLEMENTATION RESULT — AG40–42 BUILT (2026-06-09)

Prototype: `../../experiments/actpc_geom_ac8/actpc_geom_ag40_42.jl` (; pure `LinearAlgebra`, no deps). First
implementation of the Wasserstein natural gradient — UNBUILT everywhere before this.

- **AG40** `meas_laplacian(p,ω)`: L = D − W, W_ij = ω_ij(p_i+p_j). PSD, null space = 1ᵀ.
- **AG41** metric tensor `G(ξ) = Jᵀ L(p)† J`. Validated in the canonical instantiation
  ξ = p (J = I) ⇒ G = L†, so AG42 becomes `p ← p − η·L(p)·∇_p F`: the measure-weighted
  graph Laplacian applied to the gradient IS the discrete optimal-transport flux,
  `(L∇F)_i = Σ_j ω_ij(p_i+p_j)(∇F_i − ∇F_j)`, routing mass along the ground-metric graph.
- **AG42** natural-gradient update, validated.

**GATE (the defining Wasserstein property): PASSED.**
- *GEO-1 (correctness):* L PSD throughout; the update converges (F → ~0) on a
  mass-relocation task (move probability from one support point to a far one).
- *GEO-2 (transport vs teleport):* the Wasserstein update **transports** mass through
  intermediate support points (optimal-transport flow), whereas the Euclidean gradient
  **teleports** it. Peak mass in the central region: Wasserstein {line K=5,9,13: 0.53,
  0.28, 0.06; 2D-grid 4×4: 0.32} vs Euclidean **exactly 0.000** in every config. The
  qualitative distinction (transport ≫ teleport) holds across line graphs, sizes, and a
  2D grid. This is precisely the property that makes Wasserstein geometry valuable over
  KL/Euclidean — it respects the ground metric.

**Numerical note:** `G = JᵀL†J` is doubly-singular (J and L both rank K−1, softmax gauge
+ Laplacian constant null space) → the raw natural-gradient solve blows up; a damped solve
`(G+λI)\∇F` (or the p-space J=I form) is required.

**Honest scope / next:** this builds + validates the CORE AG40–42 in the clean ξ=p
instantiation. NOT yet done: (1) the general parameterized form (J ≠ I, e.g. neural
params → distribution) integrated into FabricPC's training loop as a `scale_by_wasserstein`
transform alongside the Fisher-diagonal baseline; (2) the scalable approximators AG43–45
(neural/kPCA/Nyström/RFF for cheap L† at large support) — exact `pinv` suffices at small
support but large-scale needs them. With this, the ActPC stack's geometry leg exists
(neural ✓ FabricPC, symbolic ✓ ActPC-Chem, bridge ✓ AC8, geometry ✓ AG40–42).

### Learning-preconditioner integration — INCONCLUSIVE (honest negative, 2026-06-09)

Prototype: `../../experiments/actpc_geom_ac8/actpc_geom_wnat_learn.jl`. Tested the general J≠I form as a LEARNING
preconditioner: a structured categorical model (logits = W·[x,1], softmax over K ordinal
bins, ground metric ω = bin adjacency) fit to smooth Gaussian-bump targets, with the
output-distribution gradient preconditioned by G⁻¹ = (JᵀL†J)⁻¹ (J = softmax Jacobian).
Compared Euclidean vs Fisher-diagonal vs Wasserstein.

**Result: the Wasserstein preconditioner did NOT beat the baselines** — Fisher-diagonal
won (F_final 0.011 vs Euclidean 0.059 vs Wasserstein 0.066; center-err 0.48 vs 0.99 vs
0.96). The transport advantage that is crisp for distribution RELOCATION (GEO-2) did not
transfer to a general structured-output LEARNING advantage on this task.

**Honest reading (NOT tuned to a win):** likely because (a) the L² objective is already
bin-aware, (b) Fisher is a strong adaptive baseline, (c) a step-size confound (all modes
shared η despite different preconditioned-gradient scales). A clean Wasserstein learning
win would need a genuinely transport-dominated regime (large mass shifts where the support
geometry dominates the optimization) + fair per-optimizer step-size tuning — NOT
demonstrated here. So the validated ActPC-Geom claim is the **core transport mechanism
(AG40–42, GEO-1/GEO-2)**; the *learning* advantage over good adaptive preconditioners is
an open question, deliberately not overclaimed.
