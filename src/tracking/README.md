# Particle Tracking Performance Evaluation

This module implements particle tracking performance measures based on the methodology described in:

**Chenouard et al., "Objective comparison of particle tracking methods"**
*Nature Methods* 11, 281-289 (2014), Supplementary Note 3.

## Overview

The tracking module evaluates the performance of particle tracking algorithms by comparing estimated tracks against ground truth tracks using optimal track pairing via the Hungarian algorithm.

## Performance Measures

The module computes **8 primary performance measures**:

### Quality Measures
1. **α** (alpha): Overall quality measure (0-1, higher is better)
   - Evaluates the best possible pairing between ground truth and estimated tracks
   - Accounts for both association and localization errors
   - α = 1 - d(X,Y) / d(X,∅)

2. **β** (beta): Quality with spurious track penalty (0-1, higher is better)
   - Similar to α but penalizes spurious estimated tracks
   - β ≤ α (equality when no spurious tracks)
   - β = (d(X,∅) - d(X,Y)) / (d(X,∅) + d(Ȳ,∅))

### Association Accuracy
3. **JSC** (Jaccard Similarity Coefficient for positions): Position-level accuracy (0-1, higher is better)
   - JSC = TP / (TP + FN + FP)
   - Measures how well individual positions are matched

4. **JSC_θ** (Jaccard Similarity Coefficient for tracks): Track-level accuracy (0-1, higher is better)
   - JSC_θ = TP_θ / (TP_θ + FN_θ + FP_θ)
   - Measures how well complete tracks are matched

### Localization Accuracy
5. **RMSE** (Root Mean Square Error): Average localization error (μm, lower is better)
   - Computed only on true positive (matching) positions
   - Measures spatial accuracy of localizations

6. **RMSE_θ** (Track-averaged RMSE): Track-level localization error (μm, lower is better)
   - RMSE computed per track, then averaged
   - Less sensitive to track length variations

7. **min_error**: Minimum localization error (μm)
   - Best-case spatial accuracy achieved

8. **max_error**: Maximum localization error (μm)
   - Worst-case spatial accuracy (up to gate threshold)

## Supporting Counts

The module also provides intermediate counts useful for interpretation:

- **TP**: True positive positions (matching positions)
- **FN**: False negative positions (ground truth positions not matched)
- **FP**: False positive positions (estimated positions not matched or spurious)
- **TP_θ**: True positive tracks (non-dummy matched tracks)
- **FN_θ**: False negative tracks (ground truth tracks paired with dummy)
- **FP_θ**: False positive tracks (spurious estimated tracks)

## Key Concepts

### Track Definition

A track (Trajectory) is a temporal series of spatial positions:
- Frames are **1-indexed** (Julia standard: frame 1 is the first frame)
- Positions can be 2D (x, y) or 3D (x, y, z) in micrometers (μm)
- Gaps are allowed (missing frames in the temporal sequence)
- Each trajectory has an associated time interval `dt` between frames

### Gated Distance

Positions are compared using a **gated Euclidean distance**:
- Gate parameter ε = 5.0 μm (default, as per paper)
- Distance between positions is capped at ε
- Positions match if distance < ε (strictly less than)
- Missing positions receive penalty ε
- **Note**: The gate is specified in physical units (μm), not pixels

### Optimal Pairing

Tracks are paired using the Hungarian algorithm to minimize total distance:
- Ground truth tracks may be paired with estimated tracks or dummy tracks
- Estimated tracks not selected in the pairing are considered spurious
- This ensures fair comparison even when track counts differ

## Usage

### Basic Example

```julia
using SMLMMetrics

# Define ground truth trajectory
gt_traj = Trajectory(
    id=1,
    frames=[1, 2, 3, 4],
    x=[0.0, 1.0, 2.0, 3.0],
    y=[0.0, 1.0, 2.0, 3.0],
    z=nothing,  # 2D data
    dt=0.01
)

# Define estimated trajectory with small errors
est_traj = Trajectory(
    id=1,
    frames=[1, 2, 3, 4],
    x=[0.1, 1.1, 2.1, 3.1],
    y=[0.1, 1.1, 2.1, 3.1],
    z=nothing,
    dt=0.01
)

# Create Tracks containers
gt_tracks = Tracks([gt_traj], (1, 4), Dict{String,Any}())
est_tracks = Tracks([est_traj], (1, 4), Dict{String,Any}())

# Evaluate tracking performance
metrics = evaluate_tracking(gt_tracks, est_tracks)

# Access results
println("JSC: ", metrics.JSC)           # Jaccard similarity for positions
println("JSC_θ: ", metrics.JSC_θ)       # Jaccard similarity for tracks
println("RMSE: ", metrics.RMSE)         # Localization error (μm)
println("α: ", metrics.α)               # Overall quality
println("β: ", metrics.β)               # Quality with spurious penalty
println("TP: ", metrics.TP)             # True positive positions
```

### Multiple Tracks

```julia
# Multiple ground truth trajectories
gt_traj1 = Trajectory(id=1, frames=[1, 2], x=[0.0, 1.0], y=[0.0, 1.0], z=nothing, dt=0.01)
gt_traj2 = Trajectory(id=2, frames=[1, 2], x=[5.0, 6.0], y=[5.0, 6.0], z=nothing, dt=0.01)
gt_tracks = Tracks([gt_traj1, gt_traj2], (1, 2), Dict{String,Any}())

# Multiple estimated trajectories
est_traj1 = Trajectory(id=1, frames=[1, 2], x=[0.1, 1.1], y=[0.1, 1.1], z=nothing, dt=0.01)
est_traj2 = Trajectory(id=2, frames=[1, 2], x=[5.1, 6.1], y=[5.1, 6.1], z=nothing, dt=0.01)
est_tracks = Tracks([est_traj1, est_traj2], (1, 2), Dict{String,Any}())

metrics = evaluate_tracking(gt_tracks, est_tracks)
```

### Custom Parameters

```julia
# Specify gate parameter
metrics = evaluate_tracking(
    gt_tracks,
    est_tracks,
    gate = 3.0    # Custom gate in μm (default: 5.0 μm)
)

# The sequence length (T) is automatically determined from the frame_range
# in the Tracks objects
```

## Interpretation Guide

### Perfect Tracking
- α = β = 1.0
- JSC = JSC_θ = 1.0
- RMSE = 0.0
- TP = total positions, FN = FP = 0

### Good Tracking with Localization Errors
- α, β close to 1.0 (> 0.9)
- JSC = JSC_θ = 1.0
- RMSE > 0 but small
- All positions match, but with spatial errors

### Missing Detections
- α, β reduced
- JSC, JSC_θ < 1.0
- FN > 0 (ground truth positions not detected)
- TP_θ < number of GT tracks OR FN_θ > 0

### Spurious Detections
- β < α (spurious tracks penalize β)
- JSC, JSC_θ < 1.0
- FP > 0 (false positive positions)
- FP_θ > 0 (spurious tracks)

### Broken Tracks
- JSC_θ < JSC (track-level worse than position-level)
- FP_θ > 0 (broken pieces counted as spurious)
- TP_θ < number of GT tracks

## Implementation Details

### Algorithm Flow

1. Compute pairwise distances between all GT and EST tracks
2. Build cost matrix including dummy tracks for unmatched tracks
3. Solve rectangular assignment problem using Munkres algorithm
4. Extract optimal pairing Z*
5. Identify spurious tracks (EST tracks not in Z*)
6. Compute all performance measures from the pairing

### Time Complexity

- O(n³) for Hungarian algorithm where n = max(|GT|, |EST|)
- Practically efficient for typical tracking scenarios (< 1000 tracks)

### Numerical Precision

- All floating-point measures are computed in Float64
- Test tolerances use atol = 0.001 for comparisons

## References

1. Chenouard, N. et al. Objective comparison of particle tracking methods. *Nat. Methods* **11**, 281–289 (2014).
2. Munkres, J. Algorithms for the Assignment and Transportation Problems. *J. Soc. Ind. Appl. Math.* **5**, 32–38 (1957).
3. Jaqaman, K. et al. Robust single-particle tracking in live-cell time-lapse sequences. *Nat. Methods* **5**, 695–702 (2008).

## Module Structure

```
src/tracking/
├── Tracking.jl           # Main module file, exports API
├── types.jl              # Trajectory and Tracks data structures with utilities
├── track_pairing.jl      # Distance computation and Hungarian assignment
└── tracking_metrics.jl   # All performance measures implementation
```

## See Also

- `src/io/` - Data loading module for SMITE, u-track, BNP-Track formats
- `src/io/README.md` - Documentation for loading tracking data
- Main SMLMMetrics documentation for complete package overview
