using LinearAlgebra
using Hungarian

"""
Default gate parameter (ε) in pixels, as per the paper.
"""
const DEFAULT_GATE = 5.0

"""
    gated_distance(pos1, pos2, gate)

Compute the gated Euclidean distance between two positions.

# Arguments
- `pos1::Union{Vector{Float64}, Nothing}`: First position or nothing (dummy)
- `pos2::Union{Vector{Float64}, Nothing}`: Second position or nothing (dummy)
- `gate::Float64`: Gate threshold ε

# Returns
- `Float64`: The gated distance

# Algorithm
- If both positions are dummy (nothing): distance = 0
- If one position is dummy: distance = gate (penalty)
- If both positions exist: distance = min(||pos1 - pos2||₂, gate)

# Reference
Supplementary Note 3, "Distance Between Two Tracks" section
"""
function gated_distance(pos1::Union{Vector{Float64}, Nothing},
                       pos2::Union{Vector{Float64}, Nothing},
                       gate::Float64)
    # Both dummy → 0
    if isnothing(pos1) && isnothing(pos2)
        return 0.0
    end

    # One dummy → penalty
    if isnothing(pos1) || isnothing(pos2)
        return gate
    end

    # Both present → min(euclidean, gate)
    # Handle mixed 2D/3D by only comparing XY coordinates
    n1 = length(pos1)
    n2 = length(pos2)

    if n1 == n2
        # Same dimensionality
        dist = norm(pos1 - pos2)
    else
        # Mixed 2D/3D - compare only XY (first 2 coordinates)
        dist = norm(pos1[1:2] - pos2[1:2])
    end

    return min(dist, gate)
end

"""
    track_distance(track1, track2, frame_start, frame_end, gate)

Compute the distance between two tracks over a frame range.

# Arguments
- `track1::Union{Trajectory, Nothing}`: First track or nothing (dummy)
- `track2::Union{Trajectory, Nothing}`: Second track or nothing (dummy)
- `frame_start::Int`: First frame in the sequence
- `frame_end::Int`: Last frame in the sequence
- `gate::Float64`: Gate threshold ε

# Returns
- `Float64`: Sum of gated distances over all time points

# Algorithm
Distance d(θ₁, θ₂) = Σₜ ||θ₁(t) - θ₂(t)||₂,ε for t = frame_start, ..., frame_end

# Reference
Supplementary Note 3, "Distance Between Two Tracks" section
"""
function track_distance(track1::Union{Trajectory, Nothing},
                       track2::Union{Trajectory, Nothing},
                       frame_start::Int,
                       frame_end::Int,
                       gate::Float64)
    # Both dummy → 0
    if is_dummy_trajectory(track1) && is_dummy_trajectory(track2)
        return 0.0
    end

    # Calculate total number of frames
    T = frame_end - frame_start + 1

    # One dummy → penalty for all time points
    if is_dummy_trajectory(track1) || is_dummy_trajectory(track2)
        return T * gate
    end

    # Both real tracks → sum gated distances over time
    total = 0.0
    for frame in frame_start:frame_end
        pos1 = get_position(track1, frame)
        pos2 = get_position(track2, frame)
        total += gated_distance(pos1, pos2, gate)
    end

    return total
end

"""
    TrackPairing

Structure holding the results of optimal track assignment.

# Fields
- `assignment::Vector{Int}`: For each GT track i, assignment[i] is the index of the paired EST track (0 = dummy)
- `gt_tracks::Vector{Trajectory}`: Ground truth tracks
- `est_tracks::Vector{Trajectory}`: Estimated tracks
- `frame_start::Int`: First frame in the sequence
- `frame_end::Int`: Last frame in the sequence
- `gate::Float64`: Gate parameter
- `cost_matrix::Matrix{Float64}`: The cost matrix used for assignment
- `total_cost::Float64`: Total cost of the optimal assignment
"""
struct TrackPairing
    assignment::Vector{Int}
    gt_tracks::Vector{Trajectory}
    est_tracks::Vector{Trajectory}
    frame_start::Int
    frame_end::Int
    gate::Float64
    cost_matrix::Matrix{Float64}
    total_cost::Float64
end

"""
    optimal_pairing(gt_tracks, est_tracks, frame_start, frame_end, gate)

Compute the optimal pairing between ground truth and estimated tracks.

# Arguments
- `gt_tracks::Vector{Trajectory}`: Ground truth tracks (X)
- `est_tracks::Vector{Trajectory}`: Estimated tracks (Y)
- `frame_start::Int`: First frame in the sequence
- `frame_end::Int`: Last frame in the sequence
- `gate::Float64`: Gate threshold ε

# Returns
- `TrackPairing`: Structure containing the optimal assignment

# Algorithm
1. Build cost matrix C where C[i,j] = distance between gt_track[i] and est_track[j]
2. Extend matrix to handle dummy tracks (rectangular assignment)
3. Solve assignment problem using Hungarian algorithm
4. Return the optimal pairing Z*

# Reference
Supplementary Note 3, "Distance Between Two Track Sets" section
"""
function optimal_pairing(gt_tracks::Vector{Trajectory},
                        est_tracks::Vector{Trajectory},
                        frame_start::Int,
                        frame_end::Int,
                        gate::Float64)
    n_gt = length(gt_tracks)
    n_est = length(est_tracks)
    T = frame_end - frame_start + 1

    # Handle edge cases
    if n_gt == 0 && n_est == 0
        return TrackPairing(Int[], Trajectory[], Trajectory[], frame_start, frame_end, gate,
                           Matrix{Float64}(undef, 0, 0), 0.0)
    end

    if n_gt == 0
        # No GT tracks, all EST tracks are spurious
        return TrackPairing(Int[], Trajectory[], est_tracks, frame_start, frame_end, gate,
                           Matrix{Float64}(undef, 0, 0), 0.0)
    end

    # Build rectangular cost matrix
    # Rows = GT tracks, Columns = EST tracks + dummy tracks
    n_max = max(n_gt, n_est)
    cost_matrix = zeros(n_max, n_max)

    # Fill costs for real track pairs
    for i in 1:n_gt
        for j in 1:n_est
            cost_matrix[i, j] = track_distance(gt_tracks[i], est_tracks[j], frame_start, frame_end, gate)
        end

        # Cost for pairing with dummy (beyond n_est columns)
        dummy_cost = T * gate
        for j in (n_est+1):n_max
            cost_matrix[i, j] = dummy_cost
        end
    end

    # Fill dummy rows (if n_est > n_gt)
    for i in (n_gt+1):n_max
        for j in 1:n_max
            cost_matrix[i, j] = 0.0  # Dummy GT track paired with anything has 0 cost
        end
    end

    # Solve assignment problem
    assignment_result, total_cost = hungarian(cost_matrix)

    # Extract assignment for real GT tracks only
    assignment = assignment_result[1:n_gt]

    # Mark dummy assignments (beyond n_est) as 0
    for i in 1:n_gt
        if assignment[i] > n_est
            assignment[i] = 0
        end
    end

    return TrackPairing(assignment, gt_tracks, est_tracks, frame_start, frame_end, gate,
                       cost_matrix, total_cost)
end

"""
    get_spurious_tracks(pairing)

Get the indices of spurious estimated tracks (those not paired with any GT track).

# Arguments
- `pairing::TrackPairing`: The optimal pairing

# Returns
- `Vector{Int}`: Indices of spurious tracks in est_tracks
"""
function get_spurious_tracks(pairing::TrackPairing)
    paired_est = Set(pairing.assignment)
    delete!(paired_est, 0)  # Remove dummy marker

    n_est = length(pairing.est_tracks)
    spurious = Int[]

    for j in 1:n_est
        if !(j in paired_est)
            push!(spurious, j)
        end
    end

    return spurious
end

"""
    get_paired_tracks(pairing)

Get the indices of paired tracks.

# Returns
- `Vector{Tuple{Int, Int}}`: Vector of (gt_idx, est_idx) pairs
"""
function get_paired_tracks(pairing::TrackPairing)
    pairs = Tuple{Int, Int}[]

    for (i, j) in enumerate(pairing.assignment)
        if j > 0  # Not dummy
            push!(pairs, (i, j))
        end
    end

    return pairs
end

"""
    get_dummy_paired_gt(pairing)

Get indices of GT tracks paired with dummy tracks.

# Returns
- `Vector{Int}`: Indices of GT tracks paired with dummies
"""
function get_dummy_paired_gt(pairing::TrackPairing)
    dummy_gt = Int[]

    for (i, j) in enumerate(pairing.assignment)
        if j == 0  # Paired with dummy
            push!(dummy_gt, i)
        end
    end

    return dummy_gt
end
