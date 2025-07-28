# Mathematical Reference for SMLMMetrics.jl

## Package Overview

SMLMMetrics.jl is a Julia package for quantitative evaluation of Single Molecule Localization Microscopy (SMLM) algorithms, inspired by the methodology established in Chenouard et al.'s "Objective comparison of particle tracking methods" (Nature Methods, 2014). The package provides standardized metrics for comparing localization datasets in super-resolution microscopy applications including STORM, PALM, and PAINT techniques.

## Scientific Domain and Context

### Single Molecule Localization Microscopy (SMLM)

SMLM techniques achieve super-resolution by precisely localizing individual fluorescent molecules that are temporally separated through stochastic activation and bleaching. The fundamental principle relies on the ability to determine the center position of a point spread function (PSF) with precision much better than the diffraction limit.

The localization precision σ for a single molecule is given by:

$$\sigma = \sqrt{\frac{s^2}{N} + \frac{a^2}{12N} + \frac{8\pi s^4 b^2}{a^2 N^2}}$$

where:
- $s$ is the standard deviation of the PSF
- $N$ is the number of collected photons
- $a$ is the pixel size
- $b$ is the background noise per pixel

### Connection to Particle Tracking Evaluation

Following the framework established by Chenouard et al., this package addresses the need for objective, quantitative comparison of localization algorithms. While Chenouard focused on particle tracking over time, SMLMMetrics.jl evaluates the spatial accuracy and completeness of localization detection, which is fundamentally similar to the spatial component of particle tracking evaluation.

## Mathematical Foundations

### Coordinate System and Conventions

All coordinates are represented as $d \times n$ matrices where:
- $d$ is the number of spatial dimensions (2 for 2D, 3 for 3D)
- $n$ is the number of localizations
- Coordinates follow the convention: $\mathbf{A} = [\mathbf{a}_1, \mathbf{a}_2, \ldots, \mathbf{a}_n]$

For 2D data: $\mathbf{a}_i = [x_i, y_i]^T$
For 3D data: $\mathbf{a}_i = [x_i, y_i, z_i]^T$

### Units and Physical Constants

- All spatial coordinates are in nanometers (nm)
- Default dimensional weighting parameters α are in units of nm⁻¹
- Lateral dimensions (x, y): $\alpha_{lateral} = 1 \times 10^{-2}$ nm⁻¹
- Axial dimension (z): $\alpha_{axial} = 0.5 \times 10^{-2}$ nm⁻¹

These values reflect the typical precision differences between lateral and axial localization in 3D SMLM.

## Chenouard et al. Five-Metric Framework

The Chenouard particle tracking comparison established five key metrics for objective evaluation of tracking algorithms. The current SMLMMetrics.jl package implements spatial components of this framework, while the full temporal tracking metrics would require extension.

### 1. Jaccard Similarity Coefficient (JSC)

The JSC measures the overlap between detected and true particle tracks in space and time. For temporal tracking, this extends beyond spatial overlap to include trajectory correspondence.

#### Spatial Implementation (Current SMLMMetrics.jl)

For spatial localization comparison, the Jaccard Index is implemented as:

$$J(\mathbf{A}, \mathbf{B}) = \frac{|\mathbf{A} \cap \mathbf{B}|}{|\mathbf{A} \cup \mathbf{B}|} = \frac{N_{match}}{|\mathbf{A}| + |\mathbf{B}| - N_{match}}$$

where matching uses the Hungarian algorithm with cost matrix:

$$C_{i,j} = \begin{cases}
\sqrt{\sum_{k=1}^{d} (A_{k,i} - B_{k,j})^2} & \text{if } |A_{k,i} - B_{k,j}| < d_k \text{ for all } k \\
\infty & \text{otherwise}
\end{cases}$$

#### Temporal Extension (Chenouard Framework)

For full particle tracking, JSC would be computed over trajectories:

$$JSC = \frac{|T_{true} \cap T_{detected}|}{|T_{true} \cup T_{detected}|}$$

where $T_{true}$ and $T_{detected}$ are sets of true and detected trajectories, and trajectory intersection requires both spatial and temporal correspondence.

**Properties**: Range [0, 1], with 1 indicating perfect overlap and tracking accuracy.

**Computational Complexity**: O(n³) for spatial matching; O(n³m²) for full trajectory matching where m is the number of time points.

### 2. Root Mean Square Error (RMSE)

RMSE computes positional error between estimated and ground truth particle positions, averaged over all matched trajectories.

#### Spatial Implementation (Current SMLMMetrics.jl)

$$\text{RMSE}_{\alpha} = \sqrt{\frac{1}{d} \sum_{k=1}^{d} \alpha_k^2 \left(\frac{1}{N} \sum_{i=1}^{N} (A_{k,i} - B_{k,\text{assignment}[i]})^2\right)}$$

#### Temporal Extension (Chenouard Framework)

For particle tracking, RMSE is computed over all matched trajectory points:

$$\text{RMSE} = \sqrt{\frac{1}{N_{total}} \sum_{i=1}^{N_{tracks}} \sum_{t=1}^{T_i} \|\mathbf{p}_{i,t}^{true} - \mathbf{p}_{i,t}^{detected}\|^2}$$

where $N_{total}$ is the total number of matched position pairs across all trajectories.

**Properties**: Lower RMSE indicates higher precision in localization.

**Computational Complexity**: O(n) for matched pairs.

### 3. Track Fragmentation (FRG)

FRG counts how often a true track is split into multiple fragments by the tracking algorithm.

#### Mathematical Definition

$$FRG = \frac{1}{N_{true}} \sum_{i=1}^{N_{true}} \max(0, F_i - 1)$$

where $F_i$ is the number of detected track fragments corresponding to true track $i$.

#### Implementation Requirements

- Track correspondence mapping between true and detected trajectories
- Fragment identification based on temporal gaps or identity switches
- Minimum track length thresholds

**Properties**: Lower fragmentation indicates more continuous and accurate tracking.

**Extension for SMLMMetrics.jl**: Would require temporal trajectory data structure and fragment detection algorithms.

### 4. Track Merging (MRG)

MRG measures how often two or more true tracks are merged into a single estimated track.

#### Mathematical Definition

$$MRG = \frac{1}{N_{detected}} \sum_{j=1}^{N_{detected}} \max(0, M_j - 1)$$

where $M_j$ is the number of true tracks that correspond to detected track $j$.

#### Implementation Requirements

- Bidirectional track correspondence analysis
- Temporal overlap detection
- Identity consistency verification

**Properties**: Lower merging is desirable for accurate individual particle tracking.

**Extension for SMLMMetrics.jl**: Would require track identity management and temporal correspondence analysis.

### 5. Track Identity Switches (SWC)

SWC measures instances where the identity of tracked particles switches mid-trajectory.

#### Mathematical Definition

$$SWC = \sum_{j=1}^{N_{detected}} S_j$$

where $S_j$ is the number of identity switches in detected track $j$.

#### Implementation Algorithm

For each detected track:
1. Determine correspondence to true tracks at each time point
2. Count transitions where the corresponding true track ID changes
3. Exclude switches due to track termination/initiation

**Properties**: Fewer switches indicate more reliable tracking consistency.

**Extension for SMLMMetrics.jl**: Would require temporal sequence analysis and identity tracking.

## Current SMLMMetrics.jl Implementation

### Relationship to Chenouard Framework

The current package implements the **spatial components** of the Chenouard framework:

1. **JSC (Spatial)**: Implemented as Jaccard Index for localization overlap
2. **RMSE (Spatial)**: Implemented with dimensional weighting
3. **Efficiency Metric**: Combined JSC and RMSE measure (package-specific extension)

### Missing Temporal Components

The current implementation lacks:
- Track fragmentation analysis (FRG)
- Track merging detection (MRG)  
- Identity switch counting (SWC)
- Temporal trajectory data structures
- Track correspondence algorithms

### Point Matching Algorithm Foundation

The Hungarian algorithm-based matching serves as the foundation:

$$\pi^* = \arg\min_{\pi} \sum_{i=1}^{|\mathbf{A}|} C_{i,\pi(i)}$$

**Implementation Details**:
- Large penalty value (1×10⁶) for invalid pairings
- Post-processing to remove infinite-cost assignments
- Supports 2D and 3D spatial matching

### Efficiency Metric Extension

The package introduces a combined efficiency measure:

$$E = 1 - \sqrt{(1 - JSC)^2 + \alpha^2 \cdot \text{RMSE}^2}$$

This provides a single performance metric balancing detection completeness and localization precision.

## Physical Models and Assumptions

### Point Spread Function Model

The package assumes that localizations represent the centers of point spread functions (PSFs). For 2D Gaussian PSFs:

$$\text{PSF}(x, y) = \frac{A}{2\pi\sigma_x\sigma_y} \exp\left(-\frac{(x-x_0)^2}{2\sigma_x^2} - \frac{(y-y_0)^2}{2\sigma_y^2}\right)$$

### Localization Uncertainty

Each localization has an associated uncertainty that depends on:
- Photon count
- Background noise
- PSF width
- Pixel size

The cutoff distances in the matching algorithm should reflect these uncertainties, typically set to 2-3 times the expected localization precision.

### Model Limitations

1. **Static Scene Assumption**: No temporal correlation between localizations
2. **Point Source Model**: Assumes all fluorophores are point sources
3. **Independent Localizations**: No modeling of clustering or molecular interactions
4. **Gaussian PSF**: Assumes ideal optical system without aberrations

## Data Analysis Methods

### Statistical Framework

The package employs frequentist statistical methods without explicit uncertainty propagation. Each metric provides a point estimate of performance.

### Handling Edge Cases

1. **Empty Sets**: Jaccard index is undefined; RMSE returns 0
2. **No Matches**: Jaccard index = 0; RMSE undefined
3. **Perfect Matches**: All metrics approach ideal values (JI = 1, RMSE = 0, E = 1)

### Validation Approach

Following Chenouard et al.'s methodology, validation should include:

1. **Synthetic Data**: Known ground truth with controlled noise levels
2. **Cross-Validation**: Multiple independent datasets
3. **Parameter Sensitivity**: Evaluation across different cutoff distances
4. **Comparative Analysis**: Multiple algorithms on identical datasets

## Integration with SMLMData.jl

The package seamlessly integrates with SMLMData.jl structures, supporting both 2D and 3D emitter types:

- `Emitter2D` and `Emitter2DFit` for 2D localizations
- `Emitter3D` and `Emitter3DFit` for 3D localizations

Coordinate extraction follows the convention:
```julia
# 2D coordinates
a_coords = [[emitter.x for emitter in a.emitters]'; [emitter.y for emitter in a.emitters]']

# 3D coordinates  
a_coords = [[emitter.x for emitter in a.emitters]'; [emitter.y for emitter in a.emitters]'; [emitter.z for emitter in a.emitters]']
```

## Benchmark Performance

### Algorithmic Complexity Summary

#### Current SMLMMetrics.jl Implementation

| Operation | Time Complexity | Space Complexity |
|-----------|----------------|------------------|
| Point Matching (Hungarian) | O(n³) | O(n²) |
| Jaccard Index (Spatial) | O(n³) | O(n²) |
| RMSE (Spatial) | O(n) | O(1) |
| Efficiency | O(n³) | O(n²) |

#### Full Chenouard Temporal Framework Extensions

| Metric | Time Complexity | Space Complexity | Implementation Status |
|--------|----------------|------------------|---------------------|
| JSC (Temporal) | O(n³m²) | O(nm) | Not implemented |
| RMSE (Temporal) | O(nm) | O(1) | Spatial only |
| Track Fragmentation (FRG) | O(nm log m) | O(nm) | Not implemented |
| Track Merging (MRG) | O(nm log m) | O(nm) | Not implemented |
| Identity Switches (SWC) | O(nm) | O(n) | Not implemented |

where n = number of particles, m = number of time points.

### Performance Recommendations

1. **Small Datasets** (n < 1000): All algorithms perform efficiently
2. **Medium Datasets** (1000 < n < 10000): Consider parallelization for multiple comparisons
3. **Large Datasets** (n > 10000): May require approximate matching algorithms

### Memory Considerations

The cost matrix requires O(n²) memory, which can become limiting for very large datasets. Consider chunking strategies for datasets with >50,000 localizations per comparison.

## Usage Examples and Test Cases

### Basic Usage

```julia
using SMLMMetrics

# Example 2D data
a = [1.0 2.0 3.0; 1.0 2.0 3.0]  # 2×3 matrix
b = [1.1 2.1 3.1; 1.1 2.1 3.1]  # 2×3 matrix
cutoff = [0.5, 0.5]  # 500 nm cutoff in each dimension

# Calculate metrics
ji = jaccard(a, b, cutoff)
assignment = match(a, b, cutoff)
rmse_val = rmse(a, b, [1e-2, 1e-2], assignment)
eff = efficiency(a, b, cutoff, [1e-2, 1e-2])
```

### Analytical Test Cases

1. **Perfect Match**: Identical datasets should yield JI = 1, RMSE = 0, E = 1
2. **No Overlap**: Disjoint datasets should yield JI = 0, E < 0
3. **Systematic Offset**: Constant offset should not affect JI but increase RMSE
4. **Scale Invariance**: Doubling all coordinates and cutoffs should preserve JI

## References

### Primary References

1. Chenouard, N. et al. Objective comparison of particle tracking methods. *Nature Methods* 11, 281–289 (2014).
2. Sage, D. et al. Quantitative evaluation of software packages for single-molecule localization microscopy. *Nature Methods* 12, 717–724 (2015).

### Methodological Background

1. Kuhn, H. W. The Hungarian method for the assignment problem. *Naval Research Logistics Quarterly* 2, 83–97 (1955).
2. Jaccard, P. The distribution of flora in the alpine zone. *New Phytologist* 11, 37–50 (1912).

### SMLM Technique References

1. Betzig, E. et al. Imaging intracellular fluorescent proteins at nanometer resolution. *Science* 313, 1642–1645 (2006).
2. Rust, M. J., Bates, M. & Zhuang, X. Sub-diffraction-limit imaging by stochastic optical reconstruction microscopy (STORM). *Nature Methods* 3, 793–795 (2006).
3. Hess, S. T., Girirajan, T. P. K. & Mason, M. D. Ultra-high resolution imaging by fluorescence photoactivation localization microscopy. *Biophysical Journal* 91, 4258–4272 (2006).

## Software Dependencies

- **Distances.jl**: Efficient distance calculations
- **Hungarian.jl**: Hungarian algorithm implementation
- **SMLMData.jl**: SMLM data structures and types
- **SparseArrays.jl**: Sparse matrix operations
- **Statistics.jl**: Statistical functions

This mathematical reference provides the theoretical foundation for understanding and applying the SMLMMetrics.jl package in the context of quantitative SMLM evaluation, following the rigorous comparative methodology established by Chenouard et al. for objective algorithm assessment.