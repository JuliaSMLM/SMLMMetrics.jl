# SMLMMetrics.jl API Overview

This document provides a structured overview of SMLMMetrics.jl v0.3.0, which focuses on particle tracking performance evaluation using the standardized metrics from Chenouard et al., Nature Methods 11, 281-289 (2014).

## Why This Overview Exists

### For Humans
- Provides a **concise reference** for the new tracking-focused API
- Offers **quick-start examples** for common tracking evaluation workflows
- Shows **relevant patterns** for loading data and computing metrics
- Creates an **at-a-glance understanding** of the 14 Chenouard measures

### For AI Assistants
- Enables **better code generation** with correct type usage
- Provides **structured context** about Trajectory and Tracks types
- Offers **consistent examples** for loading and evaluating tracking data
- Helps avoid **common pitfalls** when working with frame indexing and coordinates

## Key Concepts

- **Trajectory**: A single particle's path through time, represented as frame numbers and corresponding (x, y, z) positions
- **Tracks**: Collection of trajectories with frame range and metadata
- **Optimal Track Pairing**: Hungarian algorithm-based assignment between ground truth and estimated trajectories
- **Gated Distance**: Distance metric with threshold (gate) to determine matching positions
- **Chenouard Metrics**: 14 standardized performance measures for objective tracking evaluation
- **Frame Indexing**: 1-indexed frames (Julia standard), converted from 0-indexed Challenge format automatically
- **Coordinate Units**: All positions in micrometers (μm), converted from pixels by loaders when needed

## Data Types

### Trajectory

Represents a single particle trajectory.

```julia
struct Trajectory
    id::Int                              # Particle identifier
    frames::Vector{Int}                  # Frame numbers (1-indexed)
    x::Vector{Float64}                   # X positions in μm
    y::Vector{Float64}                   # Y positions in μm
    z::Union{Vector{Float64}, Nothing}   # Z positions (nothing for 2D)
    dt::Float64                          # Time between frames in seconds
end
```

**Key Points:**
- Frames must be sorted in ascending order
- All position vectors must have same length as frames vector
- For 2D trajectories, set `z=nothing`
- dt must be positive
- Gaps in trajectories are represented by missing frame numbers (e.g., `[1, 2, 4, 5]` has gap at frame 3)

**Construction Example:**

```julia
# 2D trajectory with 5 positions
traj_2d = Trajectory(
    id=1,
    frames=[1, 2, 3, 4, 5],
    x=[0.0, 1.0, 2.0, 3.0, 4.0],
    y=[0.0, 0.5, 1.0, 1.5, 2.0],
    z=nothing,
    dt=0.01
)

# 3D trajectory with gap at frame 3
traj_3d = Trajectory(
    id=2,
    frames=[1, 2, 4, 5],  # Gap at frame 3
    x=[0.0, 1.0, 3.0, 4.0],
    y=[0.0, 1.0, 3.0, 4.0],
    z=[0.0, 0.2, 0.6, 0.8],
    dt=0.01
)
```

**Utility Functions:**

```julia
is_3d(traj)              # Returns true if trajectory has z-coordinates
dimensionality(traj)     # Returns 2 or 3
num_positions(traj)      # Number of positions in trajectory
temporal_length(traj)    # frames[end] - frames[1] + 1
num_gaps(traj)          # Number of missing frames
has_position(traj, frame) # Check if trajectory has position at given frame
get_position(traj, frame) # Get [x, y] or [x, y, z] at frame, or nothing if gap
```

### Tracks

Collection of trajectories with metadata.

```julia
struct Tracks
    trajectories::Vector{Trajectory}    # All trajectories
    frame_range::Tuple{Int,Int}        # (first_frame, last_frame) for sequence
    metadata::Dict{String,Any}         # Additional information
end
```

**Key Points:**
- `frame_range` defines the temporal extent of the entire sequence (needed for computing metrics)
- `trajectories` can span different subsets of the frame range
- `metadata` can store experiment info, pixel size, dt, etc.
- All trajectories must have same dimensionality (all 2D or all 3D)

**Construction Example:**

```julia
# Create multiple trajectories
traj1 = Trajectory(id=1, frames=[1,2,3], x=[0.0,1.0,2.0], y=[0.0,1.0,2.0], z=nothing, dt=0.01)
traj2 = Trajectory(id=2, frames=[2,3,4], x=[5.0,6.0,7.0], y=[5.0,6.0,7.0], z=nothing, dt=0.01)

# Combine into Tracks
tracks = Tracks(
    trajectories=[traj1, traj2],
    frame_range=(1, 4),  # Sequence spans frames 1-4
    metadata=Dict(
        "experiment" => "test_001",
        "pixel_size" => 0.107,  # μm/pixel
        "description" => "SMITE tracking results"
    )
)
```

**Utility Functions:**

```julia
num_trajectories(tracks)  # Number of trajectories
num_frames(tracks)        # Last frame - first frame + 1
total_positions(tracks)   # Sum of positions across all trajectories
is_3d(tracks)            # Returns true if all trajectories are 3D
```

### TrackingMetrics

Results of tracking evaluation containing all 14 Chenouard measures.

```julia
struct TrackingMetrics
    # Primary performance measures
    α::Float64          # Overall quality (0-1, higher is better)
    β::Float64          # Quality with penalty for spurious tracks (0-1)
    JSC::Float64        # Jaccard index for positions (0-1)
    JSC_θ::Float64      # Jaccard index for tracks (0-1)
    RMSE::Float64       # Root mean square error (μm)
    RMSE_θ::Float64     # Track-averaged RMSE (μm)
    min_error::Float64  # Minimum localization error (μm)
    max_error::Float64  # Maximum localization error (μm)

    # Supporting counts
    TP::Int    # Position-level true positives
    FN::Int    # Position-level false negatives
    FP::Int    # Position-level false positives
    TP_θ::Int  # Track-level true positives
    FN_θ::Int  # Track-level false negatives
    FP_θ::Int  # Track-level false positives
end
```

**Interpretation:**
- **α ≈ 1.0**: Excellent tracking quality
- **α ≈ 0.5**: Moderate quality
- **α ≈ 0.0**: Poor quality
- **β < α**: Presence of spurious tracks (false positives)
- **JSC = 1.0**: Perfect position-level overlap
- **JSC_θ = 1.0**: Perfect track-level matching
- **RMSE**: Average localization error for matched positions
- **RMSE_θ**: Average of per-track RMSEs (more robust to outliers)

## Core Functions

### evaluate_tracking

Main function for computing all performance metrics.

```julia
evaluate_tracking(gt_tracks::Tracks, est_tracks::Tracks; gate::Float64=5.0)
evaluate_tracking(gt_tracks::Vector{Trajectory}, est_tracks::Vector{Trajectory}; gate::Float64=5.0)
```

**Parameters:**
- `gt_tracks`: Ground truth trajectories
- `est_tracks`: Estimated trajectories to evaluate
- `gate`: Distance threshold for matching positions (default 5.0 μm)

**Returns:** `TrackingMetrics` with all 14 measures

**Examples:**

```julia
# Basic usage
gt = load_tracks(ChallengeFormat(), "ground_truth.xml")
est = load_tracks(SmiteFormat(), "results.mat")
metrics = evaluate_tracking(gt, est)

# Custom gate parameter (default is 5.0 μm)
metrics_tight = evaluate_tracking(gt, est, gate=2.0)  # Stricter matching

# Using Vector{Trajectory} directly (frame_range auto-detected)
metrics = evaluate_tracking(gt.trajectories, est.trajectories)

# Access specific measures
println("Overall quality (α): ", metrics.α)
println("Quality with penalty (β): ", metrics.β)
println("Position Jaccard (JSC): ", metrics.JSC)
println("Track Jaccard (JSC_θ): ", metrics.JSC_θ)
println("RMSE: ", metrics.RMSE, " μm")
println("Track-averaged RMSE: ", metrics.RMSE_θ, " μm")
println("Min/Max errors: ", metrics.min_error, " / ", metrics.max_error, " μm")
println("Positions - TP:", metrics.TP, " FN:", metrics.FN, " FP:", metrics.FP)
println("Tracks - TP:", metrics.TP_θ, " FN:", metrics.FN_θ, " FP:", metrics.FP_θ)
```

### load_tracks

Unified function for loading tracking data from various formats using multiple dispatch.

```julia
load_tracks(format::FormatType, filepath::String; kwargs...)
```

**Format Types:**
- `SmiteFormat()`: SMITE .mat files
- `UTrackFormat()`: u-track .mat files (not yet implemented)
- `BNPTrackFormat()`: BNP-Track .mat files (not yet implemented)
- `ChallengeFormat()`: Particle Tracking Challenge XML

#### SMITE Format

```julia
load_tracks(::SmiteFormat, filepath::String; varname::String="SMD", dt::Float64=0.01)
```

**Parameters:**
- `filepath`: Path to SMITE .mat file
- `varname`: Variable name in MAT file (default "SMD")
- `dt`: Time between frames in seconds (default 0.01)

**SMITE Data Structure:**
- Expects MAT file with structure containing fields: `X`, `Y`, `Z` (optional), `ConnectID`, `FrameNum`
- Groups positions by `ConnectID` to form trajectories
- Coordinates already in μm (no conversion needed)

**Example:**

```julia
# Load SMITE results with default settings
smite_tracks = load_tracks(SmiteFormat(), "smite_results.mat")

# Load with custom variable name and time step
smite_tracks = load_tracks(SmiteFormat(), "data.mat", varname="TrackingData", dt=0.05)
```

#### Challenge Format (Ground Truth XML)

```julia
load_tracks(::ChallengeFormat, filepath::String; pixel_size::Float64=0.1, dt::Float64=0.01)
```

**Parameters:**
- `filepath`: Path to Particle Tracking Challenge XML file
- `pixel_size`: Micrometers per pixel for coordinate conversion (default 0.1)
- `dt`: Time between frames in seconds (default 0.01)

**XML Structure:**
- Parses `<particle>` elements with nested `<detection>` elements
- Converts 0-indexed frames to 1-indexed automatically
- Converts pixel coordinates to μm using pixel_size
- Handles both 2D (`t`, `x`, `y`) and 3D (`t`, `x`, `y`, `z`) data

**Example:**

```julia
# Load ground truth with typical confocal pixel size
gt_tracks = load_tracks(ChallengeFormat(), "ground_truth.xml", pixel_size=0.107)

# Load with different pixel size and time step
gt_tracks = load_tracks(ChallengeFormat(), "gt.xml", pixel_size=0.05, dt=0.02)
```

#### u-track and BNP-Track Formats

*Note: These loaders are not yet implemented in v0.3.0.*

```julia
# Placeholder API (to be implemented)
utrack_tracks = load_tracks(UTrackFormat(), "utrack_results.mat")
bnp_tracks = load_tracks(BNPTrackFormat(), "bnp_results.mat")
```

## Common Workflows

### Basic Tracking Evaluation

```julia
using SMLMMetrics

# Load data
gt = load_tracks(ChallengeFormat(), "ground_truth.xml", pixel_size=0.107)
est = load_tracks(SmiteFormat(), "tracking_results.mat")

# Evaluate
metrics = evaluate_tracking(gt, est)

# Report key metrics
println("Tracking Performance:")
println("  Overall Quality (α): $(round(metrics.α, digits=3))")
println("  Quality w/ Penalty (β): $(round(metrics.β, digits=3))")
println("  Position Jaccard: $(round(metrics.JSC, digits=3))")
println("  Track Jaccard: $(round(metrics.JSC_θ, digits=3))")
println("  RMSE: $(round(metrics.RMSE, digits=3)) μm")
```

### Comparing Multiple Tracking Algorithms

```julia
using SMLMMetrics

# Load ground truth once
gt = load_tracks(ChallengeFormat(), "ground_truth.xml", pixel_size=0.107)

# Load results from different algorithms
algorithms = Dict(
    "SMITE" => load_tracks(SmiteFormat(), "smite_results.mat"),
    "u-track" => load_tracks(UTrackFormat(), "utrack_results.mat"),
    "BNP-Track" => load_tracks(BNPTrackFormat(), "bnp_results.mat")
)

# Evaluate each algorithm
results = Dict()
for (name, tracks) in algorithms
    results[name] = evaluate_tracking(gt, tracks)
end

# Compare performance
println("Algorithm Comparison:")
println("Algorithm\t\tα\t\tβ\t\tJSC_θ\t\tRMSE (μm)")
for (name, metrics) in results
    println("$name\t\t$(round(metrics.α, digits=3))\t\t$(round(metrics.β, digits=3))\t\t$(round(metrics.JSC_θ, digits=3))\t\t$(round(metrics.RMSE, digits=3))")
end
```

### Manual Trajectory Creation and Evaluation

```julia
using SMLMMetrics

# Create ground truth trajectories
gt_traj1 = Trajectory(
    id=1,
    frames=[1, 2, 3, 4, 5],
    x=[0.0, 1.0, 2.0, 3.0, 4.0],
    y=[0.0, 1.0, 2.0, 3.0, 4.0],
    z=nothing,
    dt=0.01
)

gt_traj2 = Trajectory(
    id=2,
    frames=[1, 2, 3, 4, 5],
    x=[5.0, 6.0, 7.0, 8.0, 9.0],
    y=[5.0, 6.0, 7.0, 8.0, 9.0],
    z=nothing,
    dt=0.01
)

gt_tracks = Tracks([gt_traj1, gt_traj2], (1, 5), Dict{String,Any}())

# Create estimated trajectories (with errors)
est_traj1 = Trajectory(
    id=1,
    frames=[1, 2, 3, 4, 5],
    x=[0.1, 1.1, 2.1, 3.1, 4.1],
    y=[0.1, 1.1, 2.1, 3.1, 4.1],
    z=nothing,
    dt=0.01
)

# Missing second trajectory (false negative)
est_tracks = Tracks([est_traj1], (1, 5), Dict{String,Any}())

# Evaluate
metrics = evaluate_tracking(gt_tracks, est_tracks)

println("Results with missed trajectory:")
println("  Track-level FN: ", metrics.FN_θ)  # Should be 1 (missed gt_traj2)
println("  Track Jaccard: ", metrics.JSC_θ)  # Should be 0.5 (1 TP, 1 FN, 0 FP)
```

### Working with 3D Trajectories

```julia
using SMLMMetrics

# Create 3D trajectory
traj_3d = Trajectory(
    id=1,
    frames=[1, 2, 3, 4, 5],
    x=[0.0, 1.0, 2.0, 3.0, 4.0],
    y=[0.0, 1.0, 2.0, 3.0, 4.0],
    z=[0.0, 0.2, 0.4, 0.6, 0.8],
    dt=0.01
)

# Check dimensionality
println("Is 3D: ", is_3d(traj_3d))           # true
println("Dimensions: ", dimensionality(traj_3d))  # 3

# Get position at specific frame
pos = get_position(traj_3d, 3)  # Returns [2.0, 2.0, 0.4]
```

### Handling Trajectories with Gaps

```julia
using SMLMMetrics

# Trajectory with gap at frame 3
traj_gaps = Trajectory(
    id=1,
    frames=[1, 2, 4, 5],  # Frame 3 missing
    x=[0.0, 1.0, 3.0, 4.0],
    y=[0.0, 1.0, 3.0, 4.0],
    z=nothing,
    dt=0.01
)

# Query gap properties
println("Number of positions: ", num_positions(traj_gaps))      # 4
println("Temporal length: ", temporal_length(traj_gaps))        # 5 (frames 1-5)
println("Number of gaps: ", num_gaps(traj_gaps))               # 1
println("Has position at frame 2: ", has_position(traj_gaps, 2))  # true
println("Has position at frame 3: ", has_position(traj_gaps, 3))  # false
println("Position at frame 3: ", get_position(traj_gaps, 3))      # nothing
```

## Parameter Guidelines

### Gate Distance
- **Purpose**: Threshold for determining if positions match between ground truth and estimate
- **Default**: 5.0 μm (conservative for typical SMLM tracking)
- **Typical Range**: 1.0 - 10.0 μm
- **Guidelines**:
  - Use smaller gate (1-3 μm) for high-precision tracking
  - Use larger gate (5-10 μm) for lower-precision or fast-moving particles
  - Should be 2-5× expected localization precision

### Frame Rate (dt)
- **Purpose**: Time between consecutive frames in seconds
- **Default**: 0.01 s (100 fps)
- **Common Values**:
  - Fast imaging: 0.001 - 0.01 s (100-1000 fps)
  - Standard imaging: 0.01 - 0.1 s (10-100 fps)
  - Slow imaging: 0.1 - 1.0 s (1-10 fps)

### Pixel Size
- **Purpose**: Convert pixel coordinates to micrometers
- **Default**: 0.1 μm/pixel (100 nm/pixel)
- **Common Values**:
  - High magnification (100x oil): 0.05 - 0.08 μm/pixel
  - Standard magnification (60x oil): 0.1 - 0.15 μm/pixel
  - Lower magnification (40x): 0.15 - 0.2 μm/pixel

## Common Pitfalls and Important Notes

### Frame Indexing
- **Julia uses 1-indexed frames** (frame 1 is first frame)
- **Challenge XML uses 0-indexed frames** (converted automatically by loader)
- When creating trajectories manually, use 1-indexed frames
- Frame ranges are inclusive: `(1, 5)` means frames 1, 2, 3, 4, 5

### Coordinate Units
- **All coordinates must be in micrometers (μm)**
- SMITE, u-track, and BNP-Track already output in μm
- Challenge XML requires `pixel_size` parameter for conversion
- Never mix pixel and physical coordinates

### Trajectory Requirements
- Frames must be sorted in ascending order
- All position vectors (x, y, z) must have same length as frames vector
- dt must be positive
- For 2D trajectories, set `z=nothing` (not empty vector)

### Data Loading
- **SMITE**: Assumes variable name "SMD" by default (use `varname` parameter if different)
- **Challenge XML**: Requires `pixel_size` parameter (no default that works for all datasets)
- **u-track and BNP-Track**: Not yet implemented in v0.3.0

### Performance Considerations
- **Hungarian algorithm** scales as O(n³) where n is number of tracks
- For large datasets (>1000 tracks), evaluation may take significant time
- Consider filtering short trajectories (< 3 positions) before evaluation

### Metric Interpretation
- **α = 1.0, β < 1.0**: Perfect matching but with spurious tracks
- **JSC_θ = 1.0 but JSC < 1.0**: All tracks matched but positions have errors
- **RMSE_θ > RMSE**: Some tracks have much higher errors than others
- **Zero RMSE with JSC < 1.0**: Some positions matched perfectly, others not matched at all

## Type Information for AI Assistants

### Function Signatures

```julia
# Main evaluation function
evaluate_tracking(gt::Tracks, est::Tracks; gate::Float64=5.0) -> TrackingMetrics
evaluate_tracking(gt::Vector{Trajectory}, est::Vector{Trajectory}; gate::Float64=5.0) -> TrackingMetrics

# Data loading functions
load_tracks(::SmiteFormat, filepath::String; varname::String="SMD", dt::Float64=0.01) -> Tracks
load_tracks(::ChallengeFormat, filepath::String; pixel_size::Float64=0.1, dt::Float64=0.01) -> Tracks
load_tracks(::UTrackFormat, filepath::String; dt::Float64=0.01) -> Tracks  # Not implemented
load_tracks(::BNPTrackFormat, filepath::String; dt::Float64=0.01) -> Tracks  # Not implemented

# Utility functions
is_3d(traj::Trajectory) -> Bool
is_3d(tracks::Tracks) -> Bool
dimensionality(traj::Trajectory) -> Int
num_positions(traj::Trajectory) -> Int
temporal_length(traj::Trajectory) -> Int
num_gaps(traj::Trajectory) -> Int
has_position(traj::Trajectory, frame::Int) -> Bool
get_position(traj::Trajectory, frame::Int) -> Union{Vector{Float64}, Nothing}
num_trajectories(tracks::Tracks) -> Int
num_frames(tracks::Tracks) -> Int
total_positions(tracks::Tracks) -> Int
```

### Important Constants

```julia
const DEFAULT_GATE = 5.0  # Default gate distance in micrometers
```

### Type Hierarchies

```julia
# Format types (for dispatch)
abstract type TrackingFormat end  # (internal, not exported)

SmiteFormat <: TrackingFormat
UTrackFormat <: TrackingFormat
BNPTrackFormat <: TrackingFormat
ChallengeFormat <: TrackingFormat
```

## Migration from v0.2.x

SMLMMetrics v0.3.0 is a complete rewrite focused on particle tracking. The old API for point-based localization metrics has been removed.

### Removed Functions
- `jaccard(a, b, cutoff)` - Use `evaluate_tracking` and access `metrics.JSC`
- `match(a, b, cutoff)` - Not directly exposed (used internally)
- `rmse(a, b, α)` - Use `evaluate_tracking` and access `metrics.RMSE`
- `efficiency(a, b, cutoff, α)` - Not available (use α and β instead)

### Removed Dependencies
- SMLMData.jl - No longer required
- SMLMSim.jl - Removed (synthetic data generation)
- Distances.jl - No longer required
- Distributions.jl - No longer required
- Random.jl - No longer required
- SparseArrays.jl - No longer required

### New Focus
- Particle tracking evaluation (not single-frame localization)
- Chenouard et al. (2014) standardized metrics
- Trajectory and Tracks data structures
- Multiple data format support (SMITE, u-track, BNP-Track, Challenge XML)

If you need the old point-based metrics, please use SMLMMetrics v0.2.x.
