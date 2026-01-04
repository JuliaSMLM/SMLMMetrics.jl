"""
    SMLMMetrics

A Julia package for evaluating particle tracking performance using the metrics
defined in Chenouard et al., "Objective comparison of particle tracking methods",
Nature Methods 11, 281-289 (2014).

# Main Features

## Tracking Performance Evaluation
- All 14 performance measures from Chenouard et al. (2014)
- Optimal track pairing using Hungarian algorithm
- Gated Euclidean distance for trajectory comparison

## Data Types
- `Trajectory`: Single particle trajectory with frame numbers and positions
- `Tracks`: Collection of trajectories with metadata
- `TrackingMetrics`: Results containing all 14 performance measures

## Data Loading
- Unified `load_tracks()` function with multiple dispatch
- Support for SMITE, u-track, BNP-Track, and Particle Tracking Challenge formats

# Quick Start

```julia
using SMLMMetrics

# Load ground truth and estimated tracking results
gt_tracks = load_tracks(ChallengeFormat(), "ground_truth.xml")
est_tracks = load_tracks(SmiteFormat(), "tracking_results.mat")

# Evaluate performance
metrics = evaluate_tracking(gt_tracks, est_tracks)

# Access results
println("Jaccard Index (positions): ", metrics.JSC)
println("Jaccard Index (tracks): ", metrics.JSC_θ)
println("RMSE: ", metrics.RMSE, " μm")
println("Overall Quality (α): ", metrics.α)
println("Quality with penalty (β): ", metrics.β)
```

# Exported from Tracking Module
- `Trajectory`, `Tracks`, `TrackingMetrics`
- `evaluate_tracking`

# Exported from IO Module
- `SmiteFormat`, `UTrackFormat`, `BNPTrackFormat`, `ChallengeFormat`
- `load_tracks`
"""
module SMLMMetrics

# Core dependencies
using LinearAlgebra
using Statistics
using Hungarian
using MAT
using LightXML

# Include submodules
include("tracking/tracking.jl")
include("io/io.jl")

# Re-export from Tracking module
using .Tracking
export Trajectory, Tracks, TrackingMetrics
export evaluate_tracking
export is_3d, dimensionality, num_positions, temporal_length, num_gaps
export has_position, get_position
export num_trajectories, num_frames, total_positions
export DEFAULT_GATE

# Re-export from IO module
using .IO
export SmiteFormat, UTrackFormat, BNPTrackFormat, ChallengeFormat
export load_tracks

end # module
