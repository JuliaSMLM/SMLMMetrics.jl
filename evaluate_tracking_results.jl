#!/usr/bin/env julia
"""
Evaluate tracking results from SMITE, u-track, and BNP-Track against ground truth.
Saves metrics results to results/metrics folder.
"""

using SMLMMetrics
using JSON
using Printf
using MAT

# Custom loader for the trajectory format used in these files
function load_custom_trajectories(filepath::String; dt::Float64=0.01)
    mat_data = matread(filepath)

    n_traj = Int(mat_data["n_trajectories"])
    trajectories = SMLMMetrics.Trajectory[]

    # Handle empty trajectory case
    if n_traj == 0
        # Use n_frames from file if available, otherwise default to (1, 1)
        frame_range = haskey(mat_data, "n_frames") ?
                      (1, Int(mat_data["n_frames"])) : (1, 1)

        metadata = Dict{String,Any}(
            "source" => "custom",
            "original_file" => filepath
        )

        if haskey(mat_data, "pixel_size_um")
            metadata["pixel_size"] = mat_data["pixel_size_um"]
        end

        return SMLMMetrics.Tracks(
            trajectories=trajectories,
            frame_range=frame_range,
            metadata=metadata
        )
    end

    min_frame = typemax(Int)
    max_frame = 0

    for i in 1:n_traj
        frames = vec(Int.(mat_data["trajectory_$(i)_frames"]))
        x = vec(Float64.(mat_data["trajectory_$(i)_x"]))
        y = vec(Float64.(mat_data["trajectory_$(i)_y"]))

        # Get trajectory ID if available
        traj_id = haskey(mat_data, "trajectory_$(i)_id") ?
                  Int(mat_data["trajectory_$(i)_id"]) : i

        traj = SMLMMetrics.Trajectory(
            id=traj_id,
            frames=frames,
            x=x,
            y=y,
            z=nothing,
            dt=dt
        )
        push!(trajectories, traj)

        min_frame = min(min_frame, minimum(frames))
        max_frame = max(max_frame, maximum(frames))
    end

    # Use n_frames from file if available
    if haskey(mat_data, "n_frames")
        max_frame = max(max_frame, Int(mat_data["n_frames"]))
    end

    metadata = Dict{String,Any}(
        "source" => "custom",
        "original_file" => filepath
    )

    if haskey(mat_data, "pixel_size_um")
        metadata["pixel_size"] = mat_data["pixel_size_um"]
    end

    return SMLMMetrics.Tracks(
        trajectories=trajectories,
        frame_range=(min_frame, max_frame),
        metadata=metadata
    )
end

# Define file paths
gt_file = "results/tracking/ground_truth.mat"
results_dir = "results/tracking"
metrics_dir = "results/metrics"

# Tracking result files
tracking_files = Dict(
    "smite" => joinpath(results_dir, "smite_trajectories.mat"),
    "utrack" => joinpath(results_dir, "utrack_trajectories.mat"),
    "bnptrack" => joinpath(results_dir, "bnptrack_trajectories.mat")
)

# Create metrics directory if it doesn't exist
mkpath(metrics_dir)

println("=" ^ 70)
println("Tracking Performance Evaluation")
println("=" ^ 70)
println()

# Load ground truth
println("Loading ground truth from: $gt_file")
gt_tracks = load_custom_trajectories(gt_file)
println("  ✓ Loaded $(length(gt_tracks.trajectories)) ground truth trajectories")
println("  Frame range: $(gt_tracks.frame_range)")
println()

# Gate distance for track pairing (in micrometers)
gate = 5.0
println("Using gate distance: $gate μm")
println()

# Evaluate each tracking method
results = Dict()

for (method, filepath) in tracking_files
    println("-" ^ 70)
    println("Evaluating: $(uppercase(method))")
    println("-" ^ 70)

    # Load tracking results using custom loader (all files use the same custom format)
    println("Loading tracking results from: $filepath")
    est_tracks = load_custom_trajectories(filepath)

    println("  ✓ Loaded $(length(est_tracks.trajectories)) estimated trajectories")
    println("  Frame range: $(est_tracks.frame_range)")
    println()

    # Evaluate tracking performance
    println("Computing tracking metrics...")
    metrics = evaluate_tracking(gt_tracks, est_tracks, gate=gate)

    # Store results
    results[method] = metrics

    # Display key metrics
    println()
    println("Results:")
    println("  Overall Quality (α): $(round(metrics.α, digits=4))")
    println("  Detection Quality (β): $(round(metrics.β, digits=4))")
    println("  Track Jaccard (JSC_θ): $(round(metrics.JSC_θ, digits=4))")
    println("  Detection Jaccard (JSC): $(round(metrics.JSC, digits=4))")
    println("  RMSE (track-level): $(round(metrics.RMSE_θ, digits=4)) μm")
    println("  RMSE (detection-level): $(round(metrics.RMSE, digits=4)) μm")
    println("  Min error: $(round(metrics.min_error, digits=4)) μm")
    println("  Max error: $(round(metrics.max_error, digits=4)) μm")
    println()
    println("  Track-level counts:")
    println("    True Positives (TP_θ): $(metrics.TP_θ)")
    println("    False Negatives (FN_θ): $(metrics.FN_θ)")
    println("    False Positives (FP_θ): $(metrics.FP_θ)")
    println()
    println("  Detection-level counts:")
    println("    True Positives (TP): $(metrics.TP)")
    println("    False Negatives (FN): $(metrics.FN)")
    println("    False Positives (FP): $(metrics.FP)")
    println()

    # Save metrics to JSON file
    output_file = joinpath(metrics_dir, "$(method)_metrics.json")

    # Convert metrics to dictionary for JSON serialization
    metrics_dict = Dict(
        "method" => method,
        "gate_distance_um" => gate,
        "ground_truth_file" => gt_file,
        "tracking_results_file" => filepath,
        "num_gt_trajectories" => length(gt_tracks.trajectories),
        "num_est_trajectories" => length(est_tracks.trajectories),
        "gt_frame_range" => collect(gt_tracks.frame_range),
        "est_frame_range" => collect(est_tracks.frame_range),
        "metrics" => Dict(
            "alpha" => metrics.α,
            "beta" => metrics.β,
            "JSC_theta" => metrics.JSC_θ,
            "JSC" => metrics.JSC,
            "RMSE_theta" => metrics.RMSE_θ,
            "RMSE" => metrics.RMSE,
            "min_error" => metrics.min_error,
            "max_error" => metrics.max_error,
            "TP_theta" => metrics.TP_θ,
            "FN_theta" => metrics.FN_θ,
            "FP_theta" => metrics.FP_θ,
            "TP" => metrics.TP,
            "FN" => metrics.FN,
            "FP" => metrics.FP
        )
    )

    open(output_file, "w") do io
        JSON.print(io, metrics_dict, 2)
    end

    println("✓ Metrics saved to: $output_file")
    println()
end

# Create summary comparison
println("=" ^ 70)
println("Summary Comparison")
println("=" ^ 70)
println()

# Print comparison table
println("Method      α       β       JSC_θ   RMSE_θ(μm)  TP_θ  FN_θ  FP_θ")
println("-" ^ 70)
for method in ["smite", "utrack", "bnptrack"]
    m = results[method]
    @printf("%-10s  %.4f  %.4f  %.4f  %-10.4f  %-4d  %-4d  %-4d\n",
            uppercase(method), m.α, m.β, m.JSC_θ, m.RMSE_θ, m.TP_θ, m.FN_θ, m.FP_θ)
end
println()

# Save summary comparison
summary_file = joinpath(metrics_dir, "summary_comparison.json")
summary_dict = Dict(
    "gate_distance_um" => gate,
    "methods" => Dict(
        method => Dict(
            "alpha" => results[method].α,
            "beta" => results[method].β,
            "JSC_theta" => results[method].JSC_θ,
            "RMSE_theta" => results[method].RMSE_θ,
            "TP_theta" => results[method].TP_θ,
            "FN_theta" => results[method].FN_θ,
            "FP_theta" => results[method].FP_θ
        )
        for method in ["smite", "utrack", "bnptrack"]
    )
)

open(summary_file, "w") do io
    JSON.print(io, summary_dict, 2)
end

println("✓ Summary comparison saved to: $summary_file")
println()
println("=" ^ 70)
println("Evaluation Complete!")
println("=" ^ 70)
