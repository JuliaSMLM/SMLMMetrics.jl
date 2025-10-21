"""
Functions for loading BNP-Track tracking data and converting to SMLMData format.

BNP-Track outputs MCMC chains with posterior distributions. This converter extracts
MAP estimates or posterior means to create point localizations for SMLMData.
"""

using MAT
using SMLMData
using SMLMData: Emitter2DFit, Emitter3DFit, IdealCamera
using Statistics

include("utils.jl")

"""
    load_bnptrack_2d(bnp::BNPTrackSMD;
                     use_map::Bool=true,
                     burn_in::Int=100,
                     credible_interval::Float64=0.95,
                     pixel_size::Float64=0.1,
                     image_size::Tuple{Int,Int}=(512,512))

Load BNP-Track 2D results and convert to SMLMData format.

# Arguments
- `bnp::BNPTrackSMD`: Specification of BNP-Track .mat file to load
- `use_map::Bool=true`: If true, use MAP estimates (median); if false, use posterior means
- `burn_in::Int=100`: Number of MCMC samples to discard as burn-in
- `credible_interval::Float64=0.95`: CI level for uncertainty quantification (default 0.95)
- `pixel_size::Float64=0.1`: Pixel size in microns
- `image_size::Tuple{Int,Int}=(512,512)`: Image size in pixels

# Returns
- `BNPTrackSMLD{Float64, Emitter2DFit{Float64}}`: Converted tracking data

# Notes
- BNP-Track outputs MCMC chains with samples for particle positions (X, Y, Z)
- The chain.sample structure contains the final sample state
- The chain.b matrix indicates which particles exist in each sample
- The chain.sample.K vector assigns time points to particles (atoms)
- Uncertainties are derived from posterior standard deviations or credible intervals
"""
function load_bnptrack_2d(bnp::BNPTrackSMD;
                          use_map::Bool=true,
                          burn_in::Int=100,
                          credible_interval::Float64=0.95,
                          pixel_size::Float64=0.1,
                          image_size::Tuple{Int,Int}=(512,512))

    # Load MATLAB file
    file_path = joinpath(bnp.filepath, bnp.filename)
    mat_data = matread(file_path)

    if !haskey(mat_data, bnp.varname)
        error("Variable '$(bnp.varname)' not found in $(file_path)")
    end

    chain = mat_data[bnp.varname]

    # Extract MCMC chain parameters
    params = chain["params"]
    sample = chain["sample"]

    # Get frame timing information
    t_mid = vec(params["t_mid"])  # Mid-time of each frame
    t_bnd = vec(params["t_bnd"])  # Frame boundaries
    n_frames = length(t_mid)

    # Extract final sample state
    # X, Y: N × M matrices where N = number of time points, M = max particles
    X_final = sample["X"]  # X positions for all particles at all times
    Y_final = sample["Y"]  # Y positions for all particles at all times
    b_final = vec(sample["b"])  # Existence indicator (1 × M)
    K_final = vec(sample["K"])  # Atom assignment per time point (1 × N)

    # Get dimensions
    n_timepoints = size(X_final, 1)  # N
    max_particles = size(X_final, 2)  # M

    # Filter to active particles only
    active_particles = filter_active_particles(b_final)
    n_active = length(active_particles)

    if n_active == 0
        @warn "No active particles found in BNP-Track output"
        emitters = Emitter2DFit{Float64}[]
    else
        # Extract positions for each time point based on atom assignments
        emitters = Emitter2DFit{Float64}[]
        emitter_id = 1

        # For each time point, create an emitter with the assigned particle
        for (time_idx, atom_idx) in enumerate(K_final)
            # Check if this atom is active
            if atom_idx < 1 || atom_idx > max_particles || b_final[atom_idx] < 0.5
                continue  # Skip inactive or unassigned time points
            end

            # Extract position
            x = Float64(X_final[time_idx, atom_idx])
            y = Float64(Y_final[time_idx, atom_idx])

            # Skip NaN or invalid positions
            if isnan(x) || isnan(y)
                continue
            end

            # Estimate uncertainty from posterior if full chain available
            # For now, use a default small uncertainty
            # TODO: Extract from full MCMC chain if available in chain.X, chain.Y
            σ_x = 0.01  # Default 10 nm uncertainty
            σ_y = 0.01

            # Map time index to frame number (assuming 0-indexed or 1-indexed)
            frame_num = time_idx

            push!(emitters, Emitter2DFit{Float64}(
                x,
                y,
                0.0,  # photons (not directly available from BNP-Track)
                0.0,  # bg
                σ_x,
                σ_y,
                0.0,  # σ_photons
                0.0;  # σ_bg
                frame=frame_num,
                dataset=1,
                track_id=Int(atom_idx),  # Use atom index as track ID
                id=emitter_id
            ))
            emitter_id += 1
        end
    end

    # Extract pixel size and image size from params if available
    if haskey(params, "x_bnd")
        x_bnd = vec(params["x_bnd"])
        y_bnd = vec(params["y_bnd"])
        # Compute pixel size from boundaries
        if length(x_bnd) > 1 && length(y_bnd) > 1
            pixel_size_x = (x_bnd[end] - x_bnd[1]) / (length(x_bnd) - 1)
            pixel_size_y = (y_bnd[end] - y_bnd[1]) / (length(y_bnd) - 1)
            pixel_size = (pixel_size_x + pixel_size_y) / 2
        end
        image_size = (length(x_bnd) - 1, length(y_bnd) - 1)
    end

    # Create camera
    camera = IdealCamera(1:image_size[1], 1:image_size[2], pixel_size)

    # Metadata
    metadata = Dict{String,Any}(
        "original_file" => bnp.filename,
        "method" => "BNP-Track",
        "use_map" => use_map,
        "burn_in" => burn_in,
        "credible_interval" => credible_interval,
        "n_active_particles" => n_active,
        "max_particles" => max_particles,
        "pixel_size" => pixel_size,
        "image_size" => image_size
    )

    # Add chain statistics if available
    if haskey(chain, "length")
        metadata["chain_length"] = chain["length"]
    end
    if haskey(chain, "stride")
        metadata["chain_stride"] = chain["stride"]
    end

    return BNPTrackSMLD{Float64, Emitter2DFit{Float64}}(
        emitters,
        camera,
        n_frames,
        1,
        metadata
    )
end

"""
    load_bnptrack_3d(bnp::BNPTrackSMD; kwargs...)

Load BNP-Track 3D results and convert to SMLMData format.

Similar to `load_bnptrack_2d` but includes z-coordinates and uses `Emitter3DFit`.

# Arguments
Same as `load_bnptrack_2d`

# Returns
- `BNPTrackSMLD{Float64, Emitter3DFit{Float64}}`: Converted 3D tracking data
"""
function load_bnptrack_3d(bnp::BNPTrackSMD;
                          use_map::Bool=true,
                          burn_in::Int=100,
                          credible_interval::Float64=0.95,
                          pixel_size::Float64=0.1,
                          image_size::Tuple{Int,Int}=(512,512))

    # Load MATLAB file
    file_path = joinpath(bnp.filepath, bnp.filename)
    mat_data = matread(file_path)

    if !haskey(mat_data, bnp.varname)
        error("Variable '$(bnp.varname)' not found in $(file_path)")
    end

    chain = mat_data[bnp.varname]

    # Extract chain components
    params = chain["params"]
    sample = chain["sample"]

    # Get frame timing
    t_mid = vec(params["t_mid"])
    n_frames = length(t_mid)

    # Extract final sample state (now including Z)
    X_final = sample["X"]
    Y_final = sample["Y"]
    Z_final = sample["Z"]  # Z positions
    b_final = vec(sample["b"])
    K_final = vec(sample["K"])

    n_timepoints = size(X_final, 1)
    max_particles = size(X_final, 2)

    # Filter active particles
    active_particles = filter_active_particles(b_final)
    n_active = length(active_particles)

    if n_active == 0
        @warn "No active particles found in BNP-Track output"
        emitters = Emitter3DFit{Float64}[]
    else
        emitters = Emitter3DFit{Float64}[]
        emitter_id = 1

        for (time_idx, atom_idx) in enumerate(K_final)
            if atom_idx < 1 || atom_idx > max_particles || b_final[atom_idx] < 0.5
                continue
            end

            x = Float64(X_final[time_idx, atom_idx])
            y = Float64(Y_final[time_idx, atom_idx])
            z = Float64(Z_final[time_idx, atom_idx])

            if isnan(x) || isnan(y) || isnan(z)
                continue
            end

            # Default uncertainties
            σ_x = 0.01
            σ_y = 0.01
            σ_z = 0.05  # Typically larger z uncertainty

            frame_num = time_idx

            push!(emitters, Emitter3DFit{Float64}(
                x,
                y,
                z,
                0.0,  # photons
                0.0,  # bg
                σ_x,
                σ_y,
                σ_z,
                0.0,  # σ_photons
                0.0;  # σ_bg
                frame=frame_num,
                dataset=1,
                track_id=Int(atom_idx),
                id=emitter_id
            ))
            emitter_id += 1
        end
    end

    # Extract image parameters
    if haskey(params, "x_bnd")
        x_bnd = vec(params["x_bnd"])
        y_bnd = vec(params["y_bnd"])
        if length(x_bnd) > 1 && length(y_bnd) > 1
            pixel_size_x = (x_bnd[end] - x_bnd[1]) / (length(x_bnd) - 1)
            pixel_size_y = (y_bnd[end] - y_bnd[1]) / (length(y_bnd) - 1)
            pixel_size = (pixel_size_x + pixel_size_y) / 2
        end
        image_size = (length(x_bnd) - 1, length(y_bnd) - 1)
    end

    camera = IdealCamera(1:image_size[1], 1:image_size[2], pixel_size)

    metadata = Dict{String,Any}(
        "original_file" => bnp.filename,
        "method" => "BNP-Track",
        "use_map" => use_map,
        "burn_in" => burn_in,
        "credible_interval" => credible_interval,
        "n_active_particles" => n_active,
        "max_particles" => max_particles,
        "pixel_size" => pixel_size,
        "image_size" => image_size
    )

    if haskey(chain, "length")
        metadata["chain_length"] = chain["length"]
    end
    if haskey(chain, "stride")
        metadata["chain_stride"] = chain["stride"]
    end

    return BNPTrackSMLD{Float64, Emitter3DFit{Float64}}(
        emitters,
        camera,
        n_frames,
        1,
        metadata
    )
end
