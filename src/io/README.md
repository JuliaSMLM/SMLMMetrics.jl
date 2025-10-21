# IO Module for Tracking Package Converters

This module provides converters to load tracking results from popular particle tracking packages and convert them to SMLMData format for use with SMLMMetrics evaluation functions.

## Supported Packages

### 1. SMITE (Single Molecule Imaging Toolbox Extraordinaire)
- **Source**: [LidkeLab/smite](https://github.com/LidkeLab/smite)
- **File Format**: MATLAB .mat files with SMD (Single Molecule Data) structures
- **Key Fields**: X, Y, Z (positions), Photons, Bg, uncertainties, FrameNum, ConnectID (track ID)
- **Reference Implementation**: Based on [SMLMData.jl](https://github.com/JuliaSMLM/SMLMData.jl)

**Usage**:
```julia
using SMLMMetrics

# Load 2D data
smite_data = load_smite_2d(SmiteSMD("path/to/data/", "smite_output.mat"))

# Load 3D data
smite_data_3d = load_smite_3d(SmiteSMD("path/to/data/", "smite_3d_output.mat"))
```

**Features**:
- Automatic handling of complex numbers (excludes emitters with non-zero imaginary parts)
- Extracts pixel size from metadata
- Maps ConnectID to track_id

---

### 2. u-track
- **Source**: [DanuserLab/u-track](https://github.com/DanuserLab/u-track)
- **File Format**: MATLAB .mat files with `tracksFinal` structure
- **Key Fields**: tracksCoordAmpCG (coordinates), tracksFeatIndxCG (connectivity), seqOfEvents (merging/splitting)
- **Reference**: Jaqaman et al., Nature Methods (2008)

**Usage**:
```julia
using SMLMMetrics

# Load 2D data with compound track flattening
utrack_data = load_utrack_2d(
    UTrackSMD("path/to/data/", "tracksFinal.mat"),
    flatten_compound=true,
    pixel_size=0.1,
    image_size=(512, 512)
)

# Load 3D data
utrack_data_3d = load_utrack_3d(
    UTrackSMD("path/to/data/", "tracksFinal_3d.mat"),
    flatten_compound=true
)
```

**Features**:
- Flattens compound tracks (with merging/splitting) into simple tracks
- Handles gap frames (NaN values)
- Reshapes tracksCoordAmpCG row vector to matrix format
- Extracts uncertainties from coordinate std fields

**Options**:
- `flatten_compound=true`: Split compound tracks into simple tracks (recommended)
- `include_gaps=false`: Skip NaN frames or interpolate positions
- `pixel_size`: Pixel size in microns (default 0.1 μm)
- `image_size`: Image size in pixels (default 512×512)

---

### 3. BNP-Track (Bayesian Nonparametric Tracking)
- **Source**: [LabPresse/BNP-Track](https://github.com/LabPresse/BNP-Track)
- **File Format**: MATLAB .mat files with MCMC chain samples
- **Key Fields**: chain.sample.X, Y, Z (positions), chain.sample.K (atom assignments), chain.sample.b (existence indicators)
- **Reference**: Nature Methods (2024)

**Usage**:
```julia
using SMLMMetrics

# Load 2D data
bnp_data = load_bnptrack_2d(
    BNPTrackSMD("path/to/data/", "chain_output.mat"),
    use_map=true,
    burn_in=100,
    pixel_size=0.133
)

# Load 3D data
bnp_data_3d = load_bnptrack_3d(
    BNPTrackSMD("path/to/data/", "chain_3d_output.mat"),
    use_map=true
)
```

**Features**:
- Extracts MAP estimates (median) or posterior means from MCMC chains
- Handles posterior distributions for uncertainty quantification
- Filters active particles based on existence indicator `b`
- Maps atom assignments `K` to track IDs

**Options**:
- `use_map=true`: Use MAP estimates (median); if false, use posterior means
- `burn_in=100`: Number of MCMC samples to discard
- `credible_interval=0.95`: Credible interval level for uncertainty
- `pixel_size`: Pixel size in microns
- `image_size`: Image size in pixels

---

## Complete Example: Benchmarking Multiple Packages

```julia
using SMLMMetrics

# Load ground truth (synthetic data)
ground_truth = load_smite_2d(SmiteSMD("data/", "ground_truth.mat"))

# Load tracking results from different packages
smite_results = load_smite_2d(SmiteSMD("results/", "smite_tracks.mat"))
utrack_results = load_utrack_2d(UTrackSMD("results/", "utrack_tracks.mat"))
bnp_results = load_bnptrack_2d(BNPTrackSMD("results/", "bnp_chain.mat"))

# Define evaluation parameters
cutoff = [50.0, 50.0]  # 50 nm cutoff in x and y
α = [1e-2, 1e-2]       # Weighting for RMSE

# Compute Jaccard Index
jsc_smite = jaccard(ground_truth, smite_results, cutoff)
jsc_utrack = jaccard(ground_truth, utrack_results, cutoff)
jsc_bnp = jaccard(ground_truth, bnp_results, cutoff)

# Compute RMSE
rmse_smite = rmse(ground_truth, smite_results, α=α)
rmse_utrack = rmse(ground_truth, utrack_results, α=α)
rmse_bnp = rmse(ground_truth, bnp_results, α=α)

# Compute Efficiency
eff_smite = efficiency(ground_truth, smite_results, cutoff, α=α)
eff_utrack = efficiency(ground_truth, utrack_results, cutoff, α=α)
eff_bnp = efficiency(ground_truth, bnp_results, cutoff, α=α)

# Print comparison
println("Jaccard Index:")
println("  SMITE: $jsc_smite")
println("  u-track: $jsc_utrack")
println("  BNP-Track: $jsc_bnp")
println()
println("RMSE:")
println("  SMITE: $rmse_smite")
println("  u-track: $rmse_utrack")
println("  BNP-Track: $rmse_bnp")
println()
println("Efficiency:")
println("  SMITE: $eff_smite")
println("  u-track: $eff_utrack")
println("  BNP-Track: $eff_bnp")
```

---

## Data Structure

All converters output data in SMLMData format:

```julia
# 2D data
smld::SmiteSMLD{Float64, Emitter2DFit{Float64}}
smld::UTrackSMLD{Float64, Emitter2DFit{Float64}}
smld::BNPTrackSMLD{Float64, Emitter2DFit{Float64}}

# 3D data
smld::SmiteSMLD{Float64, Emitter3DFit{Float64}}
smld::UTrackSMLD{Float64, Emitter3DFit{Float64}}
smld::BNPTrackSMLD{Float64, Emitter3DFit{Float64}}
```

Each emitter contains:
- **Position**: `x`, `y` (and `z` for 3D)
- **Photometry**: `photons`, `bg` (background)
- **Uncertainties**: `σ_x`, `σ_y`, `σ_z`, `σ_photons`, `σ_bg`
- **Temporal**: `frame` (frame number)
- **Tracking**: `track_id` (trajectory ID)
- **Identification**: `dataset`, `id`

---

## Implementation Notes

### SMITE
- Based on reference implementation in SMLMData.jl
- Direct field mapping from SMD structure
- Handles complex numbers in position/photometry fields

### u-track
- Compound tracks with merging/splitting are flattened by default
- tracksCoordAmpCG row vector is reshaped to n_frames × 8 matrix
- Gap frames (NaN) are skipped
- seqOfEvents matrix is parsed for event timing

### BNP-Track
- MCMC chain final sample state is extracted
- Atom assignment K maps time points to particles
- Existence indicator b filters active particles
- Default uncertainties are used (posterior analysis TODO)

---

## Future Enhancements

1. **BNP-Track**: Full posterior uncertainty extraction from MCMC chains
2. **u-track**: Gap interpolation support
3. **u-track**: Compound track preservation option
4. **All**: Saving functions to convert SMLMData back to native formats
5. **Testing**: Comprehensive test suite with example data files

---

## Contributing

To add support for a new tracking package:

1. Create a new subdirectory under `src/io/`
2. Implement `types.jl` (data structures)
3. Implement `loading.jl` (conversion logic)
4. Implement `utils.jl` (helper functions)
5. Add exports to `io.jl`
6. Add tests
7. Update documentation

Follow the pattern established by SMITE, u-track, and BNP-Track converters.
