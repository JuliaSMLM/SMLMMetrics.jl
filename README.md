# SMLMMetrics.jl

SMLMMetrics is a Julia package for evaluating particle tracking performance in single molecule localization microscopy (SMLM) data. It implements the comprehensive performance metrics defined in Chenouard et al., "Objective comparison of particle tracking methods", Nature Methods 11, 281-289 (2014).

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaSMLM.github.io/SMLMMetrics.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaSMLM.github.io/SMLMMetrics.jl/dev/)
[![Build Status](https://github.com/JuliaSMLM/SMLMMetrics.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaSMLM/SMLMMetrics.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/JuliaSMLM/SMLMMetrics.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaSMLM/SMLMMetrics.jl)

## Features

- **All 14 Chenouard Performance Measures**: Complete implementation of standardized tracking evaluation metrics
- **Optimal Track Pairing**: Hungarian algorithm-based assignment between ground truth and estimated trajectories
- **Gated Distance Metric**: Configurable threshold for robust trajectory comparison
- **Unified Data Loading**: Support for SMITE, u-track, BNP-Track, and Particle Tracking Challenge formats
- **2D and 3D Trajectories**: Single data structure with optional z-coordinate support
- **Quality Metrics**: α (overall quality), β (quality with penalty), JSC (position-based Jaccard), JSC_θ (track-based Jaccard)
- **Accuracy Metrics**: RMSE (position-based), RMSE_θ (track-averaged), min/max localization errors

## Installation

To install SMLMMetrics, use the Julia package manager:

```julia
using Pkg
Pkg.add("SMLMMetrics")
```

## Documentation

- [**STABLE**](https://JuliaSMLM.github.io/SMLMMetrics.jl/stable/) - Documentation for the most recently tagged version of SMLMMetrics.
- [**DEVELOPMENT**](https://JuliaSMLM.github.io/SMLMMetrics.jl/dev/) - Documentation for the in-development version of SMLMMetrics.

## Quick Start

```julia
using SMLMMetrics

# Load ground truth and estimated tracking results
gt_tracks = load_tracks(ChallengeFormat(), "ground_truth.xml", pixel_size=0.107)
est_tracks = load_tracks(SmiteFormat(), "tracking_results.mat")

# Evaluate tracking performance
metrics = evaluate_tracking(gt_tracks, est_tracks)

# Access the 14 performance measures
println("Quality Metrics:")
println("  α (overall quality): ", round(metrics.α, digits=3))
println("  β (quality with penalty): ", round(metrics.β, digits=3))

println("\nJaccard Indices:")
println("  JSC (positions): ", round(metrics.JSC, digits=3))
println("  JSC_θ (tracks): ", round(metrics.JSC_θ, digits=3))

println("\nAccuracy Metrics:")
println("  RMSE: ", round(metrics.RMSE, digits=3), " μm")
println("  RMSE_θ: ", round(metrics.RMSE_θ, digits=3), " μm")
println("  Min error: ", round(metrics.min_error, digits=3), " μm")
println("  Max error: ", round(metrics.max_error, digits=3), " μm")

println("\nCounts:")
println("  Position level - TP: ", metrics.TP, ", FN: ", metrics.FN, ", FP: ", metrics.FP)
println("  Track level - TP_θ: ", metrics.TP_θ, ", FN_θ: ", metrics.FN_θ, ", FP_θ: ", metrics.FP_θ)
```

### Creating Trajectories Manually

```julia
using SMLMMetrics

# Create a 2D trajectory
traj = Trajectory(
    id=1,
    frames=[1, 2, 3, 4, 5],
    x=[0.0, 1.0, 2.0, 3.0, 4.0],
    y=[0.0, 0.5, 1.0, 1.5, 2.0],
    z=nothing,  # For 2D data
    dt=0.01     # Time between frames in seconds
)

# Create a 3D trajectory
traj_3d = Trajectory(
    id=2,
    frames=[1, 2, 3],
    x=[0.0, 1.0, 2.0],
    y=[0.0, 1.0, 2.0],
    z=[0.0, 0.2, 0.4],  # Include z for 3D
    dt=0.01
)

# Combine trajectories into a Tracks container
tracks = Tracks(
    trajectories=[traj, traj_3d],
    frame_range=(1, 5),
    metadata=Dict("experiment" => "test")
)

# Evaluate against another dataset
metrics = evaluate_tracking(ground_truth_tracks, tracks)
```

## Core Components

### Data Types
- **`Trajectory`**: Single particle trajectory with frame numbers, positions (x, y, z), and time step
- **`Tracks`**: Collection of trajectories with frame range and metadata
- **`TrackingMetrics`**: Results containing all 14 Chenouard performance measures

### Main Functions
- **`evaluate_tracking(gt, est; gate=5.0)`**: Compute all performance metrics by comparing ground truth and estimated tracks
- **`load_tracks(format, filepath; kwargs...)`**: Load tracking data from various formats using multiple dispatch

### Format Types (for `load_tracks`)
- **`SmiteFormat()`**: SMITE (Single Molecule Imaging Toolbox Extraordinaire)
- **`UTrackFormat()`**: u-track (Danuser Lab)
- **`BNPTrackFormat()`**: BNP-Track (Bayesian Nonparametric Tracking)
- **`ChallengeFormat()`**: Particle Tracking Challenge ground truth XML

## Requirements

- Julia ≥ 1.6
- Hungarian.jl (optimal track pairing)
- MAT.jl (MATLAB file support)
- LightXML.jl (XML parsing for Challenge format)

## The 14 Chenouard Performance Measures

SMLMMetrics implements all performance measures from the standardized tracking evaluation framework:

### Primary Quality Metrics
- **α**: Overall tracking quality (considers all matching pairs)
- **β**: Quality with penalty for spurious tracks (penalizes false positives)

### Jaccard Indices
- **JSC**: Position-based Jaccard similarity coefficient
- **JSC_θ**: Track-based Jaccard similarity coefficient

### Accuracy Metrics
- **RMSE**: Root mean square error over all matched positions
- **RMSE_θ**: Track-averaged RMSE (average of per-track RMSEs)
- **min_error**: Minimum localization error across all matched positions
- **max_error**: Maximum localization error across all matched positions

### Supporting Counts
- **TP, FN, FP**: Position-level true positives, false negatives, false positives
- **TP_θ, FN_θ, FP_θ**: Track-level true positives, false negatives, false positives

For details on the metric definitions, see Chenouard et al., Nature Methods 11, 281-289 (2014).

## Contributing

Contributions to SMLMMetrics are always welcome! If you have any suggestions, feature requests, or bug reports, please open an issue on [GitHub](https://github.com/JuliaSMLM/SMLMMetrics.jl/issues).

## License

SMLMMetrics.jl is licensed under the [MIT License](LICENSE).
