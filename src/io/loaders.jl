"""
Unified load_tracks function with multiple dispatch based on format type.

This file implements loaders for different tracking software packages that
all output Trajectory/Tracks types.
"""

using MAT
using LightXML

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
    load_tracks(::ChallengeFormat, filepath::String; pixel_size=0.1, dt=0.01)

Load Particle Tracking Challenge ground truth XML and convert to Tracks format.

# Arguments
- `format::ChallengeFormat`: Format specifier
- `filepath::String`: Path to the XML file
- `pixel_size::Float64`: Pixel size in μm (default: 0.1)
- `dt::Float64`: Time between frames in seconds (default: 0.01)

# Returns
- `Tracks`: Tracking dataset with ground truth trajectories

# Example
```julia
gt_tracks = load_tracks(ChallengeFormat(), "data/ground_truth.xml", pixel_size=0.107)
```

# XML Format
The expected XML structure is:
```xml
<?xml version="1.0"?>
<TrackContestISBI2012>
  <particle nSpots="N">
    <detection t="0" x="10.5" y="20.3" z="0.0" />
    ...
  </particle>
</TrackContestISBI2012>
```
"""
function load_tracks(::ChallengeFormat, filepath::String; pixel_size::Float64=0.1, dt::Float64=0.01)
    if !isfile(filepath)
        error("File not found: $filepath")
    end

    # Parse XML
    xdoc = parse_file(filepath)
    xroot = root(xdoc)

    # Storage for trajectories
    all_trajectories = Trajectory[]
    track_id = 1

    max_frame = 0
    min_frame = typemax(Int)
    is_3d = false

    # Iterate through particles (tracks)
    for particle_elem in child_elements(xroot)
        if name(particle_elem) != "particle"
            continue
        end

        # Storage for this trajectory
        frames = Int[]
        x_coords = Float64[]
        y_coords = Float64[]
        z_coords = Float64[]
        has_z = false

        # Iterate through detections in this track
        for detection_elem in child_elements(particle_elem)
            if name(detection_elem) != "detection"
                continue
            end

            # Extract attributes
            t_str = attribute(detection_elem, "t")
            x_str = attribute(detection_elem, "x")
            y_str = attribute(detection_elem, "y")
            z_str = attribute(detection_elem, "z")

            if t_str === nothing || x_str === nothing || y_str === nothing
                @warn "Detection missing required attributes (t, x, y), skipping"
                continue
            end

            # Parse coordinates (in pixels)
            frame = parse(Int, t_str)
            x_pixel = parse(Float64, x_str)
            y_pixel = parse(Float64, y_str)

            # Convert to 1-indexed and microns
            frame_1idx = frame + 1  # Convert 0-indexed to 1-indexed
            x_micron = x_pixel * pixel_size
            y_micron = y_pixel * pixel_size

            push!(frames, frame_1idx)
            push!(x_coords, x_micron)
            push!(y_coords, y_micron)

            # Check for z coordinate
            if z_str !== nothing
                z_pixel = parse(Float64, z_str)
                z_micron = z_pixel * pixel_size
                push!(z_coords, z_micron)
                has_z = true
                is_3d = true
            end

            # Track min/max frame
            max_frame = max(max_frame, frame_1idx)
            min_frame = min(min_frame, frame_1idx)
        end

        # Create trajectory if it has positions
        if !isempty(frames)
            traj = Trajectory(
                id=track_id,
                frames=frames,
                x=x_coords,
                y=y_coords,
                z=has_z ? z_coords : nothing,
                dt=dt
            )
            push!(all_trajectories, traj)
            track_id += 1
        end
    end

    # Free XML document
    free(xdoc)

    # Handle empty case
    if isempty(all_trajectories)
        min_frame = 1
        max_frame = 1
    end

    # Create metadata
    metadata = Dict{String,Any}(
        "source" => "Particle Tracking Challenge",
        "method" => "Ground Truth",
        "original_file" => filepath,
        "pixel_size" => pixel_size,
        "is_3d" => is_3d,
        "n_tracks" => length(all_trajectories)
    )

    return Tracks(
        trajectories=all_trajectories,
        frame_range=(min_frame, max_frame),
        metadata=metadata
    )
end

# TODO: Implement loaders for other formats
# - load_tracks(::UTrackFormat, ...)
# - load_tracks(::BNPTrackFormat, ...)
