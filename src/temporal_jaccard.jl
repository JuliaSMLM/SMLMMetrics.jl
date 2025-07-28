"""
    temporal_jaccard.jl

Temporal Jaccard Similarity Coefficient (JSC) from Chenouard et al. (2014).
Extends spatial Jaccard index to include temporal trajectory correspondence.
"""

"""
    temporal_jaccard(true_trajectories::Vector{Trajectory}, 
                    detected_trajectories::Vector{Trajectory}, 
                    cutoff::Vector{Float64})

Calculate the temporal Jaccard Similarity Coefficient (JSC).

JSC = |T_true ∩ T_detected| / |T_true ∪ T_detected|

Trajectories are considered matching if they have consistent spatial and temporal correspondence.

# Arguments
- `true_trajectories`: Vector of true trajectories
- `detected_trajectories`: Vector of detected trajectories
- `cutoff`: Distance cutoff for matching in each dimension

# Returns
- `Float64`: Temporal Jaccard index in [0, 1], where 1 indicates perfect tracking

# Example
```julia
true_traj = [Trajectory(1, emitters1, motion_model)]
det_traj = [Trajectory(1, emitters2, motion_model)]
jsc = temporal_jaccard(true_traj, det_traj, [0.5, 0.5])
```
"""
function temporal_jaccard(true_trajectories::Vector{<:Trajectory}, 
                         detected_trajectories::Vector{<:Trajectory}, 
                         cutoff::Vector{Float64})
    if isempty(true_trajectories) && isempty(detected_trajectories)
        return 1.0
    end
    
    if isempty(true_trajectories) || isempty(detected_trajectories)
        return 0.0
    end
    
    matching = build_temporal_matching(true_trajectories, detected_trajectories, cutoff)
    
    # Count matched trajectories
    # A trajectory is considered matched if it has consistent one-to-one correspondence
    unique_matches = 0
    for (true_id, detected_ids) in matching.true_to_detected
        if length(detected_ids) == 1
            det_id = detected_ids[1]
            if length(get(matching.detected_to_true, det_id, Int[])) == 1
                unique_matches += 1
            end
        end
    end
    
    # Jaccard = intersection / union
    total_trajectories = length(true_trajectories) + length(detected_trajectories) - unique_matches
    return unique_matches / total_trajectories
end

"""
    temporal_jaccard(matching::TemporalMatching, 
                    n_true::Int, 
                    n_detected::Int)

Calculate temporal Jaccard index from pre-computed matching.

# Arguments
- `matching`: Pre-computed temporal matching
- `n_true`: Number of true trajectories
- `n_detected`: Number of detected trajectories

# Returns
- `Float64`: Temporal Jaccard index
"""
function temporal_jaccard(matching::TemporalMatching, n_true::Int, n_detected::Int)
    if n_true == 0 && n_detected == 0
        return 1.0
    end
    
    if n_true == 0 || n_detected == 0
        return 0.0
    end
    
    # Count unique one-to-one matches
    unique_matches = 0
    for (true_id, detected_ids) in matching.true_to_detected
        if length(detected_ids) == 1
            det_id = detected_ids[1]
            if length(get(matching.detected_to_true, det_id, Int[])) == 1
                unique_matches += 1
            end
        end
    end
    
    total_trajectories = n_true + n_detected - unique_matches
    return unique_matches / total_trajectories
end