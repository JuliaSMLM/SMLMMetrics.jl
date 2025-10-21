"""
Functions for loading u-track tracking data and converting to SMLMData format.
"""

using MAT
using SMLMData
using SMLMData: Emitter2DFit, Emitter3DFit, IdealCamera

include("utils.jl")

"""
    load_utrack_2d(utrack::UTrackSMD;
                   flatten_compound::Bool=true,
                   include_gaps::Bool=false,
                   pixel_size::Float64=0.1,
                   image_size::Tuple{Int,Int}=(512,512))

Load u-track 2D tracking results and convert to SMLMData format.

# Arguments
- `utrack::UTrackSMD`: Specification of u-track .mat file to load
- `flatten_compound::Bool=true`: If true, split compound tracks into simple tracks
- `include_gaps::Bool=false`: If true, interpolate positions during gaps (NaN frames)
- `pixel_size::Float64=0.1`: Pixel size in microns (default 0.1 μm)
- `image_size::Tuple{Int,Int}=(512,512)`: Image size in pixels (x, y)

# Returns
- `UTrackSMLD{Float64, Emitter2DFit{Float64}}`: Converted tracking data

# Notes
- u-track stores compound tracks that may include merging/splitting events
- Setting `flatten_compound=true` splits these into simple tracks (recommended for metrics)
- Gap frames (NaN values) are skipped unless `include_gaps=true`
- Coordinates are assumed to be in microns
- Amplitude values are used as photon count proxies
"""
function load_utrack_2d(utrack::UTrackSMD;
                        flatten_compound::Bool=true,
                        include_gaps::Bool=false,
                        pixel_size::Float64=0.1,
                        image_size::Tuple{Int,Int}=(512,512))

    # Load MATLAB file
    file_path = joinpath(utrack.filepath, utrack.filename)
    mat_data = matread(file_path)

    if !haskey(mat_data, utrack.varname)
        error("Variable '$(utrack.varname)' not found in $(file_path)")
    end

    tracksFinal = mat_data[utrack.varname]

    # Initialize emitter storage
    emitters = Emitter2DFit{Float64}[]
    emitter_id = 1
    global_track_id = 1

    n_compound_tracks = length(tracksFinal)
    total_subtracks = 0

    # Process each compound track
    for compound_track in tracksFinal
        # Extract coordinate-amplitude array
        # Format: [x1 y1 z1 A1 dx1 dy1 dz1 dA1 x2 y2 z2 A2 ...]
        if !haskey(compound_track, "tracksCoordAmpCG")
            @warn "Compound track missing 'tracksCoordAmpCG' field, skipping"
            continue
        end

        coords_amp = vec(compound_track["tracksCoordAmpCG"])

        # Reshape to matrix: n_frames × 8
        track_matrix = reshape_track_coords(coords_amp)
        n_frames_in_track = size(track_matrix, 1)

        # Extract feature index matrix (handles merging/splitting)
        if !haskey(compound_track, "tracksFeatIndxCG")
            @warn "Compound track missing 'tracksFeatIndxCG' field, skipping"
            continue
        end

        feat_indx = compound_track["tracksFeatIndxCG"]

        # Ensure feat_indx is 2D matrix
        if ndims(feat_indx) == 1
            feat_indx = reshape(feat_indx, 1, :)
        end

        if flatten_compound
            # Split compound track into simple tracks (each row becomes a track)
            n_subtracks = size(feat_indx, 1)
            total_subtracks += n_subtracks

            for subtrack_idx in 1:n_subtracks
                track_indices = feat_indx[subtrack_idx, :]

                # Get first valid frame to determine absolute frame offset
                first_valid_frame = 0
                if haskey(compound_track, "seqOfEvents")
                    seq_events = compound_track["seqOfEvents"]
                    # Find start event for this subtrack
                    for row_idx in 1:size(seq_events, 1)
                        if Int(seq_events[row_idx, 2]) == 1 && Int(seq_events[row_idx, 3]) == subtrack_idx
                            first_valid_frame = Int(seq_events[row_idx, 1])
                            break
                        end
                    end
                end

                for (frame_offset, feat_idx) in enumerate(track_indices)
                    # Skip NaN (gaps) unless include_gaps is true
                    if isnan(feat_idx)
                        if include_gaps
                            # TODO: Implement interpolation
                            continue
                        else
                            continue
                        end
                    end

                    # Skip if frame_offset exceeds track_matrix size
                    if frame_offset > n_frames_in_track
                        continue
                    end

                    # Extract position and uncertainties from track_matrix
                    x = track_matrix[frame_offset, 1]
                    y = track_matrix[frame_offset, 2]
                    # z = track_matrix[frame_offset, 3]  # For 3D (typically 0 for 2D)
                    amplitude = track_matrix[frame_offset, 4]
                    σ_x = track_matrix[frame_offset, 5]
                    σ_y = track_matrix[frame_offset, 6]
                    # σ_z = track_matrix[frame_offset, 7]  # For 3D
                    σ_amplitude = track_matrix[frame_offset, 8]

                    # Skip invalid positions
                    if !is_valid_position(x, y)
                        continue
                    end

                    # Calculate absolute frame number
                    absolute_frame = first_valid_frame > 0 ? first_valid_frame + frame_offset - 1 : frame_offset

                    push!(emitters, Emitter2DFit{Float64}(
                        Float64(x),
                        Float64(y),
                        Float64(amplitude),
                        0.0,  # bg (not available in u-track)
                        Float64(max(σ_x, 0.0)),  # Ensure non-negative
                        Float64(max(σ_y, 0.0)),
                        Float64(max(σ_amplitude, 0.0)),
                        0.0;  # σ_bg
                        frame=absolute_frame,
                        dataset=1,
                        track_id=global_track_id,
                        id=emitter_id
                    ))
                    emitter_id += 1
                end

                global_track_id += 1
            end
        else
            # Keep compound track structure (not recommended)
            @warn "Keeping compound track structure is not fully implemented"
        end
    end

    # Create camera
    camera = IdealCamera(1:image_size[1], 1:image_size[2], pixel_size)

    # Determine number of frames
    max_frame = isempty(emitters) ? 0 : maximum(e.frame for e in emitters)

    # Metadata
    metadata = Dict{String,Any}(
        "original_file" => utrack.filename,
        "method" => "u-track",
        "flatten_compound" => flatten_compound,
        "n_compound_tracks" => n_compound_tracks,
        "n_simple_tracks" => total_subtracks,
        "pixel_size" => pixel_size,
        "image_size" => image_size
    )

    return UTrackSMLD{Float64, Emitter2DFit{Float64}}(
        emitters,
        camera,
        max_frame,
        1,
        metadata
    )
end

"""
    load_utrack_3d(utrack::UTrackSMD; kwargs...)

Load u-track 3D tracking results and convert to SMLMData format.

Similar to `load_utrack_2d` but extracts z-coordinates and uses `Emitter3DFit`.

# Arguments
Same as `load_utrack_2d`

# Returns
- `UTrackSMLD{Float64, Emitter3DFit{Float64}}`: Converted 3D tracking data
"""
function load_utrack_3d(utrack::UTrackSMD;
                        flatten_compound::Bool=true,
                        include_gaps::Bool=false,
                        pixel_size::Float64=0.1,
                        image_size::Tuple{Int,Int}=(512,512))

    # Load MATLAB file
    file_path = joinpath(utrack.filepath, utrack.filename)
    mat_data = matread(file_path)

    if !haskey(mat_data, utrack.varname)
        error("Variable '$(utrack.varname)' not found in $(file_path)")
    end

    tracksFinal = mat_data[utrack.varname]

    # Initialize emitter storage
    emitters = Emitter3DFit{Float64}[]
    emitter_id = 1
    global_track_id = 1

    n_compound_tracks = length(tracksFinal)
    total_subtracks = 0

    # Process each compound track (similar to 2D but extract z)
    for compound_track in tracksFinal
        if !haskey(compound_track, "tracksCoordAmpCG")
            @warn "Compound track missing 'tracksCoordAmpCG' field, skipping"
            continue
        end

        coords_amp = vec(compound_track["tracksCoordAmpCG"])
        track_matrix = reshape_track_coords(coords_amp)
        n_frames_in_track = size(track_matrix, 1)

        if !haskey(compound_track, "tracksFeatIndxCG")
            @warn "Compound track missing 'tracksFeatIndxCG' field, skipping"
            continue
        end

        feat_indx = compound_track["tracksFeatIndxCG"]
        if ndims(feat_indx) == 1
            feat_indx = reshape(feat_indx, 1, :)
        end

        if flatten_compound
            n_subtracks = size(feat_indx, 1)
            total_subtracks += n_subtracks

            for subtrack_idx in 1:n_subtracks
                track_indices = feat_indx[subtrack_idx, :]

                first_valid_frame = 0
                if haskey(compound_track, "seqOfEvents")
                    seq_events = compound_track["seqOfEvents"]
                    for row_idx in 1:size(seq_events, 1)
                        if Int(seq_events[row_idx, 2]) == 1 && Int(seq_events[row_idx, 3]) == subtrack_idx
                            first_valid_frame = Int(seq_events[row_idx, 1])
                            break
                        end
                    end
                end

                for (frame_offset, feat_idx) in enumerate(track_indices)
                    if isnan(feat_idx)
                        if include_gaps
                            continue
                        else
                            continue
                        end
                    end

                    if frame_offset > n_frames_in_track
                        continue
                    end

                    # Extract 3D position and uncertainties
                    x = track_matrix[frame_offset, 1]
                    y = track_matrix[frame_offset, 2]
                    z = track_matrix[frame_offset, 3]  # Now using z coordinate
                    amplitude = track_matrix[frame_offset, 4]
                    σ_x = track_matrix[frame_offset, 5]
                    σ_y = track_matrix[frame_offset, 6]
                    σ_z = track_matrix[frame_offset, 7]  # Now using z uncertainty
                    σ_amplitude = track_matrix[frame_offset, 8]

                    # Skip invalid positions (3D check)
                    if !is_valid_position(x, y, z)
                        continue
                    end

                    absolute_frame = first_valid_frame > 0 ? first_valid_frame + frame_offset - 1 : frame_offset

                    push!(emitters, Emitter3DFit{Float64}(
                        Float64(x),
                        Float64(y),
                        Float64(z),
                        Float64(amplitude),
                        0.0,  # bg
                        Float64(max(σ_x, 0.0)),
                        Float64(max(σ_y, 0.0)),
                        Float64(max(σ_z, 0.0)),
                        Float64(max(σ_amplitude, 0.0)),
                        0.0;  # σ_bg
                        frame=absolute_frame,
                        dataset=1,
                        track_id=global_track_id,
                        id=emitter_id
                    ))
                    emitter_id += 1
                end

                global_track_id += 1
            end
        end
    end

    camera = IdealCamera(1:image_size[1], 1:image_size[2], pixel_size)
    max_frame = isempty(emitters) ? 0 : maximum(e.frame for e in emitters)

    metadata = Dict{String,Any}(
        "original_file" => utrack.filename,
        "method" => "u-track",
        "flatten_compound" => flatten_compound,
        "n_compound_tracks" => n_compound_tracks,
        "n_simple_tracks" => total_subtracks,
        "pixel_size" => pixel_size,
        "image_size" => image_size
    )

    return UTrackSMLD{Float64, Emitter3DFit{Float64}}(
        emitters,
        camera,
        max_frame,
        1,
        metadata
    )
end
