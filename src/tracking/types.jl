"""
    Trajectory

A temporal series of spatial positions representing a single particle's path.

# Fields
- `id::Int`: Unique particle identifier
- `frames::Vector{Int}`: Frame numbers where particle is detected (1-indexed, Julia standard)
- `x::Vector{Float64}`: X coordinates (μm)
- `y::Vector{Float64}`: Y coordinates (μm)
- `z::Union{Vector{Float64}, Nothing}`: Z coordinates for 3D data (μm), or nothing for 2D
- `dt::Float64`: Time between frames (seconds)

# Notes
- All vectors (frames, x, y, z) must have the same length
- Frames must be sorted in ascending order
- Missing frames represent gaps in the trajectory (e.g., [1, 2, 4, 5] has a gap at frame 3)
- For 2D trajectories, z should be `nothing`
- For 3D trajectories, z must be a Vector{Float64} of the same length as x and y
- Coordinates are in physical units (μm), not pixels

# Examples
```julia
# 2D trajectory
traj_2d = Trajectory(
    id=1,
    frames=[1, 2, 3, 4],
    x=[0.0, 1.0, 2.0, 3.0],
    y=[0.0, 1.0, 2.0, 3.0],
    z=nothing,
    dt=0.01
)

# 3D trajectory with a gap at frame 3
traj_3d = Trajectory(
    id=2,
    frames=[1, 2, 4, 5],
    x=[0.0, 1.0, 3.0, 4.0],
    y=[0.0, 1.0, 3.0, 4.0],
    z=[0.0, 0.5, 1.5, 2.0],
    dt=0.01
)
```
"""
struct Trajectory
    id::Int
    frames::Vector{Int}
    x::Vector{Float64}
    y::Vector{Float64}
    z::Union{Vector{Float64}, Nothing}
    dt::Float64

    function Trajectory(id::Int, frames::Vector{Int}, x::Vector{Float64},
                       y::Vector{Float64}, z::Union{Vector{Float64}, Nothing}, dt::Float64)
        # Validate non-empty
        if isempty(frames)
            error("Trajectory must have at least one position")
        end

        # Validate lengths match
        n = length(frames)
        if length(x) != n || length(y) != n
            error("frames, x, and y must have the same length")
        end

        # Validate z if provided
        if !isnothing(z) && length(z) != n
            error("z must have the same length as x and y, or be nothing")
        end

        # Validate frames are sorted
        if !issorted(frames)
            error("frames must be sorted in ascending order")
        end

        # Validate positive dt
        if dt <= 0
            error("dt must be positive")
        end

        new(id, frames, x, y, z, dt)
    end
end

"""
    Trajectory(; id, frames, x, y, z=nothing, dt)

Convenience constructor for Trajectory using keyword arguments.
"""
function Trajectory(; id::Int, frames::Vector{Int}, x::Vector{Float64},
                    y::Vector{Float64}, z::Union{Vector{Float64}, Nothing}=nothing, dt::Float64)
    return Trajectory(id, frames, x, y, z, dt)
end

"""
    Tracks

Container for a collection of trajectories from a tracking dataset.

# Fields
- `trajectories::Vector{Trajectory}`: Vector of individual particle trajectories
- `frame_range::Tuple{Int,Int}`: (min_frame, max_frame) in the dataset
- `metadata::Dict{String,Any}`: Flexible storage for additional dataset information

# Notes
- `frame_range` defines the temporal extent of the entire dataset
- Individual trajectories may span only part of this range
- All coordinates in trajectories are in physical units (μm), not pixels
- Use metadata to store additional information like pixel_size, source, experiment name, etc.

# Example
```julia
trajs = [
    Trajectory(id=1, frames=[1,2,3], x=[0.0,1.0,2.0], y=[0.0,1.0,2.0], z=nothing, dt=0.01),
    Trajectory(id=2, frames=[2,3,4], x=[5.0,6.0,7.0], y=[5.0,6.0,7.0], z=nothing, dt=0.01)
]

tracks = Tracks(
    trajectories=trajs,
    frame_range=(1, 4),
    metadata=Dict("source" => "SMITE", "experiment" => "test1", "pixel_size" => 0.1)
)
```
"""
struct Tracks
    trajectories::Vector{Trajectory}
    frame_range::Tuple{Int,Int}
    metadata::Dict{String,Any}

    function Tracks(trajectories::Vector{Trajectory}, frame_range::Tuple{Int,Int},
                   metadata::Dict{String,Any})
        # Validate frame_range
        if frame_range[1] > frame_range[2]
            error("frame_range must be (min, max) with min <= max")
        end

        new(trajectories, frame_range, metadata)
    end
end

"""
    Tracks(; trajectories, frame_range, metadata=Dict{String,Any}())

Convenience constructor for Tracks using keyword arguments.
"""
function Tracks(; trajectories::Vector{Trajectory}, frame_range::Tuple{Int,Int},
               metadata::Dict{String,Any}=Dict{String,Any}())
    return Tracks(trajectories, frame_range, metadata)
end

# ============================================================================
# Utility functions for Trajectory
# ============================================================================

"""
    is_3d(traj::Trajectory)

Check if a trajectory is 3D (has z coordinates).
"""
function is_3d(traj::Trajectory)
    return !isnothing(traj.z)
end

"""
    dimensionality(traj::Trajectory)

Return the spatial dimensionality of the trajectory (2 or 3).
"""
function dimensionality(traj::Trajectory)
    return is_3d(traj) ? 3 : 2
end

"""
    has_position(traj::Trajectory, frame::Int)

Check if a trajectory has a position at the given frame number.
"""
function has_position(traj::Trajectory, frame::Int)
    return frame in traj.frames
end

"""
    get_position(traj::Trajectory, frame::Int)

Get the position at the given frame, or nothing if not present.

Returns a Vector{Float64} of length 2 (2D) or 3 (3D), or nothing if the frame is not in the trajectory.
"""
function get_position(traj::Trajectory, frame::Int)
    idx = findfirst(==(frame), traj.frames)

    if isnothing(idx)
        return nothing
    end

    if is_3d(traj)
        return [traj.x[idx], traj.y[idx], traj.z[idx]]
    else
        return [traj.x[idx], traj.y[idx]]
    end
end

"""
    temporal_extent(traj::Trajectory)

Return the (start_frame, end_frame) tuple for the trajectory.
"""
function temporal_extent(traj::Trajectory)
    return (minimum(traj.frames), maximum(traj.frames))
end

"""
    temporal_length(traj::Trajectory)

Return the temporal extent of the trajectory (end_frame - start_frame + 1).
This includes gaps within the trajectory.
"""
function temporal_length(traj::Trajectory)
    start_frame, end_frame = temporal_extent(traj)
    return end_frame - start_frame + 1
end

"""
    num_positions(traj::Trajectory)

Return the number of actual positions in the trajectory (excludes gaps).
"""
function num_positions(traj::Trajectory)
    return length(traj.frames)
end

"""
    num_gaps(traj::Trajectory)

Return the number of missing frames (gaps) within the trajectory's temporal extent.
"""
function num_gaps(traj::Trajectory)
    return temporal_length(traj) - num_positions(traj)
end

"""
    is_dummy_trajectory(traj::Union{Trajectory, Nothing})

Check if a trajectory is a dummy trajectory (represented as nothing).
Used internally for track pairing algorithms.
"""
function is_dummy_trajectory(traj::Union{Trajectory, Nothing})
    return traj === nothing
end

# ============================================================================
# Utility functions for Tracks
# ============================================================================

"""
    num_trajectories(tracks::Tracks)

Return the number of trajectories in the dataset.
"""
function num_trajectories(tracks::Tracks)
    return length(tracks.trajectories)
end

"""
    num_frames(tracks::Tracks)

Return the total number of frames in the dataset.
"""
function num_frames(tracks::Tracks)
    return tracks.frame_range[2] - tracks.frame_range[1] + 1
end

"""
    is_3d(tracks::Tracks)

Check if the dataset contains 3D trajectories.
Returns true if any trajectory has z coordinates.
"""
function is_3d(tracks::Tracks)
    return any(is_3d, tracks.trajectories)
end

"""
    total_positions(tracks::Tracks)

Return the total number of positions across all trajectories.
"""
function total_positions(tracks::Tracks)
    return sum(num_positions, tracks.trajectories)
end
