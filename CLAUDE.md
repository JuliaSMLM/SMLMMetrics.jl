# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SMLMMetrics.jl is a Julia package for evaluating particle tracking performance in single molecule localization microscopy (SMLM) data. It implements the comprehensive performance metrics defined in Chenouard et al., "Objective comparison of particle tracking methods", Nature Methods 11, 281-289 (2014).

**Version 0.3.0** is a complete rewrite focused on particle tracking evaluation (not single-frame localization metrics).

## Common Development Commands

### Testing
```bash
# Run full test suite
julia --project=. -e "using Pkg; Pkg.test()"

# Interactive development (use dev/ directory)
julia --project=dev
```

### Documentation
```bash
# Build documentation
julia --project=docs docs/make.jl
```

### Package Management
```bash
# Install dependencies
julia --project=. -e "using Pkg; Pkg.instantiate()"

# Update dependencies
julia --project=. -e "using Pkg; Pkg.update()"
```

## Code Architecture

### Core Module Structure
- **src/SMLMMetrics.jl** - Main module that re-exports from submodules
- **src/tracking/** - Tracking evaluation submodule
  - **Tracking.jl** - Module file (capitalized per convention)
  - **types.jl** - Trajectory and Tracks data structures with utility functions
  - **track_pairing.jl** - Optimal track pairing using Hungarian algorithm
  - **tracking_metrics.jl** - All 14 Chenouard performance measures implementation
- **src/io/** - Data loading submodule
  - **IO.jl** - Module file (capitalized per convention)
  - **formats.jl** - Format type tags (SmiteFormat, UTrackFormat, BNPTrackFormat, ChallengeFormat)
  - **loaders.jl** - Unified load_tracks() with multiple dispatch on format types

### Key Data Types
- `Trajectory` - Single particle trajectory with:
  - `id::Int` - Particle identifier
  - `frames::Vector{Int}` - Frame numbers (1-indexed, Julia standard)
  - `x::Vector{Float64}`, `y::Vector{Float64}` - Positions in μm
  - `z::Union{Vector{Float64}, Nothing}` - Optional z-coordinate for 3D
  - `dt::Float64` - Time between frames in seconds
- `Tracks` - Collection of trajectories with:
  - `trajectories::Vector{Trajectory}`
  - `frame_range::Tuple{Int,Int}` - Temporal extent (needed for metrics)
  - `metadata::Dict{String,Any}` - Additional information
- `TrackingMetrics` - Results containing all 14 Chenouard measures:
  - Primary: α, β, JSC, JSC_θ, RMSE, RMSE_θ, min_error, max_error
  - Counts: TP, FN, FP, TP_θ, FN_θ, FP_θ

### Key Functions
- `evaluate_tracking(gt, est; gate=5.0)` - Compute all 14 performance measures
- `load_tracks(format, filepath; kwargs...)` - Load tracking data from various formats

### Supported Data Formats
- **SMITE** - Single Molecule Imaging Toolbox Extraordinaire (.mat) - implemented
- **Challenge Format** - Particle Tracking Challenge ground truth XML - implemented
- **u-track** - Danuser Lab tracking software (.mat) - not yet implemented
- **BNP-Track** - Bayesian Nonparametric Tracking (.mat) - not yet implemented

### Dependencies
- `Hungarian` - Hungarian algorithm for optimal track pairing
- `MAT` - MATLAB file support for SMITE/u-track/BNP-Track
- `LightXML` - XML parsing for Challenge format
- `LinearAlgebra` - Vector/matrix operations
- `Statistics` - Mean, variance calculations

## Development Workflow

### Interactive Development
Use the `dev/` directory with Revise.jl for interactive development. This directory contains development-specific dependencies like CairoMakie for plotting.

### CI/CD Pipeline
- GitHub Actions runs tests on Julia 1.6, 1.8, and nightly
- Documentation auto-deployed to GitHub Pages
- CompatHelper manages dependency updates
- TagBot handles automatic version tagging

### Code Style
Follow standard Julia package conventions. The codebase uses:
- Modular design with submodules (Tracking, IO)
- Capitalized module files (Tracking.jl, IO.jl, types.jl)
- 1-indexed frames (Julia standard, converted from 0-indexed Challenge format automatically)
- All coordinates in micrometers (μm), not pixels
- DocStrings for all exported types and functions
- Comprehensive test coverage in test/runtests.jl and test/test_tracking.jl

## Important Technical Decisions

### Frame Indexing
- **Julia standard**: 1-indexed frames (frame 1 is first frame)
- **Challenge XML**: 0-indexed (converted automatically by loader)
- Frame ranges are inclusive: `(1, 5)` means frames 1, 2, 3, 4, 5

### Coordinate Units
- **All positions in micrometers (μm)**
- SMITE, u-track, BNP-Track already output in μm (no conversion)
- Challenge XML requires `pixel_size` parameter for conversion

### Type Design
- Single `Trajectory` type with optional `z` field (not separate 2D/3D types)
- `dt` stored per-trajectory (not per-dataset) for flexibility
- `frame_range` in Tracks for determining sequence length (T parameter in paper)

### Multiple Dispatch
- `load_tracks()` uses format type tags for dispatch (SmiteFormat(), ChallengeFormat(), etc.)
- Format types are empty structs used purely for dispatch

## Quick Reference for Common Tasks

### Loading Data
```julia
# Load SMITE results
tracks = load_tracks(SmiteFormat(), "results.mat")

# Load Challenge ground truth (requires pixel_size)
gt = load_tracks(ChallengeFormat(), "gt.xml", pixel_size=0.107)
```

### Evaluating Tracking
```julia
metrics = evaluate_tracking(gt_tracks, est_tracks, gate=5.0)

# Access metrics
println("Overall quality: ", metrics.α)
println("Track Jaccard: ", metrics.JSC_θ)
println("RMSE: ", metrics.RMSE, " μm")
```

### Creating Trajectories Manually
```julia
traj = Trajectory(
    id=1,
    frames=[1, 2, 3, 4, 5],
    x=[0.0, 1.0, 2.0, 3.0, 4.0],
    y=[0.0, 1.0, 2.0, 3.0, 4.0],
    z=nothing,  # For 2D
    dt=0.01
)

tracks = Tracks([traj], (1, 5), Dict{String,Any}())
```