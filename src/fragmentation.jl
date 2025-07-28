"""
    fragmentation.jl

Track Fragmentation (FRG) metric from Chenouard et al. (2014).
Measures how often a true track is split into multiple fragments by the tracking algorithm.
"""

"""
    track_fragmentation(true_to_detected::Dict{Int, Vector{Int}}, n_true::Int)

Calculate the Track Fragmentation (FRG) metric.

FRG = (1/N_true) * Σ max(0, F_i - 1)

where F_i is the number of detected track fragments corresponding to true track i.

# Arguments
- `true_to_detected`: Mapping from true trajectory IDs to detected trajectory IDs
- `n_true`: Total number of true trajectories

# Returns
- `Float64`: Track fragmentation score (lower is better)

# Example
```julia
mapping = Dict(1 => [1, 2], 2 => [3], 3 => [4, 5, 6])
frg = track_fragmentation(mapping, 3)  # Returns 2/3
```
"""
function track_fragmentation(true_to_detected::Dict{Int, Vector{Int}}, n_true::Int)
    if n_true == 0
        return 0.0
    end
    
    total_extra_fragments = 0
    for (true_id, detected_ids) in true_to_detected
        n_fragments = length(detected_ids)
        total_extra_fragments += max(0, n_fragments - 1)
    end
    
    return total_extra_fragments / n_true
end

"""
    track_fragmentation(matching::TemporalMatching, true_trajectories::Vector{Trajectory})

Calculate the Track Fragmentation metric using temporal matching and trajectory data.

# Arguments
- `matching`: Temporal matching between true and detected trajectories
- `true_trajectories`: Vector of true trajectories

# Returns
- `Float64`: Track fragmentation score
"""
function track_fragmentation(matching::TemporalMatching, true_trajectories::Vector{<:Trajectory})
    if isempty(true_trajectories)
        return 0.0
    end
    
    return track_fragmentation(matching.true_to_detected, length(true_trajectories))
end