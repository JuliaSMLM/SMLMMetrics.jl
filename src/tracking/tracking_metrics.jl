using LinearAlgebra
using Statistics

"""
    TrackingMetrics

Results of tracking performance evaluation.

# Fields
## Primary Performance Measures (14 measures from Chenouard et al. 2014)
- `α::Float64`: Overall quality measure (0-1, higher is better)
- `β::Float64`: Quality measure penalizing spurious tracks (0-1, higher is better)
- `JSC::Float64`: Jaccard similarity coefficient for positions (0-1, higher is better)
- `JSC_θ::Float64`: Jaccard similarity coefficient for tracks (0-1, higher is better)
- `RMSE::Float64`: Root mean square error of localization (lower is better)
- `RMSE_θ::Float64`: Track-averaged RMSE (lower is better)
- `min_error::Float64`: Minimum localization error (lower is better)
- `max_error::Float64`: Maximum localization error (lower is better)

## Supporting Counts
- `TP::Int`: True positive positions
- `FN::Int`: False negative positions
- `FP::Int`: False positive positions
- `TP_θ::Int`: True positive tracks
- `FN_θ::Int`: False negative tracks
- `FP_θ::Int`: False positive tracks

# Reference
Supplementary Note 3, "Performance Measures" section
Chenouard et al., Nature Methods 11, 281-289 (2014)
"""
struct TrackingMetrics
    # The primary performance measures
    α::Float64
    β::Float64
    JSC::Float64
    JSC_θ::Float64
    RMSE::Float64
    RMSE_θ::Float64
    min_error::Float64
    max_error::Float64

    # Supporting counts
    TP::Int
    FN::Int
    FP::Int
    TP_θ::Int
    FN_θ::Int
    FP_θ::Int
end

function Base.show(io::IO, m::TrackingMetrics)
    r(x) = round(x; digits=4)
    println(io, "TrackingMetrics:")
    println(io, "  Quality:  α = $(r(m.α)),  β = $(r(m.β))")
    println(io, "  Jaccard:  JSC = $(r(m.JSC)),  JSC_θ = $(r(m.JSC_θ))")
    println(io, "  RMSE:     overall = $(r(m.RMSE)),  per-track = $(r(m.RMSE_θ))")
    println(io, "            min = $(r(m.min_error)),  max = $(r(m.max_error))")
    println(io, "  Counts:   TP = $(m.TP),  FN = $(m.FN),  FP = $(m.FP)")
    print(io,   "  Tracks:   TP_θ = $(m.TP_θ),  FN_θ = $(m.FN_θ),  FP_θ = $(m.FP_θ)")
end

"""
    positions_match(pos1, pos2, gate)

Check if two positions are considered matching.

Two positions match if:
- Both are non-dummy (not nothing)
- Their Euclidean distance is strictly less than gate

# Reference
Supplementary Note 3, page 4: "positions at time t... are counted as matching if they are
both non-dummy and ||θ₁ᵡ(t) - θ₂ᶻ*(t)||₂ < ε"
"""
function positions_match(pos1::Union{Vector{Float64}, Nothing},
                        pos2::Union{Vector{Float64}, Nothing},
                        gate::Float64)
    if isnothing(pos1) || isnothing(pos2)
        return false
    end

    # Handle mixed 2D/3D by comparing only XY coordinates
    n1 = length(pos1)
    n2 = length(pos2)

    if n1 == n2
        return norm(pos1 - pos2) < gate
    else
        # Mixed 2D/3D - compare only XY
        return norm(pos1[1:2] - pos2[1:2]) < gate
    end
end

"""
    compute_position_metrics(pairing)

Compute position-level metrics: TP, FN, FP, JSC, RMSE, RMSE_θ, min_error, max_error.

# Arguments
- `pairing::TrackPairing`: The optimal track pairing

# Returns
- `Tuple{Int, Int, Int, Float64, Float64, Float64, Float64, Float64}`:
  (TP, FN, FP, JSC, RMSE, RMSE_θ, min_error, max_error)

# Algorithm
For each paired track (X, Z*):
- TP: Number of matching positions (both non-dummy and distance < gate)
- FN: Number of GT positions paired with dummy positions in Z*
- FP: Number of positions in spurious tracks + non-matching positions in Z*
- JSC: TP / (TP + FN + FP)
- RMSE: sqrt(sum of squared errors in TP positions / TP)
- RMSE_θ: Average of per-track RMSE values
- min_error: Minimum error among all matched positions
- max_error: Maximum error among all matched positions

# Reference
Supplementary Note 3, measures 3-6, 11-13
"""
function compute_position_metrics(pairing::TrackPairing)
    TP = 0
    FN = 0
    FP = 0
    squared_errors = Float64[]
    errors = Float64[]  # For min/max
    per_track_squared_errors = Vector{Float64}[]  # For RMSE_θ

    # Process paired tracks
    for (gt_idx, est_idx) in enumerate(pairing.assignment)
        gt_track = pairing.gt_tracks[gt_idx]

        if est_idx == 0
            # GT track paired with dummy → all GT positions are FN
            FN += num_positions(gt_track)
        else
            # GT track paired with real EST track
            est_track = pairing.est_tracks[est_idx]
            track_squared_errors = Float64[]

            # Check each time point
            for frame in pairing.frame_start:pairing.frame_end
                gt_pos = get_position(gt_track, frame)
                est_pos = get_position(est_track, frame)

                if isnothing(gt_pos) && isnothing(est_pos)
                    # Both dummy → not counted
                    continue
                elseif isnothing(gt_pos) && !isnothing(est_pos)
                    # EST position without GT → FP
                    FP += 1
                elseif !isnothing(gt_pos) && isnothing(est_pos)
                    # GT position without EST → FN
                    FN += 1
                else
                    # Both present → check if matching
                    if positions_match(gt_pos, est_pos, pairing.gate)
                        # Matching → TP
                        TP += 1
                        # Handle mixed 2D/3D by comparing only XY
                        n1 = length(gt_pos)
                        n2 = length(est_pos)
                        if n1 == n2
                            error = norm(gt_pos - est_pos)
                        else
                            error = norm(gt_pos[1:2] - est_pos[1:2])
                        end
                        squared_error = error^2
                        push!(squared_errors, squared_error)
                        push!(errors, error)
                        push!(track_squared_errors, squared_error)
                    else
                        # Non-matching → FN + FP
                        FN += 1
                        FP += 1
                    end
                end
            end

            # Store per-track errors if any matches in this track
            if !isempty(track_squared_errors)
                push!(per_track_squared_errors, track_squared_errors)
            end
        end
    end

    # Add positions from spurious tracks to FP
    spurious_indices = get_spurious_tracks(pairing)
    for idx in spurious_indices
        FP += num_positions(pairing.est_tracks[idx])
    end

    # Compute JSC
    JSC = if (TP + FN + FP) > 0
        TP / (TP + FN + FP)
    else
        0.0
    end

    # Compute RMSE (overall)
    RMSE = if TP > 0
        sqrt(sum(squared_errors) / TP)
    else
        0.0
    end

    # Compute RMSE_θ (track-averaged RMSE)
    RMSE_θ = if !isempty(per_track_squared_errors)
        # Calculate RMSE for each track, then average
        track_rmses = [sqrt(mean(track_errs)) for track_errs in per_track_squared_errors]
        mean(track_rmses)
    else
        0.0
    end

    # Compute min and max errors
    min_error = if !isempty(errors)
        minimum(errors)
    else
        0.0
    end

    max_error = if !isempty(errors)
        maximum(errors)
    else
        0.0
    end

    return (TP, FN, FP, JSC, RMSE, RMSE_θ, min_error, max_error)
end

"""
    compute_track_metrics(pairing)

Compute track-level metrics: TP_θ, FN_θ, FP_θ, JSC_θ.

# Arguments
- `pairing::TrackPairing`: The optimal track pairing

# Returns
- `Tuple{Int, Int, Int, Float64}`: (TP_θ, FN_θ, FP_θ, JSC_θ)

# Algorithm
- TP_θ: Number of non-dummy tracks in Z* (GT tracks paired with real EST tracks)
- FN_θ: Number of dummy tracks in Z* (GT tracks paired with dummy)
- FP_θ: Number of spurious tracks (EST tracks not in Z*)
- JSC_θ: TP_θ / (TP_θ + FN_θ + FP_θ)

# Reference
Supplementary Note 3, measures 7-10
"""
function compute_track_metrics(pairing::TrackPairing)
    n_gt = length(pairing.gt_tracks)
    spurious_indices = get_spurious_tracks(pairing)

    # Count non-dummy and dummy pairings
    TP_θ = count(x -> x > 0, pairing.assignment)
    FN_θ = count(x -> x == 0, pairing.assignment)
    FP_θ = length(spurious_indices)

    # Compute JSC_θ
    JSC_θ = if (TP_θ + FN_θ + FP_θ) > 0
        TP_θ / (TP_θ + FN_θ + FP_θ)
    else
        0.0
    end

    return (TP_θ, FN_θ, FP_θ, JSC_θ)
end

"""
    compute_alpha(pairing)

Compute the α measure: overall quality of best pairing.

# Arguments
- `pairing::TrackPairing`: The optimal track pairing

# Returns
- `Float64`: α measure (0-1, higher is better)

# Algorithm
α(X,Y) = 1 - d(X,Y) / d(X,∅)

where:
- d(X,Y) is the distance of the optimal pairing
- d(X,∅) is the distance when all GT tracks are paired with dummies = |X| × T × ε

# Reference
Supplementary Note 3, measure 1
"""
function compute_alpha(pairing::TrackPairing)
    n_gt = length(pairing.gt_tracks)

    if n_gt == 0
        return 0.0
    end

    # Calculate T from frame range
    T = pairing.frame_end - pairing.frame_start + 1

    # d(X, ∅) = |X| × T × ε
    d_X_empty = n_gt * T * pairing.gate

    # d(X, Y) from optimal pairing
    # We need to compute the actual distance for real GT tracks only
    d_X_Y = 0.0
    for (i, j) in enumerate(pairing.assignment)
        if j == 0
            # Paired with dummy
            d_X_Y += T * pairing.gate
        else
            # Paired with real track
            d_X_Y += track_distance(pairing.gt_tracks[i], pairing.est_tracks[j],
                                   pairing.frame_start, pairing.frame_end, pairing.gate)
        end
    end

    α = 1.0 - d_X_Y / d_X_empty

    return α
end

"""
    compute_beta(pairing)

Compute the β measure: penalizes spurious tracks.

# Arguments
- `pairing::TrackPairing`: The optimal track pairing

# Returns
- `Float64`: β measure (0-α(X,Y), higher is better)

# Algorithm
β(X,Y) = (d(X,∅) - d(X,Y)) / (d(X,∅) + d(Ȳ,∅))

where:
- d(X,∅) = |X| × T × ε
- d(X,Y) is the optimal pairing distance
- d(Ȳ,∅) = |Ȳ| × T × ε, where Ȳ is the set of spurious tracks

# Reference
Supplementary Note 3, measure 2
"""
function compute_beta(pairing::TrackPairing)
    n_gt = length(pairing.gt_tracks)
    spurious_indices = get_spurious_tracks(pairing)
    n_spurious = length(spurious_indices)

    # Calculate T from frame range
    T = pairing.frame_end - pairing.frame_start + 1

    # d(X, ∅)
    d_X_empty = n_gt * T * pairing.gate

    # d(Ȳ, ∅)
    d_Ybar_empty = n_spurious * T * pairing.gate

    # Handle edge case
    if (d_X_empty + d_Ybar_empty) == 0.0
        return 0.0
    end

    # d(X, Y)
    d_X_Y = 0.0
    for (i, j) in enumerate(pairing.assignment)
        if j == 0
            d_X_Y += T * pairing.gate
        else
            d_X_Y += track_distance(pairing.gt_tracks[i], pairing.est_tracks[j],
                                   pairing.frame_start, pairing.frame_end, pairing.gate)
        end
    end

    β = (d_X_empty - d_X_Y) / (d_X_empty + d_Ybar_empty)

    return β
end

"""
    evaluate_tracking(gt_tracks, est_tracks; gate)

Evaluate tracking performance by comparing estimated tracks to ground truth.

# Arguments
- `gt_tracks::Tracks`: Ground truth tracking dataset
- `est_tracks::Tracks`: Estimated tracking dataset
- `gate::Float64`: Matching threshold in physical units (μm, default: 5.0)

# Returns
- `TrackingMetrics`: Structure containing all performance measures

# Performance Measures
- **α**: Overall quality (0-1, higher is better)
- **β**: Quality with spurious track penalty (0-1, higher is better)
- **JSC**: Jaccard similarity for positions (0-1, higher is better)
- **JSC_θ**: Jaccard similarity for tracks (0-1, higher is better)
- **RMSE**: Root mean square localization error (lower is better)

# Example
```julia
gt_tracks = load_tracks(ChallengeFormat(), "gt.xml")
est_tracks = load_tracks(SmiteFormat(), "results.mat")
metrics = evaluate_tracking(gt_tracks, est_tracks)
println("JSC: ", metrics.JSC)
println("RMSE: ", metrics.RMSE)
println("α: ", metrics.α)
```

# Reference
Supplementary Note 3: Performance Measures
Chenouard et al., Nature Methods 11, 281-289 (2014)
"""
function evaluate_tracking(gt_tracks::Tracks, est_tracks::Tracks;
                          gate::Float64 = DEFAULT_GATE)
    # Determine frame range (union of both datasets)
    frame_start = min(gt_tracks.frame_range[1], est_tracks.frame_range[1])
    frame_end = max(gt_tracks.frame_range[2], est_tracks.frame_range[2])

    # Compute optimal pairing
    pairing = optimal_pairing(gt_tracks.trajectories, est_tracks.trajectories,
                             frame_start, frame_end, gate)

    # Compute all metrics
    TP, FN, FP, JSC, RMSE, RMSE_θ, min_error, max_error = compute_position_metrics(pairing)
    TP_θ, FN_θ, FP_θ, JSC_θ = compute_track_metrics(pairing)
    α = compute_alpha(pairing)
    β = compute_beta(pairing)

    return TrackingMetrics(α, β, JSC, JSC_θ, RMSE, RMSE_θ, min_error, max_error,
                          TP, FN, FP, TP_θ, FN_θ, FP_θ)
end

"""
    evaluate_tracking(gt_trajectories, est_trajectories; gate, frame_range)

Evaluate tracking performance using trajectory vectors directly.

# Arguments
- `gt_trajectories::Vector{Trajectory}`: Ground truth trajectories
- `est_trajectories::Vector{Trajectory}`: Estimated trajectories
- `gate::Float64`: Matching threshold in physical units (μm, default: 5.0)
- `frame_range::Union{Tuple{Int,Int}, Nothing}`: (start, end) frames (default: auto-detect)

# Returns
- `TrackingMetrics`: Structure containing all performance measures

# Example
```julia
gt_trajs = [Trajectory(id=1, frames=[1,2,3], x=[0.0,1.0,2.0], y=[0.0,1.0,2.0], z=nothing, dt=0.01)]
est_trajs = [Trajectory(id=1, frames=[1,2,3], x=[0.1,1.1,2.1], y=[0.1,1.1,2.1], z=nothing, dt=0.01)]
metrics = evaluate_tracking(gt_trajs, est_trajs)
```
"""
function evaluate_tracking(gt_trajectories::Vector{Trajectory},
                          est_trajectories::Vector{Trajectory};
                          gate::Float64 = DEFAULT_GATE,
                          frame_range::Union{Tuple{Int,Int}, Nothing} = nothing)
    # Auto-detect frame range if not provided
    if frame_range === nothing
        frame_start = typemax(Int)
        frame_end = 0

        for traj in [gt_trajectories; est_trajectories]
            if !isempty(traj.frames)
                frame_start = min(frame_start, minimum(traj.frames))
                frame_end = max(frame_end, maximum(traj.frames))
            end
        end

        # Handle empty case
        if frame_start == typemax(Int)
            frame_start = 1
            frame_end = 1
        end
    else
        frame_start, frame_end = frame_range
    end

    # Compute optimal pairing
    pairing = optimal_pairing(gt_trajectories, est_trajectories,
                             frame_start, frame_end, gate)

    # Compute all metrics
    TP, FN, FP, JSC, RMSE, RMSE_θ, min_error, max_error = compute_position_metrics(pairing)
    TP_θ, FN_θ, FP_θ, JSC_θ = compute_track_metrics(pairing)
    α = compute_alpha(pairing)
    β = compute_beta(pairing)

    return TrackingMetrics(α, β, JSC, JSC_θ, RMSE, RMSE_θ, min_error, max_error,
                          TP, FN, FP, TP_θ, FN_θ, FP_θ)
end
