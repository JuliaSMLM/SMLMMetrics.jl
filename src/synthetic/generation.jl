# Core synthetic data generation functions using SMLMSim

"""
    generate_synthetic_data(config::SyntheticConfig; seed::Union{Int,Nothing}=nothing)

Generate synthetic SMLM tracking data using SMLMSim.

Returns a `SyntheticDataset` containing:
- Ground truth localizations with perfect positions and track IDs
- Noisy localizations with realistic uncertainties
- Metadata about the simulation

# Arguments
- `config::SyntheticConfig`: Configuration parameters
- `seed::Union{Int,Nothing}`: Random seed for reproducibility (optional)

# Returns
- `SyntheticDataset`: Container with ground truth and noisy data

# Example
```julia
using SMLMMetrics.Synthetic

config = SyntheticConfig(
    density = 0.03,
    diffusion_coef = 0.1,
    t_max = 0.2
)

dataset = generate_synthetic_data(config, seed=42)
println("Generated ", dataset.n_tracks, " tracks")
println("Total localizations: ", dataset.n_localizations)
```
"""
function generate_synthetic_data(config::SyntheticConfig; seed::Union{Int,Nothing}=nothing)
    # Set random seed if provided
    if !isnothing(seed)
        Random.seed!(seed)
    end

    # Create SMLMSim parameters for diffusion simulation
    params = create_smlmsim_params(config)

    # Create camera and molecule
    camera = IdealCamera(config.image_size[1], config.image_size[2], config.pixel_size)
    molecule = GenericFluor(
        photons = config.photons_per_emitter,
        k_off = config.k_off,
        k_on = config.k_on
    )

    # Run SMLMSim simulation
    smld_sim = simulate(params, camera=camera, molecule=molecule)

    # Create ground truth (perfect localizations)
    ground_truth = create_ground_truth(smld_sim, config)

    # Create noisy data (with localization uncertainty)
    noisy_data = add_localization_noise(smld_sim, config)

    # Count trajectories and frames
    n_tracks = length(unique([e.track_id for e in ground_truth.emitters]))
    n_frames = maximum([e.frame for e in ground_truth.emitters])
    n_localizations = length(ground_truth.emitters)

    return SyntheticDataset(
        ground_truth,
        noisy_data,
        config,
        n_tracks,
        n_frames,
        n_localizations
    )
end

"""
    create_smlmsim_params(config::SyntheticConfig)

Convert SyntheticConfig to SMLMSim.DiffusionSMLMParams.
"""
function create_smlmsim_params(config::SyntheticConfig)
    return SMLMSim.DiffusionSMLMParams(
        density = config.density,
        box_size = config.box_size,
        diff_monomer = config.diffusion_coef,
        diff_dimer = 0.0,         # Not used for Brownian motion
        diff_dimer_rot = 0.0,     # Not used
        k_off = 100.0,            # High value to ensure monomers
        r_react = 0.00001,        # Very small to prevent dimer formation
        d_dimer = eps(),          # Not used
        dt = config.dt,
        t_max = config.t_max,
        ndims = config.is_3d ? 3 : 2,
        boundary = "periodic",
        camera_framerate = config.camera_framerate,
        camera_exposure = config.camera_exposure
    )
end

"""
    create_ground_truth(smld::BasicSMLD, config::SyntheticConfig)

Create ground truth data from SMLMSim output with perfect localizations.
This version has zero localization uncertainty.
"""
function create_ground_truth(smld::BasicSMLD{T,E}, config::SyntheticConfig) where {T,E}
    # Ground truth has the same emitters but with zero uncertainty
    gt_emitters = E[]

    for emitter in smld.emitters
        if E <: Emitter2DFit
            gt_emitter = Emitter2DFit{T}(
                emitter.x, emitter.y,
                emitter.photons, emitter.bg,
                0.0, 0.0, 0.0, 0.0;  # Zero uncertainty
                frame = emitter.frame,
                dataset = emitter.dataset,
                track_id = emitter.track_id,
                id = emitter.id
            )
        elseif E <: Emitter3DFit
            gt_emitter = Emitter3DFit{T}(
                emitter.x, emitter.y, emitter.z,
                emitter.photons, emitter.bg,
                0.0, 0.0, 0.0, 0.0, 0.0;  # Zero uncertainty
                frame = emitter.frame,
                dataset = emitter.dataset,
                track_id = emitter.track_id,
                id = emitter.id
            )
        else
            error("Unsupported emitter type: $E")
        end
        push!(gt_emitters, gt_emitter)
    end

    # Return new SMLD with ground truth emitters
    return BasicSMLD{T,E}(gt_emitters, smld.camera, smld.metadata)
end

"""
    add_localization_noise(smld::BasicSMLD, config::SyntheticConfig)

Add realistic localization noise to emitter positions based on Cramér-Rao lower bound.

The localization uncertainty is calculated using:
σ_xy = sqrt((s² + a²/12) / N + (8πs⁴b²) / (a²N²))

where:
- s = PSF width (σ of Gaussian)
- a = pixel size
- N = photon count
- b = background per pixel
"""
function add_localization_noise(smld::BasicSMLD{T,E}, config::SyntheticConfig) where {T,E}
    noisy_emitters = E[]

    for emitter in smld.emitters
        # Calculate localization precision using Cramér-Rao bound
        σ_xy = calculate_localization_precision(
            emitter.photons,
            config.background_photons,
            config.psf_width,
            config.pixel_size
        )

        # Add Gaussian noise to positions
        noisy_x = emitter.x + randn() * σ_xy
        noisy_y = emitter.y + randn() * σ_xy

        if E <: Emitter2DFit
            noisy_emitter = Emitter2DFit{T}(
                noisy_x, noisy_y,
                emitter.photons, emitter.bg,
                σ_xy, σ_xy, 0.0, 0.0;  # Store uncertainty
                frame = emitter.frame,
                dataset = emitter.dataset,
                track_id = emitter.track_id,
                id = emitter.id
            )
        elseif E <: Emitter3DFit
            noisy_z = emitter.z + randn() * σ_xy * 2.0  # z typically 2x worse
            σ_z = σ_xy * 2.0

            noisy_emitter = Emitter3DFit{T}(
                noisy_x, noisy_y, noisy_z,
                emitter.photons, emitter.bg,
                σ_xy, σ_xy, σ_z, 0.0, 0.0;  # Store uncertainty
                frame = emitter.frame,
                dataset = emitter.dataset,
                track_id = emitter.track_id,
                id = emitter.id
            )
        else
            error("Unsupported emitter type: $E")
        end

        push!(noisy_emitters, noisy_emitter)
    end

    # Return new SMLD with noisy emitters
    return BasicSMLD{T,E}(noisy_emitters, smld.camera, smld.metadata)
end

"""
    calculate_localization_precision(photons, bg, psf_width, pixel_size)

Calculate theoretical localization precision using Cramér-Rao lower bound.

Based on Thompson et al., Biophys J. 2002.
"""
function calculate_localization_precision(photons::Float64, bg::Float64,
                                         psf_width::Float64, pixel_size::Float64)
    s = psf_width  # PSF standard deviation in μm
    a = pixel_size # Pixel size in μm
    N = photons    # Photon count
    b = bg         # Background photons per pixel

    # Cramér-Rao lower bound (Thompson formula)
    term1 = (s^2 + a^2/12) / N
    term2 = (8 * π * s^4 * b^2) / (a^2 * N^2)

    σ = sqrt(term1 + term2)

    return σ
end
