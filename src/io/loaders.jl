"""
Unified load_tracks function with multiple dispatch based on format type.

This file implements loaders for different tracking software packages that
all output Trajectory/Tracks types.
"""

using MAT

# Import types from tracking module
using ..Tracking: Trajectory, Tracks

"""
    load_tracks(::SmiteFormat, filepath::String; varname="SMD", dt=0.01)

Load SMITE tracking data and convert to Tracks format.

# Arguments
- `format::SmiteFormat`: Format specifier
- `filepath::String`: Path to the .mat file
- `varname::String`: Variable name in .mat file (default: "SMD")
- `dt::Float64`: Time between frames in seconds (default: 0.01)

# Returns
- `Tracks`: Tracking dataset with trajectories

# Example
```julia
tracks = load_tracks(SmiteFormat(), "data/smite_results.mat")
tracks_3d = load_tracks(SmiteFormat(), "data/smite_3d.mat", dt=0.005)
```
"""
function load_tracks(::SmiteFormat, filepath::String; varname::String="SMD", dt::Float64=0.01)
    # Load MATLAB file
    mat_data = matread(filepath)

    if !haskey(mat_data, varname)
        error("Variable '$varname' not found in $filepath")
    end

    s = mat_data[varname]

    # Check for complex fields and get valid indices
    fields_to_check = haskey(s, "Z") ?
        ["X", "Y", "Z", "Photons", "Bg", "X_SE", "Y_SE", "Z_SE", "Photons_SE", "Bg_SE"] :
        ["X", "Y", "Photons", "Bg", "X_SE", "Y_SE", "Photons_SE", "Bg_SE"]

    has_complex, complex_indices = check_complex_fields(s, fields_to_check)

    valid_indices = if has_complex
        indices = get_valid_indices(s, complex_indices)
        n_removed = length(s["X"]) - length(indices)
        @warn "Found $n_removed emitters with non-zero imaginary components. These will be excluded."
        indices
    else
        1:length(s["X"])
    end

    # Extract metadata
    pixel_size = get(s, "PixelSize", 0.1)
    n_frames = Int(s["NFrames"])
    is_3d = haskey(s, "Z")

    # Group localizations by track ID (ConnectID)
    track_dict = Dict{Int, Vector{Int}}()  # track_id => indices
    for idx in valid_indices
        track_id = Int(s["ConnectID"][idx])
        if !haskey(track_dict, track_id)
            track_dict[track_id] = Int[]
        end
        push!(track_dict[track_id], idx)
    end

    # Create Trajectory objects
    trajectories = Trajectory[]
    for (track_id, indices) in track_dict
        # Sort by frame number
        sort!(indices, by=i -> Int(s["FrameNum"][i]))

        # Extract coordinates
        frames = [Int(s["FrameNum"][i]) for i in indices]
        x_coords = [Float64(real(s["X"][i])) for i in indices]
        y_coords = [Float64(real(s["Y"][i])) for i in indices]
        z_coords = is_3d ? [Float64(real(s["Z"][i])) for i in indices] : nothing

        # Create trajectory
        traj = Trajectory(
            id=track_id,
            frames=frames,
            x=x_coords,
            y=y_coords,
            z=z_coords,
            dt=dt
        )
        push!(trajectories, traj)
    end

    # Determine frame range
    frame_min = isempty(trajectories) ? 1 : minimum(minimum(t.frames) for t in trajectories)
    frame_max = isempty(trajectories) ? n_frames : max(n_frames, maximum(maximum(t.frames) for t in trajectories))

    # Create metadata
    metadata = Dict{String,Any}(
        "source" => "SMITE",
        "original_file" => filepath,
        "pixel_size" => pixel_size,
        "is_3d" => is_3d
    )

    if has_complex
        metadata["complex_fields_removed"] = true
        metadata["removed_emitter_count"] = length(s["X"]) - length(valid_indices)
    end

    return Tracks(
        trajectories=trajectories,
        frame_range=(frame_min, frame_max),
        metadata=metadata
    )
end

"""
Helper functions for handling complex numbers in SMITE data.
"""
function check_complex_fields(s::Dict, field_names::Vector{String})
    complex_indices = Dict{String, Vector{Int}}()
    has_complex = false

    for field in field_names
        if haskey(s, field)
            data = s[field]
            if eltype(data) <: Complex
                # Find indices with non-zero imaginary parts
                complex_idx = findall(x -> abs(imag(x)) > 1e-10, data)
                if !isempty(complex_idx)
                    complex_indices[field] = complex_idx
                    has_complex = true
                end
            end
        end
    end

    return has_complex, complex_indices
end

function get_valid_indices(s::Dict, complex_indices::Dict{String, Vector{Int}})
    # Combine all complex indices from all fields
    all_complex_idx = Set{Int}()
    for (field, indices) in complex_indices
        union!(all_complex_idx, indices)
    end

    # Get total number of emitters
    n_total = length(s["X"])

    # Valid indices are those not in the complex set
    valid_indices = filter(i -> !(i in all_complex_idx), 1:n_total)

    return valid_indices
end

"""
    load_tracks(::UTrackFormat, filepath::String; varname="tracksFinal", dt=0.01, flatten_compound=true)

Load u-track tracking data and convert to Tracks format.

# Arguments
- `format::UTrackFormat`: Format specifier
- `filepath::String`: Path to the .mat file
- `varname::String`: Variable name in .mat file (default: "tracksFinal")
- `dt::Float64`: Time between frames in seconds (default: 0.01)
- `flatten_compound::Bool`: Split compound tracks into simple tracks (default: true)

# Returns
- `Tracks`: Tracking dataset with trajectories

# Example
```julia
tracks = load_tracks(UTrackFormat(), "data/tracksFinal.mat")
tracks_3d = load_tracks(UTrackFormat(), "data/tracksFinal_3d.mat", dt=0.005)
```

# Notes
- u-track stores compound tracks that may include merging/splitting events
- Setting `flatten_compound=true` splits these into simple tracks (recommended)
- Gap frames (NaN values) are skipped
- Coordinates are assumed to be in microns
"""
function load_tracks(::UTrackFormat, filepath::String; varname::String="tracksFinal", dt::Float64=0.01, flatten_compound::Bool=true)
    # Load MATLAB file
    mat_data = matread(filepath)

    if !haskey(mat_data, varname)
        error("Variable '$varname' not found in $filepath")
    end

    tracksFinal = mat_data[varname]

    # Initialize trajectory storage
    all_trajectories = Trajectory[]
    track_id = 1
    n_compound_tracks = length(tracksFinal)

    # Determine if data is 3D by checking first valid track
    is_3d = false
    for compound_track in tracksFinal
        if haskey(compound_track, "tracksCoordAmpCG")
            coords_amp = vec(compound_track["tracksCoordAmpCG"])
            if !isempty(coords_amp)
                # Check if z-coordinates are non-zero
                track_matrix = reshape(coords_amp, 8, :)'
                if any(abs.(track_matrix[:, 3]) .> 1e-10)
                    is_3d = true
                end
                break
            end
        end
    end

    max_frame = 0
    min_frame = typemax(Int)

    # Process each compound track
    for compound_track in tracksFinal
        if !haskey(compound_track, "tracksCoordAmpCG") || !haskey(compound_track, "tracksFeatIndxCG")
            @warn "Compound track missing required fields, skipping"
            continue
        end

        coords_amp = vec(compound_track["tracksCoordAmpCG"])
        track_matrix = reshape(coords_amp, 8, :)'  # n_frames × 8

        feat_indx = compound_track["tracksFeatIndxCG"]
        if ndims(feat_indx) == 1
            feat_indx = reshape(feat_indx, 1, :)
        end

        # Get sequence of events for frame timing
        first_frame_offsets = ones(Int, size(feat_indx, 1))
        if haskey(compound_track, "seqOfEvents")
            seq_events = compound_track["seqOfEvents"]
            for subtrack_idx in 1:size(feat_indx, 1)
                for row_idx in 1:size(seq_events, 1)
                    if Int(seq_events[row_idx, 2]) == 1 && Int(seq_events[row_idx, 3]) == subtrack_idx
                        first_frame_offsets[subtrack_idx] = Int(seq_events[row_idx, 1])
                        break
                    end
                end
            end
        end

        if flatten_compound
            # Split compound track into simple tracks
            for subtrack_idx in 1:size(feat_indx, 1)
                track_indices = feat_indx[subtrack_idx, :]

                frames = Int[]
                x_coords = Float64[]
                y_coords = Float64[]
                z_coords = Float64[]

                first_valid_frame = first_frame_offsets[subtrack_idx]

                for (frame_offset, feat_idx) in enumerate(track_indices)
                    # Skip NaN (gaps)
                    if isnan(feat_idx) || frame_offset > size(track_matrix, 1)
                        continue
                    end

                    x = track_matrix[frame_offset, 1]
                    y = track_matrix[frame_offset, 2]
                    z = track_matrix[frame_offset, 3]

                    # Skip invalid positions
                    if isnan(x) || isnan(y) || isinf(x) || isinf(y)
                        continue
                    end

                    absolute_frame = first_valid_frame > 0 ? first_valid_frame + frame_offset - 1 : frame_offset

                    push!(frames, absolute_frame)
                    push!(x_coords, Float64(x))
                    push!(y_coords, Float64(y))
                    if is_3d
                        push!(z_coords, Float64(z))
                    end

                    max_frame = max(max_frame, absolute_frame)
                    min_frame = min(min_frame, absolute_frame)
                end

                # Create trajectory if it has positions
                if !isempty(frames)
                    traj = Trajectory(
                        id=track_id,
                        frames=frames,
                        x=x_coords,
                        y=y_coords,
                        z=is_3d ? z_coords : nothing,
                        dt=dt
                    )
                    push!(all_trajectories, traj)
                    track_id += 1
                end
            end
        end
    end

    # Handle empty case
    if isempty(all_trajectories)
        min_frame = 1
        max_frame = 1
    end

    # Create metadata
    metadata = Dict{String,Any}(
        "source" => "u-track",
        "original_file" => filepath,
        "flatten_compound" => flatten_compound,
        "n_compound_tracks" => n_compound_tracks,
        "n_tracks" => length(all_trajectories),
        "is_3d" => is_3d
    )

    return Tracks(
        trajectories=all_trajectories,
        frame_range=(min_frame, max_frame),
        metadata=metadata
    )
end

"""
    load_tracks(::BNPTrackFormat, filepath::String; varname="chain", dt=0.01)

Load BNP-Track tracking data and convert to Tracks format.

# Arguments
- `format::BNPTrackFormat`: Format specifier
- `filepath::String`: Path to the .mat file
- `varname::String`: Variable name in .mat file (default: "chain")
- `dt::Float64`: Time between frames in seconds (default: 0.01)

# Returns
- `Tracks`: Tracking dataset with trajectories

# Example
```julia
tracks = load_tracks(BNPTrackFormat(), "data/chain.mat")
tracks_3d = load_tracks(BNPTrackFormat(), "data/chain_3d.mat", dt=0.005)
```

# Notes
- BNP-Track outputs MCMC chains with posterior distributions
- This loader extracts the final sample state
- The chain.sample.K vector assigns time points to particles (atoms)
- Active particles are determined by chain.sample.b indicator
- Coordinates are assumed to be in microns
"""
function load_tracks(::BNPTrackFormat, filepath::String; varname::String="chain", dt::Float64=0.01)
    # Load MATLAB file
    mat_data = matread(filepath)

    if !haskey(mat_data, varname)
        error("Variable '$varname' not found in $filepath")
    end

    chain = mat_data[varname]

    # Extract chain components
    if !haskey(chain, "params") || !haskey(chain, "sample")
        error("Invalid BNP-Track chain structure: missing 'params' or 'sample'")
    end

    params = chain["params"]
    sample = chain["sample"]

    # Get frame timing information
    t_mid = vec(params["t_mid"])
    n_frames = length(t_mid)

    # Extract final sample state
    X_final = sample["X"]  # N × M matrix (timepoints × particles)
    Y_final = sample["Y"]
    b_final = vec(sample["b"])  # Existence indicator (1 × M)
    K_final = vec(sample["K"])  # Atom assignment per time point (1 × N)

    # Check for 3D data
    is_3d = haskey(sample, "Z")
    Z_final = is_3d ? sample["Z"] : nothing

    n_timepoints = size(X_final, 1)
    max_particles = size(X_final, 2)

    # Filter to active particles only
    active_particles = findall(b -> b >= 0.5, b_final)
    n_active = length(active_particles)

    if n_active == 0
        @warn "No active particles found in BNP-Track output"
        return Tracks(
            trajectories=Trajectory[],
            frame_range=(1, n_frames),
            metadata=Dict{String,Any}(
                "source" => "BNP-Track",
                "original_file" => filepath,
                "n_active_particles" => 0,
                "is_3d" => is_3d
            )
        )
    end

    # Build trajectories by grouping time points by atom assignment
    atom_timepoints = Dict{Int, Vector{Int}}()  # atom_idx => timepoints
    for (time_idx, atom_idx) in enumerate(K_final)
        atom_idx_int = Int(atom_idx)
        # Check if this atom is active
        if atom_idx_int >= 1 && atom_idx_int <= max_particles && b_final[atom_idx_int] >= 0.5
            if !haskey(atom_timepoints, atom_idx_int)
                atom_timepoints[atom_idx_int] = Int[]
            end
            push!(atom_timepoints[atom_idx_int], time_idx)
        end
    end

    # Create trajectories
    all_trajectories = Trajectory[]
    for (atom_idx, timepoints) in atom_timepoints
        sort!(timepoints)  # Ensure temporal order

        frames = Int[]
        x_coords = Float64[]
        y_coords = Float64[]
        z_coords = Float64[]

        for time_idx in timepoints
            x = Float64(X_final[time_idx, atom_idx])
            y = Float64(Y_final[time_idx, atom_idx])

            # Skip NaN or invalid positions
            if isnan(x) || isnan(y) || isinf(x) || isinf(y)
                continue
            end

            push!(frames, time_idx)
            push!(x_coords, x)
            push!(y_coords, y)

            if is_3d
                z = Float64(Z_final[time_idx, atom_idx])
                push!(z_coords, z)
            end
        end

        # Create trajectory if it has positions
        if !isempty(frames)
            traj = Trajectory(
                id=atom_idx,
                frames=frames,
                x=x_coords,
                y=y_coords,
                z=is_3d ? z_coords : nothing,
                dt=dt
            )
            push!(all_trajectories, traj)
        end
    end

    # Determine frame range
    min_frame = isempty(all_trajectories) ? 1 : minimum(minimum(t.frames) for t in all_trajectories)
    max_frame = isempty(all_trajectories) ? n_frames : max(n_frames, maximum(maximum(t.frames) for t in all_trajectories))

    # Create metadata
    metadata = Dict{String,Any}(
        "source" => "BNP-Track",
        "original_file" => filepath,
        "n_active_particles" => n_active,
        "max_particles" => max_particles,
        "n_tracks" => length(all_trajectories),
        "is_3d" => is_3d
    )

    # Add chain statistics if available
    if haskey(chain, "length")
        metadata["chain_length"] = chain["length"]
    end
    if haskey(chain, "stride")
        metadata["chain_stride"] = chain["stride"]
    end

    return Tracks(
        trajectories=all_trajectories,
        frame_range=(min_frame, max_frame),
        metadata=metadata
    )
end
