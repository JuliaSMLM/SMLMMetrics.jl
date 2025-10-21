# Export functions for synthetic data

"""
    export_ground_truth_xml(dataset::SyntheticDataset, filepath::String)

Export ground truth to Particle Tracking Challenge XML format.

# Arguments
- `dataset::SyntheticDataset`: The synthetic dataset
- `filepath::String`: Output XML file path

# Example
```julia
export_ground_truth_xml(dataset, "ground_truth.xml")
```
"""
function export_ground_truth_xml(dataset::SyntheticDataset, filepath::String)
    # Use the existing Challenge XML format from io/challenge
    # Group emitters by track_id
    tracks = Dict{Int, Vector}()

    for emitter in dataset.ground_truth.emitters
        if !haskey(tracks, emitter.track_id)
            tracks[emitter.track_id] = []
        end
        push!(tracks[emitter.track_id], emitter)
    end

    # Create XML structure
    using LightXML

    # Create root element
    xdoc = XMLDocument()
    xroot = create_root(xdoc, "TrackContestISBI2012")

    # Add each track as a particle
    for (track_id, emitters) in sort(collect(tracks))
        # Sort emitters by frame
        sort!(emitters, by = e -> e.frame)

        # Create particle element
        particle = new_child(xroot, "particle")
        set_attribute(particle, "nSpots", string(length(emitters)))

        # Add each detection
        for emitter in emitters
            detection = new_child(particle, "detection")
            set_attribute(detection, "t", string(emitter.frame - 1))  # 0-indexed
            set_attribute(detection, "x", string(emitter.x / dataset.config.pixel_size))  # Convert to pixels
            set_attribute(detection, "y", string(emitter.y / dataset.config.pixel_size))

            if dataset.config.is_3d
                set_attribute(detection, "z", string(emitter.z / dataset.config.pixel_size))
            else
                set_attribute(detection, "z", "0.0")
            end
        end
    end

    # Save to file
    save_file(xdoc, filepath)
    println("Ground truth XML saved to: $filepath")
end

"""
    export_ground_truth_mat(dataset::SyntheticDataset, filepath::String)

Export ground truth to MATLAB .mat format.

Creates a structure with:
- `x`, `y`, (`z` for 3D): Position arrays
- `frame`: Frame numbers
- `track_id`: Track identifiers
- `photons`: Photon counts
- `metadata`: Simulation parameters

# Arguments
- `dataset::SyntheticDataset`: The synthetic dataset
- `filepath::String`: Output .mat file path

# Example
```julia
export_ground_truth_mat(dataset, "ground_truth.mat")
```
"""
function export_ground_truth_mat(dataset::SyntheticDataset, filepath::String)
    using MAT

    # Extract data from emitters
    n = length(dataset.ground_truth.emitters)
    x = [e.x for e in dataset.ground_truth.emitters]
    y = [e.y for e in dataset.ground_truth.emitters]
    frame = [e.frame for e in dataset.ground_truth.emitters]
    track_id = [e.track_id for e in dataset.ground_truth.emitters]
    photons = [e.photons for e in dataset.ground_truth.emitters]

    data = Dict(
        "x" => x,
        "y" => y,
        "frame" => frame,
        "track_id" => track_id,
        "photons" => photons,
        "n_tracks" => dataset.n_tracks,
        "n_frames" => dataset.n_frames,
        "n_localizations" => dataset.n_localizations,
        "pixel_size_um" => dataset.config.pixel_size,
        "diffusion_coef_um2_s" => dataset.config.diffusion_coef
    )

    if dataset.config.is_3d
        z = [e.z for e in dataset.ground_truth.emitters]
        data["z"] = z
    end

    matwrite(filepath, data)
    println("Ground truth MAT saved to: $filepath")
end

"""
    export_noisy_data_mat(dataset::SyntheticDataset, filepath::String)

Export noisy localizations to MATLAB .mat format.

Similar to ground truth export but includes localization uncertainties.

# Arguments
- `dataset::SyntheticDataset`: The synthetic dataset
- `filepath::String`: Output .mat file path
"""
function export_noisy_data_mat(dataset::SyntheticDataset, filepath::String)
    using MAT

    # Extract data from noisy emitters
    x = [e.x for e in dataset.noisy_data.emitters]
    y = [e.y for e in dataset.noisy_data.emitters]
    frame = [e.frame for e in dataset.noisy_data.emitters]
    track_id = [e.track_id for e in dataset.noisy_data.emitters]
    photons = [e.photons for e in dataset.noisy_data.emitters]
    σ_x = [e.σ_x for e in dataset.noisy_data.emitters]
    σ_y = [e.σ_y for e in dataset.noisy_data.emitters]

    data = Dict(
        "x" => x,
        "y" => y,
        "frame" => frame,
        "track_id" => track_id,
        "photons" => photons,
        "sigma_x" => σ_x,
        "sigma_y" => σ_y,
        "n_tracks" => dataset.n_tracks,
        "n_frames" => dataset.n_frames,
        "n_localizations" => dataset.n_localizations,
        "pixel_size_um" => dataset.config.pixel_size,
        "diffusion_coef_um2_s" => dataset.config.diffusion_coef
    )

    if dataset.config.is_3d
        z = [e.z for e in dataset.noisy_data.emitters]
        σ_z = [e.σ_z for e in dataset.noisy_data.emitters]
        data["z"] = z
        data["sigma_z"] = σ_z
    end

    matwrite(filepath, data)
    println("Noisy data MAT saved to: $filepath")
end

"""
    save_dataset(dataset::SyntheticDataset, output_dir::String; prefix::String="synthetic")

Save complete synthetic dataset with all formats.

Creates:
- `{prefix}_ground_truth.xml`: Challenge format ground truth
- `{prefix}_ground_truth.mat`: MATLAB ground truth
- `{prefix}_noisy_data.mat`: MATLAB noisy localizations
- `{prefix}_config.txt`: Human-readable configuration

# Arguments
- `dataset::SyntheticDataset`: The dataset to save
- `output_dir::String`: Output directory
- `prefix::String`: Filename prefix (default: "synthetic")

# Returns
- Dictionary with paths to all created files

# Example
```julia
paths = save_dataset(dataset, "benchmark_data", prefix="brownian_medium")
```
"""
function save_dataset(dataset::SyntheticDataset, output_dir::String; prefix::String="synthetic")
    # Create output directory
    mkpath(output_dir)

    paths = Dict{String, String}()

    # Save ground truth XML
    xml_path = joinpath(output_dir, "$(prefix)_ground_truth.xml")
    export_ground_truth_xml(dataset, xml_path)
    paths["ground_truth_xml"] = xml_path

    # Save ground truth MAT
    gt_mat_path = joinpath(output_dir, "$(prefix)_ground_truth.mat")
    export_ground_truth_mat(dataset, gt_mat_path)
    paths["ground_truth_mat"] = gt_mat_path

    # Save noisy data MAT
    noisy_mat_path = joinpath(output_dir, "$(prefix)_noisy_data.mat")
    export_noisy_data_mat(dataset, noisy_mat_path)
    paths["noisy_data_mat"] = noisy_mat_path

    # Save configuration as text
    config_path = joinpath(output_dir, "$(prefix)_config.txt")
    save_config_txt(dataset.config, config_path, dataset)
    paths["config"] = config_path

    println("\nDataset saved to: $output_dir")
    println("  - Ground truth XML: $(basename(xml_path))")
    println("  - Ground truth MAT: $(basename(gt_mat_path))")
    println("  - Noisy data MAT: $(basename(noisy_mat_path))")
    println("  - Configuration: $(basename(config_path))")

    return paths
end

"""
    save_config_txt(config::SyntheticConfig, filepath::String, dataset::SyntheticDataset)

Save human-readable configuration file.
"""
function save_config_txt(config::SyntheticConfig, filepath::String, dataset::SyntheticDataset)
    open(filepath, "w") do io
        println(io, "="^70)
        println(io, "Synthetic SMLM Tracking Dataset Configuration")
        println(io, "="^70)
        println(io)

        println(io, "Dataset Statistics:")
        println(io, "  Number of tracks: $(dataset.n_tracks)")
        println(io, "  Number of frames: $(dataset.n_frames)")
        println(io, "  Total localizations: $(dataset.n_localizations)")
        println(io)

        println(io, "Simulation Parameters:")
        println(io, "  Density: $(config.density) molecules/μm²")
        println(io, "  Box size: $(config.box_size) μm")
        println(io, "  Diffusion coefficient: $(config.diffusion_coef) μm²/s")
        println(io, "  Timestep (dt): $(config.dt) s")
        println(io, "  Total time: $(config.t_max) s")
        println(io, "  Camera frame rate: $(config.camera_framerate) Hz")
        println(io, "  Camera exposure: $(config.camera_exposure) s")
        println(io)

        println(io, "Camera Parameters:")
        println(io, "  Pixel size: $(config.pixel_size) μm/pixel")
        println(io, "  Image size: $(config.image_size[1]) × $(config.image_size[2]) pixels")
        println(io, "  Field of view: $(config.image_size[1] * config.pixel_size) × $(config.image_size[2] * config.pixel_size) μm²")
        println(io)

        println(io, "Fluorophore Parameters:")
        println(io, "  Photons per emitter: $(config.photons_per_emitter)")
        println(io, "  Background photons: $(config.background_photons) per pixel")
        println(io, "  PSF width: $(config.psf_width) μm ($(config.psf_width * 1000) nm)")
        println(io)

        println(io, "Blinking:")
        println(io, "  Enabled: $(config.blinking)")
        if config.blinking
            println(io, "  k_on: $(config.k_on) 1/s")
            println(io, "  k_off: $(config.k_off) 1/s")
        end
        println(io)

        println(io, "Dimensionality: $(config.is_3d ? "3D" : "2D")")
        println(io)

        println(io, "="^70)
    end

    println("Configuration saved to: $filepath")
end
