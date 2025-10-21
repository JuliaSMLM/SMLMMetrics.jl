"""
Functions for loading Particle Tracking Challenge ground truth data.

The XML format used by the ISBI Particle Tracking Challenge:
- Each detection: <detection t="frame" x="pos_x" y="pos_y" z="pos_z" />
- Detections are grouped by particle (track)
- Coordinates are in pixels (floating point)
- Frame numbers are integers (0-indexed or 1-indexed depending on challenge)
"""

using LightXML
using SMLMData
using SMLMData: Emitter2DFit, Emitter3DFit, IdealCamera

"""
    load_challenge_gt_2d(gt::TrackingChallengeGT; image_size::Tuple{Int,Int}=(512,512))

Load Particle Tracking Challenge 2D ground truth from XML and convert to SMLMData format.

# Arguments
- `gt::TrackingChallengeGT`: Specification of ground truth XML file
- `image_size::Tuple{Int,Int}=(512,512)`: Image size in pixels (x, y)

# Returns
- `ChallengeSMLD{Float64, Emitter2DFit{Float64}}`: Converted ground truth data

# XML Format
The expected XML structure is:
```xml
<?xml version="1.0"?>
<TrackContestISBI2012>
  <particle nSpots="N">
    <detection t="0" x="10.5" y="20.3" z="0.0" />
    <detection t="1" x="11.2" y="21.1" z="0.0" />
    ...
  </particle>
  <particle nSpots="M">
    ...
  </particle>
</TrackContestISBI2012>
```

# Notes
- Coordinates are in pixels (center of first pixel = 0.0)
- Frame numbers are integers (may be 0-indexed or 1-indexed)
- Each particle element represents one track
- Ground truth has zero uncertainty (perfect localization)
"""
function load_challenge_gt_2d(gt::TrackingChallengeGT;
                              image_size::Tuple{Int,Int}=(512,512))

    # Load and parse XML file
    file_path = joinpath(gt.filepath, gt.filename)

    if !isfile(file_path)
        error("Ground truth file not found: $(file_path)")
    end

    # Parse XML
    xdoc = parse_file(file_path)
    xroot = root(xdoc)

    # Initialize emitter storage
    emitters = Emitter2DFit{Float64}[]
    emitter_id = 1
    track_id = 1

    max_frame = 0
    min_frame = typemax(Int)

    # Iterate through particles (tracks)
    for particle_elem in child_elements(xroot)
        if name(particle_elem) != "particle"
            continue
        end

        # Get number of detections in this track
        n_spots_str = attribute(particle_elem, "nSpots")
        n_spots = n_spots_str === nothing ? 0 : parse(Int, n_spots_str)

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

            # Parse coordinates
            frame = parse(Int, t_str)
            x_pixel = parse(Float64, x_str)
            y_pixel = parse(Float64, y_str)

            # Convert from pixel coordinates to microns
            x_micron = x_pixel * gt.pixel_size
            y_micron = y_pixel * gt.pixel_size

            # Track min/max frame
            max_frame = max(max_frame, frame)
            min_frame = min(min_frame, frame)

            # Create emitter (ground truth = zero uncertainty)
            push!(emitters, Emitter2DFit{Float64}(
                x_micron,
                y_micron,
                1000.0,  # Arbitrary photon count (ground truth)
                0.0,     # Background
                0.0,     # σ_x (perfect localization)
                0.0,     # σ_y (perfect localization)
                0.0,     # σ_photons
                0.0;     # σ_bg
                frame=frame + 1,  # Convert to 1-indexed if needed
                dataset=1,
                track_id=track_id,
                id=emitter_id
            ))

            emitter_id += 1
        end

        track_id += 1
    end

    # Free XML document
    free(xdoc)

    # Create camera
    camera = IdealCamera(1:image_size[1], 1:image_size[2], gt.pixel_size)

    # Calculate number of frames
    n_frames = max_frame - min_frame + 1

    # Metadata
    metadata = Dict{String,Any}(
        "original_file" => gt.filename,
        "source" => "Particle Tracking Challenge",
        "method" => "Ground Truth",
        "pixel_size" => gt.pixel_size,
        "image_size" => image_size,
        "n_tracks" => track_id - 1,
        "n_detections" => length(emitters),
        "frame_range" => (min_frame, max_frame)
    )

    return ChallengeSMLD{Float64, Emitter2DFit{Float64}}(
        emitters,
        camera,
        n_frames,
        1,
        metadata
    )
end

"""
    load_challenge_gt_3d(gt::TrackingChallengeGT; image_size::Tuple{Int,Int}=(512,512))

Load Particle Tracking Challenge 3D ground truth from XML and convert to SMLMData format.

Similar to `load_challenge_gt_2d` but includes z-coordinates and uses `Emitter3DFit`.

# Arguments
- `gt::TrackingChallengeGT`: Specification of ground truth XML file
- `image_size::Tuple{Int,Int}=(512,512)`: Image size in pixels (x, y)

# Returns
- `ChallengeSMLD{Float64, Emitter3DFit{Float64}}`: Converted 3D ground truth data
"""
function load_challenge_gt_3d(gt::TrackingChallengeGT;
                              image_size::Tuple{Int,Int}=(512,512))

    # Load and parse XML file
    file_path = joinpath(gt.filepath, gt.filename)

    if !isfile(file_path)
        error("Ground truth file not found: $(file_path)")
    end

    xdoc = parse_file(file_path)
    xroot = root(xdoc)

    emitters = Emitter3DFit{Float64}[]
    emitter_id = 1
    track_id = 1

    max_frame = 0
    min_frame = typemax(Int)

    # Iterate through particles (tracks)
    for particle_elem in child_elements(xroot)
        if name(particle_elem) != "particle"
            continue
        end

        # Iterate through detections
        for detection_elem in child_elements(particle_elem)
            if name(detection_elem) != "detection"
                continue
            end

            # Extract attributes
            t_str = attribute(detection_elem, "t")
            x_str = attribute(detection_elem, "x")
            y_str = attribute(detection_elem, "y")
            z_str = attribute(detection_elem, "z")

            if t_str === nothing || x_str === nothing || y_str === nothing || z_str === nothing
                @warn "3D detection missing required attributes (t, x, y, z), skipping"
                continue
            end

            # Parse coordinates
            frame = parse(Int, t_str)
            x_pixel = parse(Float64, x_str)
            y_pixel = parse(Float64, y_str)
            z_pixel = parse(Float64, z_str)

            # Convert to microns
            x_micron = x_pixel * gt.pixel_size
            y_micron = y_pixel * gt.pixel_size
            z_micron = z_pixel * gt.pixel_size

            max_frame = max(max_frame, frame)
            min_frame = min(min_frame, frame)

            # Create 3D emitter
            push!(emitters, Emitter3DFit{Float64}(
                x_micron,
                y_micron,
                z_micron,
                1000.0,  # Photons
                0.0,     # Background
                0.0,     # σ_x
                0.0,     # σ_y
                0.0,     # σ_z
                0.0,     # σ_photons
                0.0;     # σ_bg
                frame=frame + 1,
                dataset=1,
                track_id=track_id,
                id=emitter_id
            ))

            emitter_id += 1
        end

        track_id += 1
    end

    free(xdoc)

    camera = IdealCamera(1:image_size[1], 1:image_size[2], gt.pixel_size)
    n_frames = max_frame - min_frame + 1

    metadata = Dict{String,Any}(
        "original_file" => gt.filename,
        "source" => "Particle Tracking Challenge",
        "method" => "Ground Truth",
        "pixel_size" => gt.pixel_size,
        "image_size" => image_size,
        "n_tracks" => track_id - 1,
        "n_detections" => length(emitters),
        "frame_range" => (min_frame, max_frame)
    )

    return ChallengeSMLD{Float64, Emitter3DFit{Float64}}(
        emitters,
        camera,
        n_frames,
        1,
        metadata
    )
end

"""
    load_challenge_gt(gt::TrackingChallengeGT; kwargs...)

Automatically load 2D or 3D ground truth based on gt.is_3d flag.

# Arguments
- `gt::TrackingChallengeGT`: Specification of ground truth XML file
- `kwargs...`: Additional arguments passed to load_challenge_gt_2d or load_challenge_gt_3d

# Returns
- `ChallengeSMLD`: Converted ground truth data (2D or 3D)
"""
function load_challenge_gt(gt::TrackingChallengeGT; kwargs...)
    if gt.is_3d
        return load_challenge_gt_3d(gt; kwargs...)
    else
        return load_challenge_gt_2d(gt; kwargs...)
    end
end
