# Track-level Jaccard similarity coefficient (JSCθ)
# Based on "Objective comparison of particle tracking methods" (Nature Methods 2014)

"""
    jaccard_tracks(a::Array{<:Real}, b::Array{<:Real}, cutoff::Vector{<:Real})

Calculate track-level Jaccard similarity coefficient: JSCθ = TPθ/(TPθ + FNθ + FPθ)

The track-level Jaccard coefficient evaluates tracking performance at the trajectory level
rather than individual detection level, providing insight into track continuity and linking quality.

# Arguments
- `a` and `b` are `d` x `n` and `d` x `m` arrays, where `d` is the number of dimensions
- `cutoff` contains the maximum matching distance for each dimension

# Returns
- `Float64`: Track-level Jaccard index in range [0, 1], where 1 indicates perfect tracking

# Details
The track-level Jaccard coefficient is defined as JSCθ = TPθ/(TPθ + FNθ + FPθ), where:
- TPθ: Number of estimated tracks paired with ground-truth tracks
- FNθ: Number of ground-truth tracks without corresponding estimated tracks (dummy tracks)
- FPθ: Number of spurious estimated tracks (not paired with ground truth)

This differs from the point-level Jaccard (JSC) by evaluating entire track associations
rather than individual point matches, making it more sensitive to track fragmentation
and false track creation.

# Note
This simplified implementation treats each point as a separate "track". For real tracking
evaluation, tracks should be grouped by trajectory ID. For RJTrack integration, use the
track-aware version that operates on trajectory objects directly.

# References
Chenouard et al., "Objective comparison of particle tracking methods", Nature Methods (2014)
"""
function jaccard_tracks(a::Array{<:Real}, b::Array{<:Real}, cutoff::Vector{<:Real})
    # Use existing match function to get optimal assignment
    assignment = match(a, b, cutoff)
    
    n_a = size(a, 2)  # Number of ground truth "tracks" (points)
    n_b = size(b, 2)  # Number of estimated "tracks" (points)
    
    # Count track-level matches
    # TPθ: Number of estimated tracks paired with ground-truth tracks
    tp_tracks = sum(assignment .> 0)
    
    # FNθ: Number of ground-truth tracks without matches (assigned to dummy)
    fn_tracks = sum(assignment .== 0)
    
    # FPθ: Number of spurious estimated tracks (not paired with any ground truth)
    matched_b_indices = Set(assignment[assignment .> 0])
    fp_tracks = n_b - length(matched_b_indices)
    
    # JSCθ = TPθ/(TPθ + FNθ + FPθ)
    total = tp_tracks + fn_tracks + fp_tracks
    return total > 0 ? tp_tracks / total : 1.0
end

"""
    jaccard_tracks_with_trajectories(tracks_a::Vector{TrajectoryType}, tracks_b::Vector{TrajectoryType}, cutoff::Vector{<:Real})

Calculate track-level Jaccard coefficient for actual trajectory objects.

This is the proper implementation for tracking evaluation that operates on trajectory objects
rather than individual points. It should be used when evaluating methods like RJTrack that
produce actual trajectory objects with temporal continuity.

# Arguments
- `tracks_a`: Vector of ground truth trajectory objects
- `tracks_b`: Vector of estimated trajectory objects  
- `cutoff`: Maximum matching distance for each dimension

# Returns
- `Float64`: Track-level Jaccard index

# Details
This function performs optimal trajectory-to-trajectory assignment using the Munkres algorithm
with gated Euclidean distance between tracks. The distance between tracks is calculated as:

d(θₖˣ, θₖᶻ) = Σₜ |θₖˣ(t) - θₖᶻ(t)|₂,ε

where |·|₂,ε = min(|·|₂, ε) is the gated Euclidean distance and ε is the gate parameter.

This implementation would need to be adapted based on the specific trajectory data structure
used (e.g., RJTrack.Trajectory objects).
"""
function jaccard_tracks_with_trajectories(tracks_a, tracks_b, cutoff::Vector{<:Real})
    # This is a template - actual implementation depends on trajectory structure
    error("jaccard_tracks_with_trajectories requires trajectory-specific implementation. " *
          "Use jaccard_tracks for point-based evaluation or implement trajectory-specific version.")
end