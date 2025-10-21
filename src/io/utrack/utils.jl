"""
Utility functions for u-track data processing.
"""

"""
    parse_compound_track_events(seq_events::Matrix)

Parse u-track seqOfEvents matrix to understand merging/splitting events.

The seqOfEvents matrix has dimensions (n_events × 4) where:
- Column 1: Frame number where event occurs
- Column 2: Event type (1 = start, 2 = end)
- Column 3: Track index within compound track
- Column 4: Event nature (NaN = true init/term, non-NaN = split/merge)

# Returns
- `starts`: Dict mapping track_idx => (frame, is_split)
- `ends`: Dict mapping track_idx => (frame, is_merge)
"""
function parse_compound_track_events(seq_events::Matrix)
    starts = Dict{Int, Tuple{Int, Bool}}()
    ends = Dict{Int, Tuple{Int, Bool}}()

    for row_idx in 1:size(seq_events, 1)
        frame = Int(seq_events[row_idx, 1])
        event_type = Int(seq_events[row_idx, 2])
        track_idx = Int(seq_events[row_idx, 3])
        nature = seq_events[row_idx, 4]

        if event_type == 1  # Start event
            is_split = !isnan(nature)
            starts[track_idx] = (frame, is_split)
        elseif event_type == 2  # End event
            is_merge = !isnan(nature)
            ends[track_idx] = (frame, is_merge)
        end
    end

    return starts, ends
end

"""
    interpolate_gap(prev_pos::Vector{Float64}, next_pos::Vector{Float64}, n_frames::Int)

Linear interpolation for gap filling in tracks.

# Arguments
- `prev_pos`: Position before gap
- `next_pos`: Position after gap
- `n_frames`: Number of frames in the gap

# Returns
- Vector of interpolated positions
"""
function interpolate_gap(prev_pos::Vector{Float64}, next_pos::Vector{Float64}, n_frames::Int)
    positions = Vector{Vector{Float64}}()

    for i in 1:n_frames
        α = i / (n_frames + 1)
        interp_pos = (1 - α) * prev_pos + α * next_pos
        push!(positions, interp_pos)
    end

    return positions
end

"""
    reshape_track_coords(track_coords::Vector{Float64})

Reshape u-track tracksCoordAmpCG row vector to matrix format.

u-track stores coordinates as a row vector with repeating 8-element pattern:
[x1 y1 z1 A1 dx1 dy1 dz1 dA1 x2 y2 z2 A2 dx2 dy2 dz2 dA2 ...]

# Returns
- Matrix of size (n_frames × 8) where each row contains:
  [x, y, z, amplitude, σ_x, σ_y, σ_z, σ_amplitude]
"""
function reshape_track_coords(track_coords::Vector{Float64})
    n_elements = length(track_coords)
    n_frames = n_elements ÷ 8

    if n_elements % 8 != 0
        @warn "Track coordinates length ($n_elements) is not divisible by 8"
    end

    # Reshape from row vector to matrix: n_frames × 8
    track_matrix = reshape(track_coords[1:(n_frames*8)], 8, n_frames)'

    return track_matrix
end

"""
    is_valid_position(x::Real, y::Real, z::Real=0.0)

Check if a position is valid (not NaN, not all zeros).

# Arguments
- `x, y, z`: Coordinates to check

# Returns
- `true` if position is valid, `false` otherwise
"""
function is_valid_position(x::Real, y::Real, z::Real=0.0)
    # Check for NaN
    if isnan(x) || isnan(y) || isnan(z)
        return false
    end

    # Check for all zeros (often indicates missing data in u-track)
    if x == 0.0 && y == 0.0 && z == 0.0
        return false
    end

    return true
end
