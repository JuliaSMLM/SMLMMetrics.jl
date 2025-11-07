# Data Loading Module (IO)

This module provides a unified interface for loading particle tracking data from various software packages into the standardized `Tracks` and `Trajectory` format used by SMLMMetrics.

## Overview

The IO module uses **multiple dispatch** on format type tags to provide a consistent `load_tracks()` function that handles different file formats. All loaders return `Tracks` objects containing `Trajectory` data structures.

## Supported Formats

### SMITE (Single Molecule Imaging Toolbox Extraordinaire)
- **Lab**: Lidke Lab (UNM)
- **File Format**: MATLAB .mat files
- **Default Variable**: `"SMD"` (Single Molecule Data)
- **Format Tag**: `SmiteFormat()`
- **Coordinates**: Already in micrometers (μm) with pixel_size conversion
- **Reference**: https://github.com/LidkeLab/smite

### u-track
- **Lab**: Danuser Lab (UT Southwestern)
- **File Format**: MATLAB .mat files
- **Default Variable**: `"tracksFinal"`
- **Format Tag**: `UTrackFormat()`
- **Coordinates**: Stored in pixels, converted using `pixel_size` parameter
- **Special Feature**: Handles compound tracks (merging/splitting events)
- **Reference**: https://github.com/DanuserLab/u-track

### BNP-Track (Bayesian Nonparametric Tracking)
- **Lab**: Lab Presse (Grenoble)
- **File Format**: MATLAB .mat files
- **Default Variable**: `"chain"` (MCMC chain)
- **Format Tag**: `BNPTrackFormat()`
- **Coordinates**: Already in micrometers (μm)
- **Special Feature**: Extracts final sample from MCMC posterior
- **Reference**: https://github.com/LabPresse/BNPTrack

## Basic Usage

### Loading Different Formats

```julia
using SMLMMetrics

# Load SMITE results
smite_tracks = load_tracks(SmiteFormat(), "path/to/smite_results.mat")

# Load u-track results
utrack_tracks = load_tracks(UTrackFormat(), "path/to/tracksFinal.mat")

# Load BNP-Track results
bnp_tracks = load_tracks(BNPTrackFormat(), "path/to/chain.mat")
```

### Custom Parameters

```julia
# SMITE with custom variable name and frame rate
tracks = load_tracks(SmiteFormat(), "data.mat",
    varname="SMD",
    dt=0.005  # 5ms per frame
)

# u-track with custom pixel size
tracks = load_tracks(UTrackFormat(), "tracksFinal.mat",
    varname="tracksFinal",
    dt=0.01,
    pixel_size=0.108,  # 108 nm pixels
    flatten_compound=true
)

# BNP-Track with custom frame rate
tracks = load_tracks(BNPTrackFormat(), "chain.mat",
    varname="chain",
    dt=0.02  # 20ms per frame
)
```

## Format-Specific Details

### SMITE Format

**Structure**: SMITE stores single molecule localization data with tracking connections via `ConnectID` field.

**Key Fields**:
- `X`, `Y`, `Z`: Positions (with pixel_size scaling)
- `FrameNum`: Frame number for each localization
- `ConnectID`: Track identifier linking localizations
- `PixelSize`: Pixel size metadata
- `NFrames`: Total number of frames

**Special Handling**:
- Complex-valued fields are detected and removed with warning
- Coordinates converted from scaled units to micrometers
- Supports both 2D and 3D data (Z field optional)

**Parameters**:
- `varname::String`: Variable name in .mat file (default: `"SMD"`)
- `dt::Float64`: Time between frames in seconds (default: `0.01`)

### u-track Format

**Structure**: u-track uses compound tracks that may include merging/splitting events. Each compound track contains:
- `tracksCoordAmpCG`: Position and amplitude data (8 columns per frame)
- `tracksFeatIndxCG`: Feature indices for sub-tracks
- `seqOfEvents`: Frame timing and event sequence

**Key Features**:
- Compound tracks are split into simple tracks when `flatten_compound=true` (recommended)
- Gap frames (NaN values) are automatically skipped
- Frame timing extracted from `seqOfEvents` when available
- Supports both standard and simplified formats

**Coordinate Layout** (tracksCoordAmpCG):
- Columns 1-2: x, y positions (pixels)
- Column 3: z position (pixels, for 3D)
- Columns 4-8: amplitude and uncertainty data

**Parameters**:
- `varname::String`: Variable name in .mat file (default: `"tracksFinal"`)
- `dt::Float64`: Time between frames in seconds (default: `0.01`)
- `pixel_size::Float64`: Pixel size in micrometers (default: `0.1`)
- `flatten_compound::Bool`: Split compound tracks into simple tracks (default: `true`)

**Important**: Always provide accurate `pixel_size` for your microscope setup!

### BNP-Track Format

**Structure**: BNP-Track performs Bayesian inference via MCMC and outputs a posterior distribution. The loader extracts the final sample state.

**Key Fields**:
- `chain.sample.X`, `Y`, `Z`: Position matrices (N timepoints × M particles)
- `chain.sample.b`: Existence indicator for particles (length M vector)
- `chain.sample.K`: Atom assignment per timepoint (length N vector)
- `chain.params.t_mid`: Frame timing information

**Key Features**:
- Only active particles (b ≥ 0.5) are extracted
- NaN and invalid positions are automatically filtered
- Each column represents a potential particle trajectory
- Coordinates assumed to be in micrometers

**Parameters**:
- `varname::String`: Variable name in .mat file (default: `"chain"`)
- `dt::Float64`: Time between frames in seconds (default: `0.01`)

## Return Type: Tracks

All loaders return a `Tracks` object with:

```julia
struct Tracks
    trajectories::Vector{Trajectory}  # Collection of trajectories
    frame_range::Tuple{Int,Int}       # (min_frame, max_frame)
    metadata::Dict{String,Any}        # Format-specific metadata
end
```

Each `Trajectory` contains:

```julia
struct Trajectory
    id::Int                           # Trajectory identifier
    frames::Vector{Int}               # Frame numbers (1-indexed)
    x::Vector{Float64}                # X coordinates (μm)
    y::Vector{Float64}                # Y coordinates (μm)
    z::Union{Vector{Float64},Nothing} # Z coordinates (μm) or nothing for 2D
    dt::Float64                       # Time between frames (seconds)
end
```

### Metadata Fields

Common metadata across all formats:
- `"source"`: Format name (e.g., "SMITE", "u-track", "BNP-Track")
- `"original_file"`: Path to loaded file
- `"is_3d"`: Boolean indicating 2D or 3D data
- `"n_tracks"`: Number of trajectories

Format-specific metadata:
- **SMITE**: `"pixel_size"`, `"complex_fields_removed"`, `"removed_emitter_count"`
- **u-track**: `"pixel_size"`, `"flatten_compound"`, `"n_compound_tracks"`
- **BNP-Track**: `"n_active_particles"`, `"max_particles"`, `"chain_length"`, `"chain_stride"`

## Data Standards

### Coordinate Units
All loaders ensure coordinates are in **micrometers (μm)**:
- SMITE: Converted from scaled pixels (pixel_size / 100)
- u-track: Converted from pixels using `pixel_size` parameter
- BNP-Track: Already in micrometers (no conversion)

### Frame Indexing
All trajectories use **1-indexed frames** (Julia standard):
- Frame 1 is the first frame
- `frame_range = (1, 100)` means frames 1 through 100
- This is consistent across all formats
- Challenge XML format (0-indexed) would be auto-converted if implemented

### Time Representation
Frame time interval `dt` (in seconds) is stored per-trajectory for flexibility:
- Common values: `0.01` (100 Hz), `0.005` (200 Hz), `0.02` (50 Hz)
- Set based on your camera frame rate
- Used by tracking metrics for temporal analysis

## Complete Example Workflow

```julia
using SMLMMetrics

# Load ground truth from Challenge format (when implemented)
# gt_tracks = load_tracks(ChallengeFormat(), "gt.xml", pixel_size=0.1)

# For now, assume gt_tracks exists from another source

# Load estimated tracks from different methods
smite_results = load_tracks(SmiteFormat(), "smite_output.mat", dt=0.01)
utrack_results = load_tracks(UTrackFormat(), "tracksFinal.mat",
    dt=0.01,
    pixel_size=0.108,
    flatten_compound=true
)
bnp_results = load_tracks(BNPTrackFormat(), "chain.mat", dt=0.01)

# Evaluate each method
smite_metrics = evaluate_tracking(gt_tracks, smite_results)
utrack_metrics = evaluate_tracking(gt_tracks, utrack_results)
bnp_metrics = evaluate_tracking(gt_tracks, bnp_results)

# Compare results
println("SMITE: α=$(smite_metrics.α), JSC_θ=$(smite_metrics.JSC_θ)")
println("u-track: α=$(utrack_metrics.α), JSC_θ=$(utrack_metrics.JSC_θ)")
println("BNP-Track: α=$(bnp_metrics.α), JSC_θ=$(bnp_metrics.JSC_θ)")
```

## Inspecting Loaded Data

```julia
# Load tracks
tracks = load_tracks(SmiteFormat(), "data.mat")

# Basic information
println("Number of trajectories: ", length(tracks.trajectories))
println("Frame range: ", tracks.frame_range)
println("Metadata: ", tracks.metadata)

# Examine first trajectory
traj = tracks.trajectories[1]
println("Trajectory ID: ", traj.id)
println("Number of positions: ", length(traj.frames))
println("First frame: ", first(traj.frames))
println("Last frame: ", last(traj.frames))
println("3D data: ", traj.z !== nothing)

# Access positions
for i in 1:length(traj.frames)
    frame = traj.frames[i]
    x = traj.x[i]
    y = traj.y[i]
    z = traj.z !== nothing ? traj.z[i] : NaN
    println("Frame $frame: ($x, $y, $z) μm")
end
```

## Error Handling

### Common Issues

**File not found**:
```julia
# Will throw error if file doesn't exist
tracks = load_tracks(SmiteFormat(), "nonexistent.mat")
# ERROR: SystemError: opening file "nonexistent.mat"
```

**Variable not found**:
```julia
# Will throw error if variable name is wrong
tracks = load_tracks(SmiteFormat(), "data.mat", varname="WrongName")
# ERROR: Variable 'WrongName' not found in data.mat
```

**Invalid data structure**:
```julia
# Will throw error if required fields are missing
tracks = load_tracks(BNPTrackFormat(), "invalid.mat")
# ERROR: Invalid BNP-Track chain structure: missing 'params' or 'sample'
```

### Warnings

**SMITE complex fields**:
```julia
# Warns if complex-valued data is found and removed
tracks = load_tracks(SmiteFormat(), "data_with_complex.mat")
# WARNING: Found 15 emitters with non-zero imaginary components. These will be excluded.
```

**Empty tracks**:
```julia
# Warns if no active particles found
tracks = load_tracks(BNPTrackFormat(), "empty_chain.mat")
# WARNING: No active particles found in BNP-Track output
```

## Module Structure

```
src/io/
├── IO.jl           # Module file with exports
├── formats.jl      # Format type tags (SmiteFormat, UTrackFormat, BNPTrackFormat)
├── loaders.jl      # load_tracks() implementations with multiple dispatch
└── README.md       # This file
```

## Extending the Module

To add support for a new format:

1. Define a format type tag in `formats.jl`:
```julia
struct NewFormat end
```

2. Implement loader in `loaders.jl`:
```julia
function load_tracks(::NewFormat, filepath::String; kwargs...)
    # Load data
    # Convert to Trajectory objects
    # Return Tracks object
end
```

3. Export in `IO.jl`:
```julia
export NewFormat
```

4. Document in this README

## See Also

- `src/tracking/` - Tracking evaluation metrics module
- `src/tracking/types.jl` - Trajectory and Tracks type definitions
- Main SMLMMetrics documentation for complete API reference
