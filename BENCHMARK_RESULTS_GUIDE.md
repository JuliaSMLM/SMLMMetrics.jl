# Benchmarking Results: SMITE, u-track, and BNP-Track

This guide provides a complete workflow for running benchmarks and saving results when comparing SMITE, u-track, and BNP-Track against Particle Tracking Challenge ground truth.

---

## Quick Start

### 1. Run the Benchmark Script

```julia
using SMLMMetrics
using Printf
using Dates

# Load ground truth
gt = load_challenge_gt_2d(
    TrackingChallengeGT(
        "challenge_data/scenario1/",
        "scenario1_GT.xml",
        pixel_size=0.1,
        is_3d=false
    ),
    image_size=(512, 512)
)

# Load tracking results
smite_result = load_smite_2d(
    SmiteSMD("results/", "smite_output.mat")
)

utrack_result = load_utrack_2d(
    UTrackSMD("results/", "utrack_output.mat"),
    flatten_compound=true,
    pixel_size=0.1
)

bnp_result = load_bnptrack_2d(
    BNPTrackSMD("results/", "bnp_chain.mat"),
    use_map=true,
    burn_in=100,
    pixel_size=0.1
)

# Evaluation parameters
cutoff = [50.0, 50.0]  # 50 nm matching threshold
α = [1e-2, 1e-2]       # Dimensional weighting

# Compute metrics
println("\n" * "="^70)
println("Computing metrics...")
println("="^70)

# SMITE
smite_jaccard = jaccard(gt, smite_result, cutoff)
smite_rmse = rmse(gt, smite_result, α=α) * 1000  # Convert to nm
smite_efficiency = efficiency(gt, smite_result, cutoff, α=α)

# u-track
utrack_jaccard = jaccard(gt, utrack_result, cutoff)
utrack_rmse = rmse(gt, utrack_result, α=α) * 1000
utrack_efficiency = efficiency(gt, utrack_result, cutoff, α=α)

# BNP-Track
bnp_jaccard = jaccard(gt, bnp_result, cutoff)
bnp_rmse = rmse(gt, bnp_result, α=α) * 1000
bnp_efficiency = efficiency(gt, bnp_result, cutoff, α=α)

println("✓ All metrics computed\n")

# Generate and save report
save_benchmark_results(
    "BENCHMARK_RESULTS.md",
    gt, smite_result, utrack_result, bnp_result,
    cutoff, α
)
```

---

## 2. Complete Benchmark Function with Auto-Save

Save this function in your script for easy reuse:

```julia
"""
    save_benchmark_results(filename, gt, smite, utrack, bnp, cutoff, α)

Compute all metrics and save formatted results to markdown file.

# Arguments
- `filename::String`: Output markdown file path
- `gt`: Ground truth SMLD dataset
- `smite`: SMITE tracking results
- `utrack`: u-track tracking results
- `bnp`: BNP-Track tracking results
- `cutoff`: Matching distance threshold [x_nm, y_nm]
- `α`: RMSE dimensional weighting

# Example
```julia
save_benchmark_results(
    "BENCHMARK_RESULTS.md",
    ground_truth, smite_data, utrack_data, bnp_data,
    [50.0, 50.0], [1e-2, 1e-2]
)
```
"""
function save_benchmark_results(filename::String,
                                gt, smite, utrack, bnp,
                                cutoff, α)
    # Compute all metrics
    results = Dict(
        "SMITE" => Dict(
            "jaccard" => jaccard(gt, smite, cutoff),
            "rmse" => rmse(gt, smite, α=α) * 1000,
            "efficiency" => efficiency(gt, smite, cutoff, α=α)
        ),
        "u-track" => Dict(
            "jaccard" => jaccard(gt, utrack, cutoff),
            "rmse" => rmse(gt, utrack, α=α) * 1000,
            "efficiency" => efficiency(gt, utrack, cutoff, α=α)
        ),
        "BNP-Track" => Dict(
            "jaccard" => jaccard(gt, bnp, cutoff),
            "rmse" => rmse(gt, bnp, α=α) * 1000,
            "efficiency" => efficiency(gt, bnp, cutoff, α=α)
        )
    )

    # Sort by efficiency
    sorted_names = sort(collect(keys(results)),
                       by=name -> results[name]["efficiency"],
                       rev=true)

    # Write to markdown file
    open(filename, "w") do io
        # Header
        println(io, "# Particle Tracking Benchmark Results")
        println(io, "")
        println(io, "**Generated**: ", Dates.format(now(), "yyyy-mm-dd HH:MM:SS"))
        println(io, "")
        println(io, "---")
        println(io, "")

        # Ground Truth Info
        println(io, "## Ground Truth Dataset")
        println(io, "")
        println(io, "- **Source**: ", gt.metadata["source"])
        println(io, "- **Original File**: ", gt.metadata["original_file"])
        println(io, "- **Number of Tracks**: ", gt.metadata["n_tracks"])
        println(io, "- **Number of Detections**: ", gt.metadata["n_detections"])
        println(io, "- **Frame Range**: ", gt.metadata["frame_range"])
        println(io, "- **Pixel Size**: ", gt.metadata["pixel_size"], " μm")
        println(io, "- **Image Size**: ", gt.metadata["image_size"])
        println(io, "")
        println(io, "---")
        println(io, "")

        # Evaluation Parameters
        println(io, "## Evaluation Parameters")
        println(io, "")
        println(io, "- **Matching Threshold**: ", cutoff[1], " nm (x), ", cutoff[2], " nm (y)")
        println(io, "- **RMSE Weighting (α)**: ", α)
        println(io, "")
        println(io, "---")
        println(io, "")

        # Results Summary Table
        println(io, "## Performance Metrics Summary")
        println(io, "")
        println(io, "| Algorithm | Jaccard Index ↑ | RMSE (nm) ↓ | Efficiency ↑ |")
        println(io, "|-----------|-----------------|--------------|--------------|")

        for name in sorted_names
            @printf(io, "| %-9s | %.4f          | %.2f         | %.4f       |\n",
                   name,
                   results[name]["jaccard"],
                   results[name]["rmse"],
                   results[name]["efficiency"])
        end

        println(io, "")
        println(io, "*↑ = higher is better, ↓ = lower is better*")
        println(io, "")
        println(io, "---")
        println(io, "")

        # Detailed Results
        println(io, "## Detailed Results")
        println(io, "")

        for name in sorted_names
            println(io, "### ", name)
            println(io, "")

            r = results[name]

            println(io, "**Jaccard Index**: ", @sprintf("%.4f", r["jaccard"]))
            println(io, "- Measures overlap between detected and true localizations")
            println(io, "- Range: 0.0 to 1.0 (higher is better)")

            if r["jaccard"] > 0.8
                println(io, "- **Performance**: Excellent ✓")
            elseif r["jaccard"] > 0.6
                println(io, "- **Performance**: Good")
            elseif r["jaccard"] > 0.4
                println(io, "- **Performance**: Moderate")
            else
                println(io, "- **Performance**: Poor")
            end
            println(io, "")

            println(io, "**RMSE**: ", @sprintf("%.2f", r["rmse"]), " nm")
            println(io, "- Root Mean Square Error (localization precision)")
            println(io, "- Range: 0 to ∞ nm (lower is better)")

            if r["rmse"] < 20
                println(io, "- **Performance**: Excellent ✓")
            elseif r["rmse"] < 50
                println(io, "- **Performance**: Good")
            elseif r["rmse"] < 100
                println(io, "- **Performance**: Moderate")
            else
                println(io, "- **Performance**: Poor")
            end
            println(io, "")

            println(io, "**Efficiency**: ", @sprintf("%.4f", r["efficiency"]))
            println(io, "- Combined metric (detection + localization)")
            println(io, "- Range: 0.0 to 1.0 (higher is better)")

            if r["efficiency"] > 0.8
                println(io, "- **Performance**: Excellent ✓")
            elseif r["efficiency"] > 0.6
                println(io, "- **Performance**: Good")
            elseif r["efficiency"] > 0.4
                println(io, "- **Performance**: Moderate")
            else
                println(io, "- **Performance**: Poor")
            end
            println(io, "")
            println(io, "---")
            println(io, "")
        end

        # Ranking
        println(io, "## Algorithm Ranking")
        println(io, "")
        println(io, "**By Efficiency Score** (combined metric):")
        println(io, "")

        for (i, name) in enumerate(sorted_names)
            medal = i == 1 ? "🥇" : i == 2 ? "🥈" : i == 3 ? "🥉" : "  "
            @printf(io, "%s **%d. %s** — Efficiency: %.4f\n",
                   medal, i, name, results[name]["efficiency"])
        end

        println(io, "")
        println(io, "---")
        println(io, "")

        # Interpretation Guide
        println(io, "## Metric Interpretation")
        println(io, "")
        println(io, "### Jaccard Index")
        println(io, "")
        println(io, "Measures the overlap between detected and ground truth localizations:")
        println(io, "")
        println(io, "```")
        println(io, "J = |A ∩ B| / |A ∪ B|")
        println(io, "```")
        println(io, "")
        println(io, "- **> 0.8**: Excellent detection overlap")
        println(io, "- **0.6-0.8**: Good performance")
        println(io, "- **0.4-0.6**: Moderate performance")
        println(io, "- **< 0.4**: Poor detection")
        println(io, "")

        println(io, "### RMSE (Root Mean Square Error)")
        println(io, "")
        println(io, "Average distance error between matched localizations:")
        println(io, "")
        println(io, "- **< 20 nm**: Excellent localization precision")
        println(io, "- **20-50 nm**: Good precision")
        println(io, "- **50-100 nm**: Moderate precision")
        println(io, "- **> 100 nm**: Poor precision")
        println(io, "")

        println(io, "### Efficiency")
        println(io, "")
        println(io, "Combined metric balancing detection and localization:")
        println(io, "")
        println(io, "```")
        println(io, "ε = J × (1 - RMSE_normalized)")
        println(io, "```")
        println(io, "")
        println(io, "- **> 0.8**: Excellent overall performance")
        println(io, "- **0.6-0.8**: Good performance")
        println(io, "- **0.4-0.6**: Moderate performance")
        println(io, "- **< 0.4**: Poor performance")
        println(io, "")

        println(io, "---")
        println(io, "")

        # Footer
        println(io, "## References")
        println(io, "")
        println(io, "- **Particle Tracking Challenge**: Chenouard et al., *Nature Methods* 11, 281-289 (2014)")
        println(io, "- **SMITE**: https://github.com/LidkeLab/smite")
        println(io, "- **u-track**: https://github.com/DanuserLab/u-track")
        println(io, "- **BNP-Track**: https://github.com/LabPresse/BNP-Track")
        println(io, "- **SMLMMetrics.jl**: Julia package for SMLM performance evaluation")
        println(io, "")
        println(io, "---")
        println(io, "")
        println(io, "*Report generated by SMLMMetrics.jl*")
    end

    println("✓ Results saved to: ", filename)
end
```

---

## 3. Example Output Format

The generated markdown file will look like this:

```markdown
# Particle Tracking Benchmark Results

**Generated**: 2025-10-21 14:30:45

---

## Ground Truth Dataset

- **Source**: Particle Tracking Challenge
- **Original File**: virus_SNR7_low_GT.xml
- **Number of Tracks**: 25
- **Number of Detections**: 2450
- **Frame Range**: (0, 99)
- **Pixel Size**: 0.1 μm
- **Image Size**: (512, 512)

---

## Evaluation Parameters

- **Matching Threshold**: 50.0 nm (x), 50.0 nm (y)
- **RMSE Weighting (α)**: [0.01, 0.01]

---

## Performance Metrics Summary

| Algorithm | Jaccard Index ↑ | RMSE (nm) ↓ | Efficiency ↑ |
|-----------|-----------------|--------------|--------------|
| SMITE     | 0.8523          | 24.30        | 0.8891       |
| u-track   | 0.8214          | 31.70        | 0.8456       |
| BNP-Track | 0.7945          | 28.90        | 0.8123       |

*↑ = higher is better, ↓ = lower is better*

---

## Algorithm Ranking

**By Efficiency Score** (combined metric):

🥇 **1. SMITE** — Efficiency: 0.8891
🥈 **2. u-track** — Efficiency: 0.8456
🥉 **3. BNP-Track** — Efficiency: 0.8123

---
```

---

## 4. Batch Processing Multiple Scenarios

To compare across different scenarios (SNR, density, etc.):

```julia
# Define scenarios to test
scenarios = [
    ("virus_SNR7_low", "virus_SNR7_low_GT.xml"),
    ("virus_SNR4_medium", "virus_SNR4_medium_GT.xml"),
    ("vesicle_SNR7_high", "vesicle_SNR7_high_GT.xml")
]

# Process each scenario
for (scenario_name, gt_filename) in scenarios
    println("\n" * "="^70)
    println("Processing: ", scenario_name)
    println("="^70)

    # Load ground truth
    gt = load_challenge_gt_2d(
        TrackingChallengeGT(
            "challenge_data/$(scenario_name)/",
            gt_filename,
            pixel_size=0.1,
            is_3d=false
        ),
        image_size=(512, 512)
    )

    # Load results
    smite = load_smite_2d(SmiteSMD("results/$(scenario_name)/", "smite.mat"))
    utrack = load_utrack_2d(UTrackSMD("results/$(scenario_name)/", "utrack.mat"),
                            flatten_compound=true, pixel_size=0.1)
    bnp = load_bnptrack_2d(BNPTrackSMD("results/$(scenario_name)/", "bnp.mat"),
                          use_map=true, burn_in=100, pixel_size=0.1)

    # Save results
    save_benchmark_results(
        "RESULTS_$(scenario_name).md",
        gt, smite, utrack, bnp,
        [50.0, 50.0], [1e-2, 1e-2]
    )
end

println("\n✓ All scenarios processed!")
```

---

## 5. Export to CSV for Further Analysis

```julia
using CSV, DataFrames

function export_to_csv(results_dict, filename::String)
    # Create DataFrame
    df = DataFrame(
        Algorithm = String[],
        Jaccard = Float64[],
        RMSE_nm = Float64[],
        Efficiency = Float64[]
    )

    # Populate
    for (name, metrics) in results_dict
        push!(df, (
            name,
            metrics["jaccard"],
            metrics["rmse"],
            metrics["efficiency"]
        ))
    end

    # Sort by efficiency
    sort!(df, :Efficiency, rev=true)

    # Save
    CSV.write(filename, df)
    println("✓ CSV saved to: ", filename)
end

# Usage
export_to_csv(results, "benchmark_results.csv")
```

---

## 6. Full Automated Workflow Script

Save as `run_benchmark.jl`:

```julia
#!/usr/bin/env julia

using SMLMMetrics
using Printf
using Dates

println("="^70)
println("  Particle Tracking Algorithm Benchmark")
println("  Automated Workflow with Result Saving")
println("="^70)

# Configuration
const DATA_DIR = "challenge_data/scenario1/"
const GT_FILE = "scenario1_GT.xml"
const RESULTS_DIR = "results/"
const OUTPUT_FILE = "BENCHMARK_RESULTS.md"
const PIXEL_SIZE = 0.1  # μm
const CUTOFF = [50.0, 50.0]  # nm
const ALPHA = [1e-2, 1e-2]

# Step 1: Load Ground Truth
println("\n[1/4] Loading ground truth...")
gt = load_challenge_gt_2d(
    TrackingChallengeGT(DATA_DIR, GT_FILE, pixel_size=PIXEL_SIZE, is_3d=false),
    image_size=(512, 512)
)
println("  ✓ Loaded $(gt.metadata["n_tracks"]) tracks, $(gt.metadata["n_detections"]) detections")

# Step 2: Load Tracking Results
println("\n[2/4] Loading tracking results...")

results = Dict{String, Any}()

try
    results["SMITE"] = load_smite_2d(SmiteSMD(RESULTS_DIR, "smite_output.mat"))
    println("  ✓ SMITE loaded")
catch e
    println("  ✗ SMITE failed: ", e)
end

try
    results["u-track"] = load_utrack_2d(
        UTrackSMD(RESULTS_DIR, "utrack_output.mat"),
        flatten_compound=true, pixel_size=PIXEL_SIZE
    )
    println("  ✓ u-track loaded")
catch e
    println("  ✗ u-track failed: ", e)
end

try
    results["BNP-Track"] = load_bnptrack_2d(
        BNPTrackSMD(RESULTS_DIR, "bnp_chain.mat"),
        use_map=true, burn_in=100, pixel_size=PIXEL_SIZE
    )
    println("  ✓ BNP-Track loaded")
catch e
    println("  ✗ BNP-Track failed: ", e)
end

if isempty(results)
    error("No tracking results could be loaded!")
end

# Step 3: Compute Metrics
println("\n[3/4] Computing metrics...")

metrics = Dict{String, Dict{String, Float64}}()

for (name, data) in results
    println("  → Evaluating ", name)
    metrics[name] = Dict(
        "jaccard" => jaccard(gt, data, CUTOFF),
        "rmse" => rmse(gt, data, α=ALPHA) * 1000,
        "efficiency" => efficiency(gt, data, CUTOFF, α=ALPHA)
    )
end

println("  ✓ All metrics computed")

# Step 4: Save Results
println("\n[4/4] Saving results...")

# Use the save_benchmark_results function defined above
# (Include the function definition in this script or load it from a module)

save_benchmark_results(
    OUTPUT_FILE,
    gt,
    get(results, "SMITE", nothing),
    get(results, "u-track", nothing),
    get(results, "BNP-Track", nothing),
    CUTOFF,
    ALPHA
)

# Print summary to console
println("\n" * "="^70)
println("BENCHMARK COMPLETE!")
println("="^70)
println("\nResults Summary:")
println("-"^70)

sorted_names = sort(collect(keys(metrics)),
                   by=name -> metrics[name]["efficiency"],
                   rev=true)

for name in sorted_names
    m = metrics[name]
    println("\n", name, ":")
    @printf("  Jaccard Index: %.4f\n", m["jaccard"])
    @printf("  RMSE: %.2f nm\n", m["rmse"])
    @printf("  Efficiency: %.4f\n", m["efficiency"])
end

println("\n" * "="^70)
println("Detailed results saved to: ", OUTPUT_FILE)
println("="^70)
```

Run with:
```bash
julia --project=. run_benchmark.jl
```

---

## Next Steps

1. **Run your benchmarks**: Execute the automated script
2. **Review markdown results**: Open the generated `.md` files
3. **Analyze CSV data**: Import into Excel/Python for plots
4. **Compare scenarios**: Run batch processing for multiple datasets
5. **Publish findings**: Use the markdown reports in papers/presentations

---

## Troubleshooting

### Issue: Results file not created
- Check write permissions in current directory
- Verify all data loaded successfully before calling save function

### Issue: Metrics show NaN
- Ensure ground truth and results have overlapping frames
- Check coordinate units match (microns vs pixels)
- Verify pixel_size parameter is correct

### Issue: Missing algorithm results
- Script continues even if one algorithm fails to load
- Check error messages for specific loading issues
- Verify .mat file paths and variable names

---

*For more details, see `TRACKING_BENCHMARK_GUIDE.md` and `IMPLEMENTATION_SUMMARY.md`*
