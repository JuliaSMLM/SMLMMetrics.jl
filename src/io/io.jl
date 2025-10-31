"""
Input/Output module for loading particle tracking data.

This module provides a unified interface for loading tracking data from various packages:
- **SMITE**: Single Molecule Imaging Toolbox Extraordinaire (LidkeLab)
- **u-track**: Particle tracking software (DanuserLab)
- **BNP-Track**: Bayesian Nonparametric Tracking (LabPresse)
- **Particle Tracking Challenge**: Ground truth XML format

All loaders use multiple dispatch on format type tags and return Tracks objects
containing Trajectory data.

# Usage Example

```julia
using SMLMMetrics

# Load ground truth from Particle Tracking Challenge XML
gt_tracks = load_tracks(ChallengeFormat(), "data/ground_truth.xml", pixel_size=0.107)

# Load SMITE tracking results
smite_tracks = load_tracks(SmiteFormat(), "results/smite_tracks.mat")

# Compare using metrics
metrics = evaluate_tracking(gt_tracks, smite_tracks)
println("JSC: ", metrics.JSC)
println("α: ", metrics.α)
```

# Exported Types
- `SmiteFormat`: Format tag for SMITE data
- `UTrackFormat`: Format tag for u-track data
- `BNPTrackFormat`: Format tag for BNP-Track data
- `ChallengeFormat`: Format tag for Particle Tracking Challenge XML

# Exported Functions
- `load_tracks(format, filepath; kwargs...)`: Unified loading function with multiple dispatch
"""
module IO

# Include format type definitions
include("formats.jl")

# Include unified loaders
include("loaders.jl")

# Export format types
export SmiteFormat, UTrackFormat, BNPTrackFormat, ChallengeFormat

# Export main loading function
export load_tracks

end # module
