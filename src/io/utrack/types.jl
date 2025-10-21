"""
u-track data structures for loading tracking results.

u-track (Jaqaman et al., Nature Methods 2008) outputs tracking data in MATLAB .mat files
with sophisticated structure arrays representing particle trajectories including gap-closing,
merging, and splitting events.
"""

using SMLMData

"""
    UTrackSMD

Specifies a u-track .mat file to load.

# Fields
- `filepath::String`: Directory containing the .mat file
- `filename::String`: Name of the .mat file
- `varname::String`: Variable name in .mat file (default: "tracksFinal")
"""
mutable struct UTrackSMD
    filepath::String
    filename::String
    varname::String
end

"""
    UTrackSMD(filepath, filename)

Create a UTrackSMD with default variable name "tracksFinal".
"""
function UTrackSMD(filepath::String, filename::String)
    return UTrackSMD(filepath, filename, "tracksFinal")
end

"""
    UTrackSMLD{T,E<:AbstractEmitter} <: SMLD

Container for u-track tracking data converted to SMLMData format.

# Fields
- `emitters::Vector{E}`: Vector of emitters (Emitter2DFit or Emitter3DFit)
- `camera::AbstractCamera`: Camera information
- `n_frames::Int`: Total number of frames
- `n_datasets::Int`: Number of datasets (typically 1)
- `metadata::Dict{String,Any}`: Additional metadata from u-track output
"""
struct UTrackSMLD{T,E<:AbstractEmitter} <: SMLD
    emitters::Vector{E}
    camera::AbstractCamera
    n_frames::Int
    n_datasets::Int
    metadata::Dict{String,Any}
end
