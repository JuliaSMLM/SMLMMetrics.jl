"""
BNP-Track data structures for loading tracking results.

BNP-Track (Bayesian Nonparametric Track) from LabPresse outputs tracking data
in MATLAB .mat files containing MCMC chain samples with posterior distributions.

Reference: https://www.nature.com/articles/s41592-024-02349-9
Repository: https://github.com/LabPresse/BNP-Track
"""

using SMLMData

"""
    BNPTrackSMD

Specifies a BNP-Track .mat file to load.

# Fields
- `filepath::String`: Directory containing the .mat file
- `filename::String`: Name of the .mat file
- `varname::String`: Variable name in .mat file (default: "chain")
"""
mutable struct BNPTrackSMD
    filepath::String
    filename::String
    varname::String
end

"""
    BNPTrackSMD(filepath, filename)

Create a BNPTrackSMD with default variable name "chain".
"""
function BNPTrackSMD(filepath::String, filename::String)
    return BNPTrackSMD(filepath, filename, "chain")
end

"""
    BNPTrackSMLD{T,E<:AbstractEmitter} <: SMLD

Container for BNP-Track tracking data converted to SMLMData format.

# Fields
- `emitters::Vector{E}`: Vector of emitters (Emitter2DFit or Emitter3DFit)
- `camera::AbstractCamera`: Camera information
- `n_frames::Int`: Total number of frames
- `n_datasets::Int`: Number of datasets (typically 1)
- `metadata::Dict{String,Any}`: Additional metadata including posterior statistics
"""
struct BNPTrackSMLD{T,E<:AbstractEmitter} <: SMLD
    emitters::Vector{E}
    camera::AbstractCamera
    n_frames::Int
    n_datasets::Int
    metadata::Dict{String,Any}
end
