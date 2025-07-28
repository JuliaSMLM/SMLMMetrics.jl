"""
    temporal_rmse.jl

Temporal Root Mean Square Error (RMSE) from Chenouard et al. (2014).
Computes positional error between estimated and ground truth particle positions across trajectories.
"""

"""
    temporal_rmse(true_trajectories::Vector{Trajectory}, 
                 detected_trajectories::Vector{Trajectory}, 
                 cutoff::Vector{Float64},
                 α::Vector{Float64} = [1e-2, 1e-2])

Calculate the temporal RMSE across all matched trajectory points.

RMSE = sqrt((1/N_total) * Σ ||p_true - p_detected||²)

where the sum is over all matched position pairs across all trajectories.

# Arguments
- `true_trajectories`: Vector of true trajectories
- `detected_trajectories`: Vector of detected trajectories
- `cutoff`: Distance cutoff for matching in each dimension
- `α`: Dimensional weighting parameters (default: [1e-2, 1e-2] nm⁻¹)

# Returns
- `Float64`: Weighted RMSE value

# Example
```julia
true_traj = [Trajectory(1, emitters1, motion_model)]
det_traj = [Trajectory(1, emitters2, motion_model)]
rmse = temporal_rmse(true_traj, det_traj, [0.5, 0.5], [1e-2, 1e-2])
```
"""
function temporal_rmse(true_trajectories::Vector{<:Trajectory}, 
                      detected_trajectories::Vector{<:Trajectory}, 
                      cutoff::Vector{Float64},
                      α::Vector{Float64} = [1e-2, 1e-2])
    matching = build_temporal_matching(true_trajectories, detected_trajectories, cutoff)
    
    total_error = 0.0
    n_matches = 0
    
    # Iterate through all frames
    for (frame, frame_corr) in matching.frame_correspondences
        # Get positions for this frame
        true_positions = Dict{Int, Vector{Float64}}()
        for traj in true_trajectories
            for emitter in traj.emitters
                if emitter.frame == frame
                    true_positions[traj.id] = [emitter.x, emitter.y]
                end
            end
        end
        
        detected_positions = Dict{Int, Vector{Float64}}()
        for traj in detected_trajectories
            for emitter in traj.emitters
                if emitter.frame == frame
                    detected_positions[traj.id] = [emitter.x, emitter.y]
                end
            end
        end
        
        # Calculate errors for matched pairs
        for (true_id, det_id) in frame_corr
            if haskey(true_positions, true_id) && haskey(detected_positions, det_id)
                true_pos = true_positions[true_id]
                det_pos = detected_positions[det_id]
                
                # Weighted squared error
                error = sum((α[i] * (true_pos[i] - det_pos[i]))^2 for i in 1:2)
                total_error += error
                n_matches += 1
            end
        end
    end
    
    if n_matches == 0
        return 0.0
    end
    
    return sqrt(total_error / n_matches / 2)  # Divide by 2 for dimension normalization
end

"""
    temporal_rmse(matching::TemporalMatching,
                 true_trajectories::Vector{Trajectory}, 
                 detected_trajectories::Vector{Trajectory},
                 α::Vector{Float64} = [1e-2, 1e-2])

Calculate temporal RMSE from pre-computed matching.

# Arguments
- `matching`: Pre-computed temporal matching
- `true_trajectories`: Vector of true trajectories
- `detected_trajectories`: Vector of detected trajectories
- `α`: Dimensional weighting parameters

# Returns
- `Float64`: Weighted RMSE value
"""
function temporal_rmse(matching::TemporalMatching,
                      true_trajectories::Vector{<:Trajectory}, 
                      detected_trajectories::Vector{<:Trajectory},
                      α::Vector{Float64} = [1e-2, 1e-2])
    total_error = 0.0
    n_matches = 0
    
    # Build position lookup tables for efficiency
    true_pos_lookup = Dict{Tuple{Int,Int}, Vector{Float64}}()
    for traj in true_trajectories
        for emitter in traj.emitters
            true_pos_lookup[(traj.id, emitter.frame)] = [emitter.x, emitter.y]
        end
    end
    
    detected_pos_lookup = Dict{Tuple{Int,Int}, Vector{Float64}}()
    for traj in detected_trajectories
        for emitter in traj.emitters
            detected_pos_lookup[(traj.id, emitter.frame)] = [emitter.x, emitter.y]
        end
    end
    
    # Calculate errors for all matched pairs
    for (frame, frame_corr) in matching.frame_correspondences
        for (true_id, det_id) in frame_corr
            true_key = (true_id, frame)
            det_key = (det_id, frame)
            
            if haskey(true_pos_lookup, true_key) && haskey(detected_pos_lookup, det_key)
                true_pos = true_pos_lookup[true_key]
                det_pos = detected_pos_lookup[det_key]
                
                # Weighted squared error
                error = sum((α[i] * (true_pos[i] - det_pos[i]))^2 for i in 1:2)
                total_error += error
                n_matches += 1
            end
        end
    end
    
    if n_matches == 0
        return 0.0
    end
    
    return sqrt(total_error / n_matches / 2)
end