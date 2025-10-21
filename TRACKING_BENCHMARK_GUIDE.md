# Complete Guide: Benchmarking Particle Tracking Algorithms

This guide walks you through the complete workflow for benchmarking SMITE, u-track, and BNP-Track using the Particle Tracking Challenge datasets with ground truth.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Step-by-Step Workflow](#step-by-step-workflow)
4. [Data Sources](#data-sources)
5. [Running the Benchmark](#running-the-benchmark)
6. [Interpreting Results](#interpreting-results)
7. [Troubleshooting](#troubleshooting)

---

## Overview

**Goal**: Compare the performance of three particle tracking packages on standardized benchmark data with ground truth.

**Tracking Packages**:
- **SMITE**: Single Molecule Imaging Toolbox Extraordinaire (LidkeLab)
- **u-track**: Robust particle tracking (DanuserLab)
- **BNP-Track**: Bayesian Nonparametric Tracking (LabPresse)

**Ground Truth Source**: Particle Tracking Challenge (Chenouard et al., Nature Methods 2014)

**Evaluation Metrics**:
- Jaccard Index (detection overlap)
- RMSE (localization accuracy)
- Efficiency (combined metric)
- Full tracking metrics (α, β, JSC_θ)

---

## Prerequisites

### Software Requirements

1. **Julia** (>= 1.6)
   - SMLMMetrics.jl package (this repository)

2. **MATLAB** (for running tracking algorithms)
   - SMITE toolbox
   - u-track toolbox
   - BNP-Track toolbox

### Julia Packages

All dependencies are automatically installed:
```julia
using Pkg
Pkg.instantiate()  # In the SMLMMetrics project directory
```

**Key Dependencies**:
- `SMLMData.jl` - Data structures for SMLM
- `MAT.jl` - MATLAB file I/O
- `LightXML.jl` - XML parsing for ground truth
- `Hungarian.jl` - Optimal matching
- `Distances.jl` - Distance calculations

---

## Step-by-Step Workflow

### Step 1: Download Particle Tracking Challenge Data

**Option A: Official Website**
```
Website: http://bioimageanalysis.org/track/
```

Download:
- Training image sequences (TIFF stacks)
- Ground truth XML files
- Choose scenarios (e.g., Virus, Vesicle, Receptor, Microtubule)
- Choose SNR levels (high, medium, low)
- Choose density levels (low, medium, high)

**Option B: Alternative Sources**

If the official website is down, search for:
- "ISBI particle tracking challenge datasets"
- Published papers with supplementary data
- Imaging challenge mirrors (e.g., Grand Challenges in Biomedical Image Analysis)

**Organize Data**:
```
challenge_data/
├── virus_SNR7_density_low/
│   ├── images/
│   │   ├── t000.tif
│   │   ├── t001.tif
│   │   ├── ...
│   │   └── t099.tif
│   └── virus_SNR7_low_GT.xml
├── vesicle_SNR4_density_high/
│   └── ...
```

---

### Step 2: Run Tracking Algorithms (MATLAB)

Process the **same image sequences** with all three tracking packages.

#### 2.1 SMITE

```matlab
% In MATLAB with SMITE installed
addpath('path/to/smite');

% Load image sequence
images = loadTiffStack('challenge_data/virus_SNR7_density_low/images/');

% Run SMITE tracking
SMD = smi.SPT.tracking(images, params);

% Save results
save('results/smite_virus_SNR7_low.mat', 'SMD');
```

#### 2.2 u-track

```matlab
% In MATLAB with u-track installed
addpath('path/to/u-track/');

% Set up parameters
param.gapCloseParam.timeWindow = 3;
param.gapCloseParam.minTrackLen = 3;
% ... (see u-track documentation)

% Run tracking
tracksFinal = trackCloseGapsKalman(detectionResults, ...
                                   costMatrices, ...
                                   param.gapCloseParam);

% Save results
save('results/utrack_virus_SNR7_low.mat', 'tracksFinal');
```

#### 2.3 BNP-Track

```matlab
% In MATLAB with BNP-Track installed
cd('path/to/BNP-Track/');

% Load images as 3D array
load('challenge_data/virus_SNR7_density_low/images.mat', 'w');

% Set parameters (modify BNP_track_driver.m)
opts.pixel_size = 0.1;  % 100 nm
opts.t_exp = 0.1 * ones(1, size(w,3));  % Exposure time
% ... (see BNP-Track documentation)

% Run chain
chain = chainer_main([], 0, opts, true, []);
chain = chainer_main(chain, 500, [], true, false);  % 500 iterations

% Save results
save('results/bnp_virus_SNR7_low.mat', 'chain');
```

---

### Step 3: Load and Compare Results (Julia)

```julia
using SMLMMetrics

# Load ground truth
gt = load_challenge_gt(
    TrackingChallengeGT(
        "challenge_data/virus_SNR7_density_low/",
        "virus_SNR7_low_GT.xml",
        pixel_size=0.1,  # 100 nm pixels
        is_3d=false
    ),
    image_size=(512, 512)
)

# Load tracking results
smite_result = load_smite_2d(
    SmiteSMD("results/", "smite_virus_SNR7_low.mat")
)

utrack_result = load_utrack_2d(
    UTrackSMD("results/", "utrack_virus_SNR7_low.mat"),
    flatten_compound=true,
    pixel_size=0.1
)

bnp_result = load_bnptrack_2d(
    BNPTrackSMD("results/", "bnp_virus_SNR7_low.mat"),
    use_map=true,
    burn_in=100,
    pixel_size=0.1
)

# Compare
cutoff = [50.0, 50.0]  # 50 nm matching threshold

println("Jaccard Index (higher is better):")
println("  SMITE:     ", jaccard(gt, smite_result, cutoff))
println("  u-track:   ", jaccard(gt, utrack_result, cutoff))
println("  BNP-Track: ", jaccard(gt, bnp_result, cutoff))

println("\nRMSE (nm, lower is better):")
println("  SMITE:     ", rmse(gt, smite_result) * 1000)
println("  u-track:   ", rmse(gt, utrack_result) * 1000)
println("  BNP-Track: ", rmse(gt, bnp_result) * 1000)
```

---

### Step 4: Generate Full Report

Use the example script:

```bash
julia --project=. examples/benchmark_example.jl
```

This will:
1. Load all data
2. Compute all metrics
3. Generate a formatted report
4. Save results to `benchmark_results.txt`

---

## Data Sources

### Particle Tracking Challenge

**Official**: http://bioimageanalysis.org/track/

**Scenarios Available**:
- Vesicle
- Receptor
- Virus
- Microtubule

**Each scenario has**:
- 3 SNR levels (high/medium/low)
- 3 density levels (low/medium/high)
- 100 frames per sequence
- Ground truth XML with exact positions

**Example Ground Truth XML**:
```xml
<?xml version="1.0"?>
<TrackContestISBI2012>
  <particle nSpots="100">
    <detection t="0" x="45.3" y="67.8" z="0.0" />
    <detection t="1" x="46.1" y="68.2" z="0.0" />
    ...
  </particle>
  ...
</TrackContestISBI2012>
```

### Alternative: Generate Synthetic Data

If challenge data is unavailable, generate synthetic data:

```julia
using SMLMMetrics

# Generate synthetic trajectories
n_particles = 10
n_frames = 100
tracks = generate_synthetic_tracks(n_particles, n_frames,
                                   diffusion=0.05,  # μm²/s
                                   noise=20)  # nm

# Export to TIFF + XML ground truth
export_synthetic_data("synthetic_data/", tracks)
```

*(Note: Synthetic data generation functionality to be added)*

---

## Running the Benchmark

### Quick Start

1. **Download challenge data** → `challenge_data/`
2. **Run SMITE** → `results/smite_*.mat`
3. **Run u-track** → `results/utrack_*.mat`
4. **Run BNP-Track** → `results/bnp_*.mat`
5. **Run benchmark**:
   ```bash
   julia --project=. examples/benchmark_example.jl
   ```

### Batch Processing Multiple Scenarios

```julia
scenarios = [
    "virus_SNR7_low",
    "virus_SNR4_medium",
    "vesicle_SNR7_high",
    # ... add more
]

for scenario in scenarios
    println("\n========== Processing: $scenario ==========")

    # Load ground truth
    gt = load_challenge_gt(...)

    # Load results
    # ... (as above)

    # Compute metrics
    # ... (as above)

    # Save to CSV
    # ... (implement)
end
```

---

## Interpreting Results

### Jaccard Index

**Range**: 0.0 to 1.0 (higher is better)

- **> 0.8**: Excellent detection overlap
- **0.6-0.8**: Good performance
- **0.4-0.6**: Moderate performance
- **< 0.4**: Poor detection

**Interpretation**: Measures the overlap between detected and true localizations.

### RMSE (Root Mean Square Error)

**Range**: 0 to ∞ nm (lower is better)

- **< 20 nm**: Excellent localization precision
- **20-50 nm**: Good precision
- **50-100 nm**: Moderate precision
- **> 100 nm**: Poor precision

**Interpretation**: Average distance error between matched localizations.

### Efficiency

**Range**: 0.0 to 1.0 (higher is better)

- **> 0.8**: Excellent overall performance
- **0.6-0.8**: Good performance
- **0.4-0.6**: Moderate performance
- **< 0.4**: Poor performance

**Interpretation**: Combined metric balancing detection and localization.

### Example Report

```
================================================================================
Metric              SMITE          u-track        BNP-Track
================================================================================
Jaccard Index       0.8523         0.8214         0.7945
RMSE (nm)           24.3           31.7           28.9
Efficiency          0.8891         0.8456         0.8123
================================================================================

🏆 Algorithm Ranking (by Efficiency):
🥇 1. SMITE         (0.8891)
🥈 2. u-track       (0.8456)
🥉 3. BNP-Track     (0.8123)
```

---

## Troubleshooting

### Issue: XML File Not Found

**Error**: `Ground truth file not found: path/to/file.xml`

**Solution**:
- Check file path is correct
- Ensure XML file is in the specified directory
- Try absolute path instead of relative path

### Issue: MATLAB Results Not Loading

**Error**: `Variable 'SMD' not found in smite_results.mat`

**Solution**:
- Verify MATLAB saved the correct variable names
- Check variable names match expectations:
  - SMITE: `SMD`
  - u-track: `tracksFinal`
  - BNP-Track: `chain`

### Issue: Coordinates Don't Match

**Problem**: Metrics show very poor performance despite good visual alignment

**Solution**:
- Verify `pixel_size` parameter matches imaging system
- Check coordinate units (pixels vs microns)
- Ensure frame indexing is consistent (0-indexed vs 1-indexed)

### Issue: Missing Dependencies

**Error**: `LightXML not found`

**Solution**:
```julia
using Pkg
Pkg.resolve()
Pkg.instantiate()
```

---

## Citation

If you use this benchmarking framework in your research, please cite:

**Particle Tracking Challenge**:
```
Chenouard et al., "Objective comparison of particle tracking methods",
Nature Methods, vol. 11, no. 3, pp. 281-289, March 2014
```

**SMLMMetrics.jl**: *(Add your publication when available)*

---

## Additional Resources

- **SMITE**: https://github.com/LidkeLab/smite
- **u-track**: https://github.com/DanuserLab/u-track
- **BNP-Track**: https://github.com/LabPresse/BNP-Track
- **SMLMData.jl**: https://github.com/JuliaSMLM/SMLMData.jl
- **Particle Tracking Challenge**: http://bioimageanalysis.org/track/

---

## Contact & Support

For questions or issues:
1. Open an issue on GitHub
2. Check documentation in `src/io/README.md`
3. Review examples in `examples/`

Happy benchmarking! 🔬
