"""
Input/Output module for converting tracking package outputs to SMLMData format.

This module provides converters for popular particle tracking packages:
- **SMITE**: Single Molecule Imaging Toolbox Extraordinaire (LidkeLab)
- **u-track**: Particle tracking software (DanuserLab)
- **BNP-Track**: Bayesian Nonparametric Tracking (LabPresse)

All converters transform tracking results into SMLMData types (SMLD) containing
Emitter2DFit or Emitter3DFit objects, making them compatible with SMLMMetrics
evaluation functions.

# Usage Example

```julia
using SMLMMetrics

# Load ground truth
ground_truth = load_smite_2d(SmiteSMD("data/", "ground_truth.mat"))

# Load tracking results from different packages
smite_results = load_smite_2d(SmiteSMD("results/", "smite_tracks.mat"))
utrack_results = load_utrack_2d(UTrackSMD("results/", "utrack_tracks.mat"))
bnp_results = load_bnptrack_2d(BNPTrackSMD("results/", "bnp_chain.mat"))

# Compare using metrics
cutoff = [50.0, 50.0]  # 50 nm
jsc_smite = jaccard(ground_truth, smite_results, cutoff)
jsc_utrack = jaccard(ground_truth, utrack_results, cutoff)
jsc_bnp = jaccard(ground_truth, bnp_results, cutoff)
```

# Exported Types
- `SmiteSMD`, `SmiteSMLD`: SMITE data structures
- `UTrackSMD`, `UTrackSMLD`: u-track data structures
- `BNPTrackSMD`, `BNPTrackSMLD`: BNP-Track data structures

# Exported Functions
- `load_smite_2d`, `load_smite_3d`: Load SMITE 2D/3D tracking data
- `load_utrack_2d`, `load_utrack_3d`: Load u-track 2D/3D tracking data
- `load_bnptrack_2d`, `load_bnptrack_3d`: Load BNP-Track 2D/3D tracking data
"""

# SMITE converter
include("smite/types.jl")
include("smite/loading.jl")

# u-track converter
include("utrack/types.jl")
include("utrack/loading.jl")

# BNP-Track converter
include("bnptrack/types.jl")
include("bnptrack/loading.jl")

# Particle Tracking Challenge ground truth loader
include("challenge/types.jl")
include("challenge/loading.jl")

# Export SMITE types and functions
export SmiteSMD, SmiteSMLD
export load_smite_2d, load_smite_3d

# Export u-track types and functions
export UTrackSMD, UTrackSMLD
export load_utrack_2d, load_utrack_3d

# Export BNP-Track types and functions
export BNPTrackSMD, BNPTrackSMLD
export load_bnptrack_2d, load_bnptrack_3d

# Export Particle Tracking Challenge types and functions
export TrackingChallengeGT, ChallengeSMLD
export load_challenge_gt, load_challenge_gt_2d, load_challenge_gt_3d
