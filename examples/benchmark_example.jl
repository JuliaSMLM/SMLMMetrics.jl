"""
Example: Benchmarking Tracking Algorithms with Particle Tracking Challenge Data

This example demonstrates how to:
1. Load ground truth from Particle Tracking Challenge XML
2. Load tracking results from SMITE, u-track, and BNP-Track
3. Compare all three algorithms against ground truth
4. Generate a performance report

Author: Claude Code
Date: 2025
"""

using SMLMMetrics

println("="^70)
println("  Particle Tracking Algorithm Benchmark")
println("="^70)

## Step 1: Load Ground Truth
println("\n[1/4] Loading ground truth from Particle Tracking Challenge...")

# Specify ground truth file
gt_spec = TrackingChallengeGT(
    "challenge_data/scenario1/",  # Directory containing XML file
    "scenario1_GT.xml",           # Ground truth XML file
    pixel_size=0.1,               # 100 nm pixels
    is_3d=false                   # 2D tracking
)

# Load ground truth
try
    ground_truth = load_challenge_gt_2d(gt_spec, image_size=(512, 512))

    println("  ✓ Ground truth loaded successfully")
    println("    - Tracks: ", ground_truth.metadata["n_tracks"])
    println("    - Detections: ", ground_truth.metadata["n_detections"])
    println("    - Frames: ", ground_truth.metadata["frame_range"])
catch e
    println("  ✗ Error loading ground truth: ", e)
    println("  → Make sure to download Particle Tracking Challenge data first!")
    println("  → Website: http://bioimageanalysis.org/track/")
    exit(1)
end

## Step 2: Load Tracking Results
println("\n[2/4] Loading tracking results from all algorithms...")

results = Dict()

# Load SMITE results
try
    results["SMITE"] = load_smite_2d(
        SmiteSMD("results/scenario1/", "smite_output.mat")
    )
    println("  ✓ SMITE results loaded")
catch e
    println("  ✗ SMITE results not found: ", e)
end

# Load u-track results
try
    results["u-track"] = load_utrack_2d(
        UTrackSMD("results/scenario1/", "utrack_output.mat"),
        flatten_compound=true
    )
    println("  ✓ u-track results loaded")
catch e
    println("  ✗ u-track results not found: ", e)
end

# Load BNP-Track results
try
    results["BNP-Track"] = load_bnptrack_2d(
        BNPTrackSMD("results/scenario1/", "bnp_chain.mat"),
        use_map=true,
        burn_in=100
    )
    println("  ✓ BNP-Track results loaded")
catch e
    println("  ✗ BNP-Track results not found: ", e)
end

if isempty(results)
    println("\n  ERROR: No tracking results found!")
    println("  → Process the challenge images with SMITE, u-track, and BNP-Track first")
    exit(1)
end

## Step 3: Compute Metrics
println("\n[3/4] Computing performance metrics...")

# Define evaluation parameters
cutoff = [50.0, 50.0]  # 50 nm matching distance threshold
α = [1e-2, 1e-2]       # Dimensional weighting for RMSE

# Storage for results
jaccard_scores = Dict()
rmse_scores = Dict()
efficiency_scores = Dict()

for (name, result) in results
    println("  → Evaluating ", name, "...")

    # Jaccard Index (overlap metric)
    jaccard_scores[name] = jaccard(ground_truth, result, cutoff)

    # RMSE (localization accuracy)
    rmse_scores[name] = rmse(ground_truth, result, α=α)

    # Efficiency (combined metric)
    efficiency_scores[name] = efficiency(ground_truth, result, cutoff, α=α)
end

println("  ✓ All metrics computed")

## Step 4: Generate Report
println("\n[4/4] Performance Report")
println("="^70)

# Sort algorithms by efficiency (best first)
sorted_names = sort(collect(keys(efficiency_scores)),
                    by=name -> efficiency_scores[name],
                    rev=true)

println("\nEvaluation Parameters:")
println("  - Matching threshold: ", cutoff[1], " nm")
println("  - RMSE weighting α: ", α)

println("\n" * "─"^70)
println("Metric              ", join([rpad(name, 15) for name in sorted_names]))
println("─"^70)

# Jaccard Index (higher is better, 0-1 range)
print("Jaccard Index       ")
for name in sorted_names
    @printf("%-15.4f", jaccard_scores[name])
end
println()

# RMSE (lower is better, in nm)
print("RMSE (nm)           ")
for name in sorted_names
    @printf("%-15.2f", rmse_scores[name] * 1000)  # Convert to nm
end
println()

# Efficiency (higher is better, 0-1 range)
print("Efficiency          ")
for name in sorted_names
    @printf("%-15.4f", efficiency_scores[name])
end
println()

println("─"^70)

# Ranking
println("\n🏆 Algorithm Ranking (by Efficiency):")
for (i, name) in enumerate(sorted_names)
    medal = i == 1 ? "🥇" : i == 2 ? "🥈" : i == 3 ? "🥉" : "  "
    @printf("%s %d. %-12s (%.4f)\n", medal, i, name, efficiency_scores[name])
end

println("\n" * "="^70)
println("Benchmark Complete!")
println("="^70)

# Optional: Save results to file
println("\nSaving results to benchmark_results.txt...")
open("benchmark_results.txt", "w") do io
    println(io, "Particle Tracking Algorithm Benchmark Results")
    println(io, "=" ^ 50)
    println(io, "\nScenario: scenario1")
    println(io, "Date: ", Dates.now())
    println(io, "\nEvaluation Parameters:")
    println(io, "  Matching threshold: ", cutoff[1], " nm")
    println(io, "  RMSE weighting α: ", α)
    println(io, "\nResults:")
    for name in sorted_names
        println(io, "\n", name, ":")
        println(io, "  Jaccard Index: ", jaccard_scores[name])
        println(io, "  RMSE: ", rmse_scores[name] * 1000, " nm")
        println(io, "  Efficiency: ", efficiency_scores[name])
    end
end
println("  ✓ Results saved")
