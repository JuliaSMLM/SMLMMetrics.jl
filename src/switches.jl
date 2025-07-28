"""
    switches.jl

Track Identity Switches (SWC) metric from Chenouard et al. (2014).
Measures instances where the identity of tracked particles switches mid-trajectory.
"""

"""
    identity_switches(frame_correspondences::Dict{Int, Dict{Int, Int}}, 
                     detected_trajectories::Vector{Trajectory})

Calculate the Track Identity Switches (SWC) metric.

SWC = Σ S_j

where S_j is the number of identity switches in detected track j.

# Arguments
- `frame_correspondences`: Frame-wise correspondence mapping
- `detected_trajectories`: Vector of detected trajectories

# Returns
- `Int`: Total number of identity switches

# Example
```julia
# Frame 1: detected track 1 matches true track 1
# Frame 2: detected track 1 matches true track 2 (switch!)
# Frame 3: detected track 1 matches true track 2 (no switch)
frame_corr = Dict(
    1 => Dict(1 => 1),
    2 => Dict(2 => 1),
    3 => Dict(2 => 1)
)
```
"""
function identity_switches(frame_correspondences::Dict{Int, Dict{Int, Int}}, 
                          detected_trajectories::Vector{<:Trajectory})
    total_switches = 0
    
    for traj in detected_trajectories
        # Get frames for this trajectory
        frames = [emitter.frame for emitter in traj.emitters]
        if length(frames) < 2
            continue
        end
        
        # Track identity changes across frames
        last_true_id = nothing
        for frame in sort(frames)
            if haskey(frame_correspondences, frame)
                frame_corr = frame_correspondences[frame]
                # Find true ID corresponding to this detected trajectory at this frame
                for (true_id, det_id) in frame_corr
                    if det_id == traj.id
                        if !isnothing(last_true_id) && true_id != last_true_id
                            total_switches += 1
                        end
                        last_true_id = true_id
                        break
                    end
                end
            end
        end
    end
    
    return total_switches
end

"""
    identity_switches(matching::TemporalMatching, detected_trajectories::Vector{Trajectory})

Calculate the Identity Switches metric using temporal matching and trajectory data.

# Arguments
- `matching`: Temporal matching between true and detected trajectories
- `detected_trajectories`: Vector of detected trajectories

# Returns
- `Int`: Total number of identity switches
"""
function identity_switches(matching::TemporalMatching, detected_trajectories::Vector{<:Trajectory})
    return identity_switches(matching.frame_correspondences, detected_trajectories)
end