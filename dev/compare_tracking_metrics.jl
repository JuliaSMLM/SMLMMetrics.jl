#!/usr/bin/env julia
"""
Compare tracking metrics from all 3 methods with comprehensive visualizations.
Creates comparison table and plots for all 14 Chenouard measures.
"""

using JSON
using CairoMakie
using Printf

# Load metrics from JSON files
metrics_dir = "../results/metrics"
output_dir = "../results/metrics"

println("Loading metrics from JSON files...")
smite_data = JSON.parsefile(joinpath(metrics_dir, "smite_metrics.json"))
utrack_data = JSON.parsefile(joinpath(metrics_dir, "utrack_metrics.json"))
bnptrack_data = JSON.parsefile(joinpath(metrics_dir, "bnptrack_metrics.json"))

methods = ["SMITE", "u-track", "BNP-Track"]
method_data = [smite_data, utrack_data, bnptrack_data]

# Extract all 14 measures
measure_names = [
    "alpha", "beta", "JSC_theta", "JSC",
    "RMSE_theta", "RMSE", "min_error", "max_error",
    "TP_theta", "FN_theta", "FP_theta",
    "TP", "FN", "FP"
]

measure_labels = [
    "α (Overall Quality)", "β (Detection Quality)",
    "JSC_θ (Track Jaccard)", "JSC (Detection Jaccard)",
    "RMSE_θ (μm)", "RMSE (μm)", "Min Error (μm)", "Max Error (μm)",
    "TP_θ (Tracks)", "FN_θ (Tracks)", "FP_θ (Tracks)",
    "TP (Detections)", "FN (Detections)", "FP (Detections)"
]

# Create comparison table
println("\n" * "=" ^ 100)
println("COMPREHENSIVE TRACKING PERFORMANCE COMPARISON")
println("All 14 Chenouard Measures")
println("=" ^ 100)
println()

# Print table header
@printf("%-30s | %-15s | %-15s | %-15s\n", "Measure", "SMITE", "u-track", "BNP-Track")
println("-" ^ 100)

# Store data for plotting
comparison_data = Dict{String, Vector{Float64}}()

for (measure, label) in zip(measure_names, measure_labels)
    values = Float64[]
    @printf("%-30s |", label)

    for data in method_data
        value = data["metrics"][measure]
        push!(values, Float64(value))

        # Format based on measure type
        if measure in ["TP_theta", "FN_theta", "FP_theta", "TP", "FN", "FP"]
            @printf(" %-15d |", Int(value))
        else
            @printf(" %-15.4f |", value)
        end
    end

    comparison_data[measure] = values
    println()
end

println("=" ^ 100)
println()

# Save table to text file
table_file = joinpath(output_dir, "comparison_table.txt")
open(table_file, "w") do io
    println(io, "=" ^ 100)
    println(io, "COMPREHENSIVE TRACKING PERFORMANCE COMPARISON")
    println(io, "All 14 Chenouard Measures")
    println(io, "=" ^ 100)
    println(io)

    @printf(io, "%-30s | %-15s | %-15s | %-15s\n", "Measure", "SMITE", "u-track", "BNP-Track")
    println(io, "-" ^ 100)

    for (measure, label) in zip(measure_names, measure_labels)
        @printf(io, "%-30s |", label)

        for data in method_data
            value = data["metrics"][measure]

            if measure in ["TP_theta", "FN_theta", "FP_theta", "TP", "FN", "FP"]
                @printf(io, " %-15d |", Int(value))
            else
                @printf(io, " %-15.4f |", value)
            end
        end

        println(io)
    end

    println(io, "=" ^ 100)
end

println("✓ Table saved to: $table_file")
println()

# Create comprehensive visualization
println("Creating visualizations...")

# Set up figure with multiple subplots
fig = Figure(size=(1400, 1200), fontsize=12)

# Color scheme for methods
colors = [:steelblue, :coral, :mediumseagreen]

# 1. Quality measures (α, β, JSC_θ, JSC)
ax1 = Axis(fig[1, 1],
    title="Quality Measures (0-1 scale)",
    ylabel="Score",
    xticks=(1:4, ["α", "β", "JSC_θ", "JSC"])
)
ylims!(ax1, 0, 1.1)

quality_measures = ["alpha", "beta", "JSC_theta", "JSC"]
for (i, method) in enumerate(methods)
    values = [comparison_data[m][i] for m in quality_measures]
    barplot!(ax1, (1:4) .+ (i-2)*0.25, values,
             width=0.25, color=colors[i], label=method)
end

axislegend(ax1, position=:lt)
hlines!(ax1, [1.0], color=:gray, linestyle=:dash, linewidth=1)

# 2. RMSE measures
ax2 = Axis(fig[1, 2],
    title="Root Mean Square Error",
    ylabel="RMSE (μm)",
    xticks=(1:2, ["RMSE_θ", "RMSE"]),
)

rmse_measures = ["RMSE_theta", "RMSE"]
for (i, method) in enumerate(methods)
    values = [comparison_data[m][i] for m in rmse_measures]
    barplot!(ax2, (1:2) .+ (i-2)*0.25, values,
             width=0.25, color=colors[i], label=method)
end

# 3. Error range (min/max)
ax3 = Axis(fig[2, 1],
    title="Error Range",
    ylabel="Error (μm)",
    xticks=(1:2, ["Min", "Max"]),
)

error_measures = ["min_error", "max_error"]
for (i, method) in enumerate(methods)
    values = [comparison_data[m][i] for m in error_measures]
    barplot!(ax3, (1:2) .+ (i-2)*0.25, values,
             width=0.25, color=colors[i], label=method)
end

# 4. Track-level counts
ax4 = Axis(fig[2, 2],
    title="Track-Level Counts",
    ylabel="Count",
    xticks=(1:3, ["TP_θ", "FN_θ", "FP_θ"]),
)

track_counts = ["TP_theta", "FN_theta", "FP_theta"]
for (i, method) in enumerate(methods)
    values = [comparison_data[m][i] for m in track_counts]
    barplot!(ax4, (1:3) .+ (i-2)*0.25, values,
             width=0.25, color=colors[i], label=method)
end

# 5. Detection-level counts
ax5 = Axis(fig[3, 1:2],
    title="Detection-Level Counts",
    ylabel="Count",
    xticks=(1:3, ["TP", "FN", "FP"]),
)

detection_counts = ["TP", "FN", "FP"]
for (i, method) in enumerate(methods)
    values = [comparison_data[m][i] for m in detection_counts]
    barplot!(ax5, (1:3) .+ (i-2)*0.25, values,
             width=0.25, color=colors[i], label=method)
end

axislegend(ax5, position=:rt, orientation=:horizontal)

# Add overall title
Label(fig[0, :], "Tracking Performance Comparison: All 14 Chenouard Measures",
      fontsize=18, font=:bold)

# Save figure
plot_file = joinpath(output_dir, "comparison_plot.png")
save(plot_file, fig, px_per_unit=2)
println("✓ Plot saved to: $plot_file")

# Create a second figure focusing on quality metrics
fig2 = Figure(size=(1000, 600), fontsize=14)

ax = Axis(fig2[1, 1],
    title="Overall Performance: Key Quality Metrics",
    ylabel="Score (0-1)",
    xlabel="Metric",
    xticks=(1:4, ["α\n(Overall)", "β\n(Detection)", "JSC_θ\n(Track)", "JSC\n(Detection)"])
)
ylims!(ax, 0, 1.1)

for (i, method) in enumerate(methods)
    values = [comparison_data[m][i] for m in quality_measures]
    barplot!(ax, (1:4) .+ (i-2)*0.25, values,
             width=0.25, color=colors[i], label=method)
end

axislegend(ax, position=:lt, framevisible=true)
hlines!(ax, [1.0], color=:gray, linestyle=:dash, linewidth=1, label="Perfect Score")

# Add text annotations for exact values
for (j, measure) in enumerate(quality_measures)
    for (i, method) in enumerate(methods)
        val = comparison_data[measure][i]
        if val > 0.01  # Only show non-zero values
            text!(ax, j + (i-2)*0.25, val + 0.05,
                  text=@sprintf("%.3f", val),
                  align=(:center, :bottom), fontsize=10)
        end
    end
end

plot_file2 = joinpath(output_dir, "quality_metrics_comparison.png")
save(plot_file2, fig2, px_per_unit=2)
println("✓ Quality metrics plot saved to: $plot_file2")

println()
println("=" ^ 100)
println("Comparison complete!")
println("=" ^ 100)
println()
println("Generated files:")
println("  1. $table_file - Comprehensive comparison table")
println("  2. $plot_file - All 14 measures visualization")
println("  3. $plot_file2 - Key quality metrics focus plot")
println()
