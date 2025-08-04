# Usage Examples for the New SMLMMetrics

using SMLMMetrics
using LinearAlgebra

# ============================================================================
# EXAMPLE 1: Basic Usage with Coordinate Arrays
# ============================================================================

# Generate example data
ground_truth = rand(2, 100)  # 100 2D points
estimated = ground_truth + 0.1 * randn(2, 100)  # Add some noise

# Define cutoff (gate parameter)
cutoff = [0.5, 0.5]  # 0.5 units in each dimension

# Calculate all metrics
α_score = alpha(ground_truth, estimated, cutoff)
β_score = beta(ground_truth, estimated, cutoff)
jsc_score = jaccard(ground_truth, estimated, cutoff)
jscθ_score = jaccard_tracks(ground_truth, estimated, cutoff)
rmse_score = rmse(ground_truth, estimated, [0.01, 0.01])

println("Tracking Performance Metrics:")
println("α (alpha): $(round(α_score, digits=3))")
println("β (beta): $(round(β_score, digits=3))")
println("JSC (point-level Jaccard): $(round(jsc_score, digits=3))")
println("JSCθ (track-level Jaccard): $(round(jscθ_score, digits=3))")
println("RMSE: $(round(rmse_score, digits=3))")

# ============================================================================
# EXAMPLE 2: Comprehensive Evaluation Function
# ============================================================================

"""
    evaluate_tracking_performance(ground_truth, estimated, cutoff; α_weights=[0.01, 0.01])

Comprehensive evaluation of tracking performance using all five metrics from the paper.
"""
function evaluate_tracking_performance(ground_truth, estimated, cutoff; α_weights=[0.01, 0.01])
    results = Dict{Symbol, Float64}()
    
    # Calculate track-level metrics (α, β, JSCθ)
    results[:alpha] = alpha(ground_truth, estimated, cutoff)
    results[:beta] = beta(ground_truth, estimated, cutoff)
    results[:jaccard_tracks] = jaccard_tracks(ground_truth, estimated, cutoff)
    
    # Calculate point-level metrics (JSC, RMSE)
    results[:jaccard_points] = jaccard(ground_truth, estimated, cutoff)
    results[:rmse] = rmse(ground_truth, estimated, α_weights)
    
    # Calculate efficiency (composite metric)
    results[:efficiency] = efficiency(ground_truth, estimated, cutoff, α_weights)
    
    return results
end

# Example usage
results = evaluate_tracking_performance(ground_truth, estimated, cutoff)

println("\nComprehensive Evaluation Results:")
for (metric, value) in results
    println("$(metric): $(round(value, digits=4))")
end

# ============================================================================
# EXAMPLE 3: Comparing Different Tracking Methods
# ============================================================================

"""
    compare_tracking_methods(ground_truth, method_results::Dict, cutoff)

Compare multiple tracking methods using all available metrics.
"""
function compare_tracking_methods(ground_truth, method_results::Dict, cutoff)
    comparison = Dict{String, Dict{Symbol, Float64}}()
    
    for (method_name, estimated_tracks) in method_results
        comparison[method_name] = evaluate_tracking_performance(
            ground_truth, estimated_tracks, cutoff
        )
    end
    
    return comparison
end

# Example: Compare three hypothetical tracking methods
method_a = ground_truth + 0.05 * randn(size(ground_truth))  # Low noise
method_b = ground_truth + 0.15 * randn(size(ground_truth))  # Medium noise  
method_c = ground_truth + 0.25 * randn(size(ground_truth))  # High noise

methods = Dict(
    "Method A" => method_a,
    "Method B" => method_b, 
    "Method C" => method_c
)

comparison = compare_tracking_methods(ground_truth, methods, cutoff)

println("\nMethod Comparison:")
println("="^60)
for (method, metrics) in comparison
    println("$method:")
    for (metric, value) in metrics
        println("  $(metric): $(round(value, digits=4))")
    end
    println()
end

# ============================================================================
# EXAMPLE 4: Working with SMLMData Objects
# ============================================================================

# Example for when you have SMLMData objects with 2D emitters
using SMLMData

# Assuming you have two BasicSMLD objects: smld_truth and smld_estimated
# (This is pseudocode - actual usage depends on your data)

function evaluate_smld_tracking(smld_truth, smld_estimated, cutoff)
    """
    Evaluate tracking performance for SMLMData objects.
    """
    
    # Use the SMLMData-specific implementations
    α_score = alpha(smld_truth, smld_estimated, cutoff)
    β_score = beta(smld_truth, smld_estimated, cutoff)
    jsc_score = jaccard(smld_truth, smld_estimated, cutoff)
    jscθ_score = jaccard_tracks(smld_truth, smld_estimated, cutoff)
    rmse_score = rmse(smld_truth, smld_estimated)
    eff_score = efficiency(smld_truth, smld_estimated, cutoff)
    
    return (
        α = α_score,
        β = β_score, 
        JSC = jsc_score,
        JSCθ = jscθ_score,
        RMSE = rmse_score,
        efficiency = eff_score
    )
end

# ============================================================================
# EXAMPLE 5: Understanding the Metrics
# ============================================================================

"""
Demonstrate the differences between the metrics using synthetic examples.
"""
function demonstrate_metric_differences()
    println("Demonstrating Metric Differences")
    println("="^40)
    
    # Perfect matching case
    gt = rand(2, 50)
    perfect = copy(gt)
    
    println("1. Perfect Matching:")
    results = evaluate_tracking_performance(gt, perfect, [0.1, 0.1])
    for (k, v) in results
        println("   $k: $(round(v, digits=3))")
    end
    
    # Small localization errors
    println("\n2. Small Localization Errors:")
    small_error = gt + 0.02 * randn(size(gt))
    results = evaluate_tracking_performance(gt, small_error, [0.1, 0.1])
    for (k, v) in results
        println("   $k: $(round(v, digits=3))")
    end
    
    # Missing detections (fewer estimated points)
    println("\n3. Missing Detections:")
    missing = gt[:, 1:30]  # Remove 20 points
    results = evaluate_tracking_performance(gt, missing, [0.1, 0.1])
    for (k, v) in results
        println("   $k: $(round(v, digits=3))")
    end
    
    # False positives (extra estimated points)
    println("\n4. False Positives:")
    extra_points = rand(2, 20)
    false_pos = hcat(gt, extra_points)
    results = evaluate_tracking_performance(gt, false_pos, [0.1, 0.1])
    for (k, v) in results
        println("   $k: $(round(v, digits=3))")
    end
    
    # Large localization errors
    println("\n5. Large Localization Errors:")
    large_error = gt + 0.3 * randn(size(gt))
    results = evaluate_tracking_performance(gt, large_error, [0.1, 0.1])
    for (k, v) in results
        println("   $k: $(round(v, digits=3))")
    end
end

# Run the demonstration
demonstrate_metric_differences()

# ============================================================================
# EXAMPLE 6: Sensitivity Analysis
# ============================================================================

"""
Analyze sensitivity of metrics to gate parameter (cutoff).
"""
function analyze_gate_sensitivity(ground_truth, estimated)
    gate_values = [0.1, 0.2, 0.5, 1.0, 2.0, 5.0]
    
    println("\nGate Parameter Sensitivity Analysis:")
    println("="^50)
    println("Gate\tα\tβ\tJSC\tJSCθ")
    
    for gate in gate_values
        cutoff = [gate, gate]
        α_val = alpha(ground_truth, estimated, cutoff)
        β_val = beta(ground_truth, estimated, cutoff)
        jsc_val = jaccard(ground_truth, estimated, cutoff)
        jscθ_val = jaccard_tracks(ground_truth, estimated, cutoff)
        
        println("$(gate)\t$(round(α_val,digits=3))\t$(round(β_val,digits=3))\t$(round(jsc_val,digits=3))\t$(round(jscθ_val,digits=3))")
    end
end

# Test with noisy data
noisy_data = ground_truth + 0.3 * randn(size(ground_truth))
analyze_gate_sensitivity(ground_truth, noisy_data)

println("\n" * "="^60)
println("Examples completed! The new metrics provide comprehensive")
println("evaluation of tracking performance as described in the")
println("Chenouard et al. Nature Methods 2014 paper.")
println("="^60)