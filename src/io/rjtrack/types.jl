"""
RJTrack Integration Types

Types for loading data from RJTrack.jl package and converting to SMLMData format.
"""

"""
    RJTrackState

Specification for loading tracking data from RJTrack.jl TrackingState format.

# Fields
- `tracking_state`: RJTrack.TrackingState object (ground truth or inferred)
- `pixel_size::Float64`: Pixel size in microns
- `is_3d::Bool`: Whether data is 3D

# Example
```julia
using RJTrack
using SMLMMetrics

# Generate synthetic data with RJTrack
gt_state, images, camera, psf, stats = run_simulation()

# Convert to SMLMData format for metrics
rj_spec = RJTrackState(gt_state, pixel_size=0.1, is_3d=false)
smld = load_rjtrack_2d(rj_spec)

# Now use with SMLMMetrics
jaccard_score = jaccard(smld, other_result, [50.0, 50.0])
```
"""
mutable struct RJTrackState
    tracking_state::Any  # RJTrack.TrackingState
    pixel_size::Float64
    is_3d::Bool

    function RJTrackState(tracking_state; pixel_size::Float64=0.1, is_3d::Bool=false)
        new(tracking_state, pixel_size, is_3d)
    end
end

"""
    RJTrackSMLD{T,E} <: SMLD

SMLD container for data loaded from RJTrack.jl.

# Fields
- `emitters::Vector{E}`: Vector of emitter fits (Emitter2DFit or Emitter3DFit)
- `camera::AbstractCamera`: Camera model
- `n_frames::Int`: Total number of frames
- `n_datasets::Int`: Number of datasets (typically 1)
- `metadata::Dict{String,Any}`: Additional metadata

# Metadata Contents
- `"source"`: "RJTrack.jl"
- `"method"`: "Synthetic Ground Truth" or "RJMCMC Inference"
- `"pixel_size"`: Pixel size in microns
- `"n_tracks"`: Number of trajectories
- `"n_detections"`: Total number of detections
- `"frame_range"`: (min_frame, max_frame)
- `"diffusion_coef"`: Diffusion coefficient (if available)
- `"background"`: Background per frame (if available)
"""
struct RJTrackSMLD{T,E<:AbstractEmitter} <: SMLD
    emitters::Vector{E}
    camera::AbstractCamera
    n_frames::Int
    n_datasets::Int
    metadata::Dict{String,Any}
end
