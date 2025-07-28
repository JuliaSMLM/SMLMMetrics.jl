"""
    merging.jl

Track Merging (MRG) metric from Chenouard et al. (2014).
Measures how often two or more true tracks are merged into a single estimated track.
"""

"""
    track_merging(detected_to_true::Dict{Int, Vector{Int}}, n_detected::Int)

Calculate the Track Merging (MRG) metric.

MRG = (1/N_detected) * Σ max(0, M_j - 1)

where M_j is the number of true tracks that correspond to detected track j.

# Arguments
- `detected_to_true`: Mapping from detected trajectory IDs to true trajectory IDs
- `n_detected`: Total number of detected trajectories

# Returns
- `Float64`: Track merging score (lower is better)

# Example
```julia
mapping = Dict(1 => [1, 2], 2 => [3], 3 => [4, 5])
mrg = track_merging(mapping, 3)  # Returns 2/3
```
"""
function track_merging(detected_to_true::Dict{Int, Vector{Int}}, n_detected::Int)
    if n_detected == 0
        return 0.0
    end
    
    total_extra_merges = 0
    for (detected_id, true_ids) in detected_to_true
        n_true = length(true_ids)
        total_extra_merges += max(0, n_true - 1)
    end
    
    return total_extra_merges / n_detected
end

"""
    track_merging(matching::TemporalMatching, detected_trajectories::Vector{Trajectory})

Calculate the Track Merging metric using temporal matching and trajectory data.

# Arguments
- `matching`: Temporal matching between true and detected trajectories
- `detected_trajectories`: Vector of detected trajectories

# Returns
- `Float64`: Track merging score
"""
function track_merging(matching::TemporalMatching, detected_trajectories::Vector{<:Trajectory})
    if isempty(detected_trajectories)
        return 0.0
    end
    
    return track_merging(matching.detected_to_true, length(detected_trajectories))
end