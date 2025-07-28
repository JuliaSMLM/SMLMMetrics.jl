"""
    temporal_matching.jl

Temporal matching infrastructure for trajectory correspondence analysis.
"""

using SMLMSim: DiffusingEmitter2D, AbstractMotionModel

"""
    Trajectory{M<:AbstractMotionModel}

Trajectory type following RJTrack conventions.
"""
mutable struct Trajectory{M<:AbstractMotionModel}
    id::Int
    emitters::Vector{DiffusingEmitter2D{Float64}}
    motion_model::M

    function Trajectory(id::Int, emitters::Vector{DiffusingEmitter2D{Float64}}, motion_model::M) where {M<:AbstractMotionModel}
        new{M}(id, emitters, motion_model)
    end
end

Trajectory(id::Int, emitter::DiffusingEmitter2D{Float64}, motion_model::M) where {M<:AbstractMotionModel} = 
    Trajectory(id, [emitter], motion_model)

"""
    TemporalMatching

Stores the correspondence between true and detected trajectories.

# Fields
- `true_to_detected::Dict{Int, Vector{Int}}`: Maps true trajectory IDs to detected trajectory IDs
- `detected_to_true::Dict{Int, Vector{Int}}`: Maps detected trajectory IDs to true trajectory IDs
- `frame_correspondences::Dict{Int, Dict{Int, Int}}`: Frame-wise correspondence mapping
"""
struct TemporalMatching
    true_to_detected::Dict{Int, Vector{Int}}
    detected_to_true::Dict{Int, Vector{Int}}
    frame_correspondences::Dict{Int, Dict{Int, Int}}
end

"""
    build_temporal_matching(true_trajectories::Vector{Trajectory}, 
                          detected_trajectories::Vector{Trajectory}, 
                          cutoff::Vector{Float64})

Build temporal matching between true and detected trajectories using frame-by-frame matching.

# Arguments
- `true_trajectories`: Vector of true trajectories
- `detected_trajectories`: Vector of detected trajectories  
- `cutoff`: Distance cutoff for matching in each dimension [x, y]

# Returns
- `TemporalMatching`: Structure containing trajectory correspondences
"""
function build_temporal_matching(true_trajectories::Vector{<:Trajectory}, 
                               detected_trajectories::Vector{<:Trajectory}, 
                               cutoff::Vector{Float64})
    true_to_detected = Dict{Int, Vector{Int}}()
    detected_to_true = Dict{Int, Vector{Int}}()
    frame_correspondences = Dict{Int, Dict{Int, Int}}()
    
    # Get all unique frames
    all_frames = Set{Int}()
    for traj in vcat(true_trajectories, detected_trajectories)
        for emitter in traj.emitters
            push!(all_frames, emitter.frame)
        end
    end
    
    # Match trajectories frame by frame
    for frame in all_frames
        # Extract positions at this frame
        true_pos = Float64[]
        true_ids = Int[]
        for traj in true_trajectories
            for emitter in traj.emitters
                if emitter.frame == frame
                    push!(true_pos, emitter.x, emitter.y)
                    push!(true_ids, traj.id)
                end
            end
        end
        
        detected_pos = Float64[]
        detected_ids = Int[]
        for traj in detected_trajectories
            for emitter in traj.emitters
                if emitter.frame == frame
                    push!(detected_pos, emitter.x, emitter.y)
                    push!(detected_ids, traj.id)
                end
            end
        end
        
        if !isempty(true_pos) && !isempty(detected_pos)
            # Convert to matrices
            true_coords = reshape(true_pos, 2, :)
            detected_coords = reshape(detected_pos, 2, :)
            
            # Use existing match function
            assignment = match(true_coords, detected_coords, cutoff)
            
            # Build frame correspondence
            frame_corr = Dict{Int, Int}()
            for (i, j) in enumerate(assignment)
                if j > 0  # Valid match
                    true_id = true_ids[i]
                    detected_id = detected_ids[j]
                    
                    # Update trajectory mappings
                    if !haskey(true_to_detected, true_id)
                        true_to_detected[true_id] = Int[]
                    end
                    if !(detected_id in true_to_detected[true_id])
                        push!(true_to_detected[true_id], detected_id)
                    end
                    
                    if !haskey(detected_to_true, detected_id)
                        detected_to_true[detected_id] = Int[]
                    end
                    if !(true_id in detected_to_true[detected_id])
                        push!(detected_to_true[detected_id], true_id)
                    end
                    
                    frame_corr[true_id] = detected_id
                end
            end
            frame_correspondences[frame] = frame_corr
        end
    end
    
    return TemporalMatching(true_to_detected, detected_to_true, frame_correspondences)
end