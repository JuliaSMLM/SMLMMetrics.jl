"""
Particle Tracking Challenge data structures for loading ground truth.

The Particle Tracking Challenge (Chenouard et al., Nature Methods 2014) provides
standard benchmark datasets with ground truth for evaluating particle tracking algorithms.

Reference: http://bioimageanalysis.org/track/
Paper: Chenouard et al., Nature Methods, vol. 11, no. 3, pp. 281-289, March 2014
"""

using SMLMData

"""
    TrackingChallengeGT

Specifies a Particle Tracking Challenge ground truth XML file to load.

# Fields
- `filepath::String`: Directory containing the XML file
- `filename::String`: Name of the XML file
- `pixel_size::Float64`: Pixel size in microns (default: 0.1 μm)
- `is_3d::Bool`: Whether the data is 3D (default: false for 2D)
"""
mutable struct TrackingChallengeGT
    filepath::String
    filename::String
    pixel_size::Float64
    is_3d::Bool
end

"""
    TrackingChallengeGT(filepath, filename; pixel_size=0.1, is_3d=false)

Create a TrackingChallengeGT with specified parameters.
"""
function TrackingChallengeGT(filepath::String, filename::String;
                            pixel_size::Float64=0.1,
                            is_3d::Bool=false)
    return TrackingChallengeGT(filepath, filename, pixel_size, is_3d)
end

"""
    ChallengeSMLD{T,E<:AbstractEmitter} <: SMLD

Container for Particle Tracking Challenge ground truth converted to SMLMData format.

# Fields
- `emitters::Vector{E}`: Vector of emitters (Emitter2DFit or Emitter3DFit)
- `camera::AbstractCamera`: Camera information
- `n_frames::Int`: Total number of frames
- `n_datasets::Int`: Number of datasets (typically 1)
- `metadata::Dict{String,Any}`: Additional metadata including challenge scenario info
"""
struct ChallengeSMLD{T,E<:AbstractEmitter} <: SMLD
    emitters::Vector{E}
    camera::AbstractCamera
    n_frames::Int
    n_datasets::Int
    metadata::Dict{String,Any}
end
