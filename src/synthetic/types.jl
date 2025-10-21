# Type definitions for synthetic data generation

"""
    SyntheticConfig

Configuration for generating synthetic SMLM tracking data using SMLMSim.

# Fields
- `density::Float64`: Particle density (molecules per μm²)
- `box_size::Float64`: Simulation box size (μm)
- `diffusion_coef::Float64`: Diffusion coefficient (μm²/s)
- `dt::Float64`: Timestep (s)
- `t_max::Float64`: Total simulation time (s)
- `camera_framerate::Float64`: Camera frame rate (Hz)
- `camera_exposure::Float64`: Camera exposure time (s)
- `pixel_size::Float64`: Camera pixel size (μm/pixel)
- `image_size::Tuple{Int,Int}`: Image dimensions (width, height) in pixels
- `photons_per_emitter::Float64`: Photon count per emitter
- `background_photons::Float64`: Background photons per pixel
- `psf_width::Float64`: PSF width (μm)
- `is_3d::Bool`: Whether to generate 3D data (default: false)
- `blinking::Bool`: Whether to enable blinking (default: false)
- `k_on::Float64`: On-rate for blinking (1/s, default: 1e10 for no blinking)
- `k_off::Float64`: Off-rate for blinking (1/s, default: 0.0 for no blinking)

# Example
```julia
config = SyntheticConfig(
    density = 0.03,
    box_size = 12.8,
    diffusion_coef = 0.1,
    dt = 0.005,
    t_max = 0.2,
    camera_framerate = 100.0,
    camera_exposure = 0.005,
    pixel_size = 0.1,
    image_size = (128, 128),
    photons_per_emitter = 1e4,
    background_photons = 5.0,
    psf_width = 0.15
)
```
"""
struct SyntheticConfig
    # Simulation parameters
    density::Float64
    box_size::Float64
    diffusion_coef::Float64
    dt::Float64
    t_max::Float64
    camera_framerate::Float64
    camera_exposure::Float64

    # Camera parameters
    pixel_size::Float64
    image_size::Tuple{Int,Int}

    # Fluorophore parameters
    photons_per_emitter::Float64
    background_photons::Float64

    # PSF parameters
    psf_width::Float64

    # Dimensionality
    is_3d::Bool

    # Blinking parameters
    blinking::Bool
    k_on::Float64
    k_off::Float64

    # Inner constructor with defaults
    function SyntheticConfig(;
        density::Float64 = 0.03,
        box_size::Float64 = 12.8,
        diffusion_coef::Float64 = 0.1,
        dt::Float64 = 0.005,
        t_max::Float64 = 0.2,
        camera_framerate::Float64 = 100.0,
        camera_exposure::Float64 = 0.005,
        pixel_size::Float64 = 0.1,
        image_size::Tuple{Int,Int} = (128, 128),
        photons_per_emitter::Float64 = 1e4,
        background_photons::Float64 = 5.0,
        psf_width::Float64 = 0.15,
        is_3d::Bool = false,
        blinking::Bool = false,
        k_on::Float64 = 1e10,
        k_off::Float64 = 0.0
    )
        new(density, box_size, diffusion_coef, dt, t_max, camera_framerate, camera_exposure,
            pixel_size, image_size, photons_per_emitter, background_photons, psf_width,
            is_3d, blinking, k_on, k_off)
    end
end

"""
    SyntheticDataset

Container for synthetic SMLM tracking data including ground truth and noisy observations.

# Fields
- `ground_truth::BasicSMLD`: Perfect localizations with track IDs
- `noisy_data::BasicSMLD`: Localizations with realistic noise and missing detections
- `config::SyntheticConfig`: Configuration used to generate the data
- `n_tracks::Int`: Number of trajectories
- `n_frames::Int`: Number of time frames
- `n_localizations::Int`: Total number of localizations
"""
struct SyntheticDataset{T,E}
    ground_truth::BasicSMLD{T,E}
    noisy_data::BasicSMLD{T,E}
    config::SyntheticConfig
    n_tracks::Int
    n_frames::Int
    n_localizations::Int
end

"""
    PresetConfig

Preset configurations for common benchmarking scenarios.
"""
module Presets
    using ..SyntheticConfig

    """
        brownian_low_density()

    Low density Brownian motion (easy tracking scenario).
    """
    function brownian_low_density()
        return SyntheticConfig(
            density = 0.01,
            diffusion_coef = 0.1,
            photons_per_emitter = 1e4,
            background_photons = 3.0
        )
    end

    """
        brownian_medium_density()

    Medium density Brownian motion (moderate difficulty).
    """
    function brownian_medium_density()
        return SyntheticConfig(
            density = 0.03,
            diffusion_coef = 0.1,
            photons_per_emitter = 1e4,
            background_photons = 5.0
        )
    end

    """
        brownian_high_density()

    High density Brownian motion (difficult tracking scenario).
    """
    function brownian_high_density()
        return SyntheticConfig(
            density = 0.08,
            diffusion_coef = 0.1,
            photons_per_emitter = 1e4,
            background_photons = 8.0
        )
    end

    """
        fast_diffusion()

    Fast diffusing particles (challenging due to motion blur).
    """
    function fast_diffusion()
        return SyntheticConfig(
            density = 0.03,
            diffusion_coef = 0.5,  # 5x faster
            photons_per_emitter = 1e4,
            background_photons = 5.0
        )
    end

    """
        low_snr()

    Low signal-to-noise ratio (low photons, high background).
    """
    function low_snr()
        return SyntheticConfig(
            density = 0.03,
            diffusion_coef = 0.1,
            photons_per_emitter = 3e3,  # Lower photons
            background_photons = 10.0    # Higher background
        )
    end

    """
        with_blinking()

    Brownian motion with fluorophore blinking.
    """
    function with_blinking()
        return SyntheticConfig(
            density = 0.03,
            diffusion_coef = 0.1,
            photons_per_emitter = 1e4,
            background_photons = 5.0,
            blinking = true,
            k_on = 10.0,   # Moderate blinking
            k_off = 5.0
        )
    end
end
