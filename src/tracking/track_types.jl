"""
    Track

A temporal series of spatial positions for particle tracking evaluation.

# Fields
- `positions::Dict{Int, Vector{Float64}}`: Maps time points to spatial coordinates [x, y] or [x, y, z]
- `t_init::Int`: Initial time point (birth time)
- `t_end::Int`: Final time point (death time)

# Notes
- Missing positions in the interval [t_init, t_end] are treated as gaps in the track
- Time points are 0-indexed following the paper convention
"""
struct Track
    positions::Dict{Int, Vector{Float64}}
    t_init::Int
    t_end::Int

    function Track(positions::Dict{Int, Vector{Float64}}, t_init::Int, t_end::Int)
        if isempty(positions)
            error("Track must have at least one position")
        end
        if t_init > t_end
            error("t_init must be <= t_end")
        end
        new(positions, t_init, t_end)
    end
end

"""
    Track(positions::Dict{Int, Vector{Float64}})

Construct a Track with automatic detection of t_init and t_end from the position keys.
"""
function Track(positions::Dict{Int, Vector{Float64}})
    if isempty(positions)
        error("Track must have at least one position")
    end
    times = collect(keys(positions))
    t_init = minimum(times)
    t_end = maximum(times)
    return Track(positions, t_init, t_end)
end

"""
    has_position(track::Track, t::Int)

Check if a track has a position at time point t.
"""
function has_position(track::Track, t::Int)
    return haskey(track.positions, t)
end

"""
    get_position(track::Track, t::Int)

Get the position at time t, or nothing if not present.
"""
function get_position(track::Track, t::Int)
    return get(track.positions, t, nothing)
end

"""
    track_length(track::Track)

Return the temporal extent of the track (t_end - t_init + 1).
"""
function track_length(track::Track)
    return track.t_end - track.t_init + 1
end

"""
    num_positions(track::Track)

Return the number of actual positions in the track.
"""
function num_positions(track::Track)
    return length(track.positions)
end

"""
    is_dummy_track(track::Union{Track, Nothing})

Check if a track is a dummy track (represented as nothing).
"""
function is_dummy_track(track::Union{Track, Nothing})
    return track === nothing
end
