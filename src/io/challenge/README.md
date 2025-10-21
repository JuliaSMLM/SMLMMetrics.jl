# Particle Tracking Challenge Ground Truth Loader

This module provides functions to load ground truth data from the **Particle Tracking Challenge** (Chenouard et al., Nature Methods 2014) and convert it to SMLMData format for benchmarking particle tracking algorithms.

## Overview

The Particle Tracking Challenge provides standard benchmark datasets with:
- **Computer-generated images** with various scenarios (virus, vesicle, receptor, microtubule)
- **Multiple SNR levels** (signal-to-noise ratios)
- **Multiple particle densities**
- **Ground truth XML files** with exact particle positions and trajectories

**Reference:**
- Website: http://bioimageanalysis.org/track/
- Paper: Chenouard et al., "Objective comparison of particle tracking methods", *Nature Methods*, vol. 11, no. 3, pp. 281-289, March 2014

---

## XML Format

The ground truth is provided in XML format with the following structure:

```xml
<?xml version="1.0"?>
<TrackContestISBI2012>
  <particle nSpots="10">
    <detection t="0" x="10.5" y="20.3" z="0.0" />
    <detection t="1" x="11.2" y="21.1" z="0.0" />
    <detection t="2" x="12.1" y="22.0" z="0.0" />
    ...
  </particle>
  <particle nSpots="15">
    <detection t="0" x="50.7" y="45.2" z="0.0" />
    <detection t="1" x="51.3" y="46.1" z="0.0" />
    ...
  </particle>
</TrackContestISBI2012>
```

### Format Details

- **`<particle>`**: Represents one complete track/trajectory
  - Attribute `nSpots`: Number of detections in this track

- **`<detection>`**: Represents one localization at a specific time point
  - Attribute `t`: Frame number (integer, may be 0-indexed or 1-indexed)
  - Attribute `x`: X position in pixels (floating point)
  - Attribute `y`: Y position in pixels (floating point)
  - Attribute `z`: Z position in pixels (floating point, 0.0 for 2D data)

### Coordinate System

- **Spatial**: Pixel coordinates where center of first pixel = 0.0
- **Temporal**: Integer frame indices
- **Precision**: Floating-point (ground truth = perfect localization)

---

## Usage

### Basic Example: Load 2D Ground Truth

```julia
using SMLMMetrics

# Specify ground truth file
gt_spec = TrackingChallengeGT(
    "path/to/challenge/data/",  # Directory
    "scenario1_GT.xml",         # Filename
    pixel_size=0.1,             # Pixel size in microns
    is_3d=false                 # 2D data
)

# Load ground truth
ground_truth = load_challenge_gt_2d(gt_spec, image_size=(512, 512))

# Inspect
println("Number of tracks: ", ground_truth.metadata["n_tracks"])
println("Number of detections: ", ground_truth.metadata["n_detections"])
println("Frame range: ", ground_truth.metadata["frame_range"])
```

### Load 3D Ground Truth

```julia
# For 3D data
gt_spec_3d = TrackingChallengeGT(
    "path/to/challenge/data/",
    "scenario_3D_GT.xml",
    pixel_size=0.1,
    is_3d=true  # 3D data
)

ground_truth_3d = load_challenge_gt_3d(gt_spec_3d, image_size=(512, 512))
```

### Automatic 2D/3D Detection

```julia
# Automatically load based on is_3d flag
ground_truth = load_challenge_gt(gt_spec)
```

---

## Complete Benchmarking Workflow

### Step 1: Download Challenge Data

1. Visit http://bioimageanalysis.org/track/
2. Download image sequences and ground truth XML files
3. Organize in a directory structure:
   ```
   challenge_data/
   ├── scenario1/
   │   ├── images/
   │   │   ├── t000.tif
   │   │   ├── t001.tif
   │   │   └── ...
   │   └── scenario1_GT.xml
   ├── scenario2/
   │   └── ...
   ```

### Step 2: Run Tracking Algorithms

Process the same image sequences with all three tracking packages:

```bash
# In MATLAB/Octave:
# 1. Run SMITE on images → smite_results.mat
# 2. Run u-track on images → utrack_results.mat
# 3. Run BNP-Track on images → bnp_chain.mat
```

### Step 3: Load and Compare Results

```julia
using SMLMMetrics

# Load ground truth
gt = load_challenge_gt(
    TrackingChallengeGT("challenge_data/scenario1/", "scenario1_GT.xml",
                       pixel_size=0.1, is_3d=false)
)

# Load tracking results
smite_result = load_smite_2d(SmiteSMD("results/", "smite_results.mat"))
utrack_result = load_utrack_2d(UTrackSMD("results/", "utrack_results.mat"))
bnp_result = load_bnptrack_2d(BNPTrackSMD("results/", "bnp_chain.mat"))

# Comparison parameters
cutoff = [50.0, 50.0]  # 50 nm in each dimension
α = [1e-2, 1e-2]       # Weighting for RMSE

# Compute metrics
println("\n========== JACCARD INDEX ==========")
println("SMITE:     ", jaccard(gt, smite_result, cutoff))
println("u-track:   ", jaccard(gt, utrack_result, cutoff))
println("BNP-Track: ", jaccard(gt, bnp_result, cutoff))

println("\n========== RMSE ==========")
println("SMITE:     ", rmse(gt, smite_result, α=α))
println("u-track:   ", rmse(gt, utrack_result, α=α))
println("BNP-Track: ", rmse(gt, bnp_result, α=α))

println("\n========== EFFICIENCY ==========")
println("SMITE:     ", efficiency(gt, smite_result, cutoff, α=α))
println("u-track:   ", efficiency(gt, utrack_result, cutoff, α=α))
println("BNP-Track: ", efficiency(gt, bnp_result, cutoff, α=α))
```

### Step 4: Advanced Tracking Metrics

Use the built-in tracking evaluation module:

```julia
using SMLMMetrics.Tracking

# Convert to Track format
gt_tracks = convert_to_tracks(gt)
smite_tracks = convert_to_tracks(smite_result)

# Evaluate using Chenouard metrics
metrics = evaluate_tracking(gt_tracks, smite_tracks)

println("α (overall quality): ", metrics.α)
println("β (with false positives penalty): ", metrics.β)
println("JSC (position Jaccard): ", metrics.JSC)
println("JSC_θ (track Jaccard): ", metrics.JSC_θ)
println("RMSE: ", metrics.RMSE)
```

---

## Example Output

```julia
julia> ground_truth = load_challenge_gt_2d(gt_spec, image_size=(512, 512))
ChallengeSMLD{Float64, Emitter2DFit{Float64}}:
  - 245 emitters
  - 512×512 image
  - 100 frames
  - Pixel size: 0.1 μm

julia> ground_truth.metadata
Dict{String, Any} with 7 entries:
  "original_file"  => "scenario1_GT.xml"
  "source"         => "Particle Tracking Challenge"
  "method"         => "Ground Truth"
  "pixel_size"     => 0.1
  "image_size"     => (512, 512)
  "n_tracks"       => 25
  "n_detections"   => 245
  "frame_range"    => (0, 99)
```

---

## Features

✅ **Automatic XML parsing** using LightXML.jl
✅ **2D and 3D support** with automatic detection
✅ **Pixel-to-micron conversion** based on pixel_size parameter
✅ **Zero uncertainty** (ground truth = perfect localization)
✅ **Track ID preservation** from particle elements
✅ **Metadata extraction** (number of tracks, detections, frame range)
✅ **Compatible with SMLMMetrics** evaluation functions

---

## Troubleshooting

### XML File Not Found
```julia
ERROR: Ground truth file not found: path/to/file.xml
```
**Solution**: Check the file path and ensure the XML file exists.

### Missing Attributes
```julia
Warning: Detection missing required attributes (t, x, y), skipping
```
**Solution**: Verify the XML file format matches the expected structure.

### Coordinate Conversion Issues
- **Problem**: Coordinates seem wrong after loading
- **Solution**: Verify `pixel_size` parameter matches your imaging system
- **Note**: Challenge coordinates are in pixels (center of first pixel = 0.0)

---

## Implementation Notes

### Coordinate Conversion

The loader automatically converts from pixel coordinates to microns:

```julia
x_micron = x_pixel * pixel_size
y_micron = y_pixel * pixel_size
z_micron = z_pixel * pixel_size
```

### Frame Indexing

The loader converts frame indices to 1-indexed (Julia convention):

```julia
frame_julia = frame_xml + 1
```

Adjust if your challenge data uses 1-indexed frames already.

### Perfect Localization

Ground truth emitters have zero uncertainty:
```julia
σ_x = 0.0  # Perfect localization in x
σ_y = 0.0  # Perfect localization in y
σ_z = 0.0  # Perfect localization in z
```

---

## Related Functions

- `load_smite_2d/3d` - Load SMITE tracking results
- `load_utrack_2d/3d` - Load u-track tracking results
- `load_bnptrack_2d/3d` - Load BNP-Track tracking results
- `jaccard` - Compute Jaccard index between datasets
- `rmse` - Compute root mean square error
- `efficiency` - Compute combined efficiency metric
- `evaluate_tracking` - Full tracking evaluation (Chenouard metrics)

---

## Citation

If you use the Particle Tracking Challenge data in your research, please cite:

```
@article{chenouard2014objective,
  title={Objective comparison of particle tracking methods},
  author={Chenouard, Nicolas and Smal, Ihor and de Chaumont, Fabrice and
          Ma{\v{s}}ka, Martin and others},
  journal={Nature Methods},
  volume={11},
  number={3},
  pages={281--289},
  year={2014},
  publisher={Nature Publishing Group}
}
```

---

## Future Enhancements

- [ ] Support for additional XML format variants
- [ ] Automatic download of challenge datasets
- [ ] Pre-configured scenarios (virus, vesicle, receptor, etc.)
- [ ] Batch processing of multiple scenarios
- [ ] Visualization tools for ground truth trajectories
