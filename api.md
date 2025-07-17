# SMLMMetrics.jl API Overview

This document provides a structured overview of the SMLMMetrics.jl package designed for analyzing single molecule localization microscopy (SMLM) data in Julia.

## Why This Overview Exists

### For Humans
- Provides a **concise reference** without diving into full documentation
- Offers **quick-start examples** for common use cases
- Shows **relevant patterns** more clearly than individual docstrings
- Creates an **at-a-glance understanding** of package capabilities

### For AI Assistants
- Enables **better code generation** with correct API patterns
- Provides **structured context** about type hierarchies and relationships
- Offers **consistent examples** to learn from when generating code
- Helps avoid **common pitfalls** or misunderstandings about the API

## Key Concepts

- **Localization Data**: Coordinate positions (x, y, z) of fluorophore detections in microns
- **Ground Truth vs. Detected**: Comparing algorithm outputs against known truth data
- **Jaccard Index**: Similarity metric based on matching localizations within distance thresholds
- **RMSE**: Root Mean Square Error measuring positional accuracy of matched pairs
- **Efficiency**: Combined metric incorporating both detection rate and positional accuracy
- **Dimensional Weighting**: Different precision requirements for lateral (x,y) vs. axial (z) dimensions
- **Hungarian Algorithm**: Optimal assignment algorithm for finding best matches between point sets

## Data Format Support

SMLMMetrics supports two primary data formats:

### 1. Raw Coordinate Arrays
- **Format**: `d × n` matrices where `d` = dimensions (2 or 3), `n` = number of localizations
- **Units**: Coordinates in microns
- **Usage**: Direct numerical analysis without metadata

### 2. SMLMData Integration
- **Format**: `BasicSMLD{T,E}` containers from SMLMData.jl package
- **Emitter Types**: `Emitter2D`, `Emitter2DFit`, `Emitter3D`, `Emitter3DFit`
- **Benefits**: Includes camera information, metadata, and uncertainty estimates

## Core Functions

### Jaccard Index Calculation

```julia
# Basic usage with coordinate arrays
a = [1.0 2.0 3.0; 4.0 5.0 6.0]  # 2×3 array: 3 points in 2D
b = [1.1 2.1 4.0; 4.1 5.1 7.0]  # 2×3 array: 3 points in 2D
cutoff = [0.2, 0.2]               # 0.2 micron tolerance in each dimension

jaccard_index = jaccard(a, b, cutoff)
# Returns: similarity between 0 (no overlap) and 1 (perfect overlap)
```

The Jaccard index is defined as: `J(A,B) = |A ∩ B| / |A ∪ B|`

### Point Matching

```julia
# Find optimal point assignments between datasets
assignment = match(a, b, cutoff)
# Returns: Vector where assignment[i] = index of point in b matched to point i in a
# assignment[i] = 0 means point i in a has no match within cutoff distance

# Example interpretation:
# assignment = [1, 2, 0] means:
# - Point 1 in a matches point 1 in b
# - Point 2 in a matches point 2 in b  
# - Point 3 in a has no match in b
```

### RMSE Calculation

```julia
# Basic RMSE between same-size arrays
rmse_basic = rmse(a, b)

# Weighted RMSE with dimensional weighting
α = [1.0, 2.0]  # Weight y-dimension twice as much as x-dimension
rmse_weighted = rmse(a, b, α)

# RMSE only for matched pairs (using assignment from match function)
assignment = match(a, b, cutoff)
rmse_matched = rmse(a, b, α, assignment)
```

### Efficiency Metric

```julia
# Combined accuracy and detection rate metric
α = [1e-2, 1e-2]  # Dimensional weights (units: μm⁻¹)
efficiency_score = efficiency(a, b, cutoff, α)

# For 3D data with default axial weighting
a_3d = [1.0 2.0; 4.0 5.0; 0.1 0.2]  # 3×2 array
b_3d = [1.1 2.1; 4.1 5.1; 0.0 0.3]  # 3×2 array
cutoff_3d = [0.2, 0.2, 0.5]         # Looser tolerance in z
efficiency_3d = efficiency(a_3d, b_3d, cutoff_3d)
```

## SMLMData Integration

### Working with BasicSMLD Containers

```julia
using SMLMData
using SMLMData: BasicSMLD, Emitter2DFit, IdealCamera

# Create emitters
emitters = [
    Emitter2DFit{Float64}(1.0, 2.0, 1000.0, 10.0, 0.01, 0.01, 50.0, 2.0),
    Emitter2DFit{Float64}(3.0, 4.0, 1200.0, 12.0, 0.01, 0.01, 60.0, 2.0)
]

# Create camera
camera = IdealCamera(512, 512, 0.1)  # 512×512 pixels, 0.1 μm/pixel

# Create SMLD container
smld_a = BasicSMLD(emitters, camera, 1, 1, Dict{String,Any}())

# Similar for ground truth data
smld_b = BasicSMLD(truth_emitters, camera, 1, 1, Dict{String,Any}())

# Use SMLMMetrics functions directly
cutoff = [0.05, 0.05]  # 50 nm tolerance
ji = jaccard(smld_a, smld_b, cutoff)
rmse_val = rmse(smld_a, smld_b, α=[1e-2, 1e-2])
eff = efficiency(smld_a, smld_b, cutoff, α=[1e-2, 1e-2])  # α as keyword for SMLMData
```

### 2D vs 3D Analysis

```julia
# 2D Analysis
using SMLMData: Emitter2DFit
emitters_2d = [Emitter2DFit{Float64}(x, y, photons, bg, σx, σy, σph, σbg) 
               for (...)]
smld_2d = BasicSMLD(emitters_2d, camera, n_frames, n_datasets, metadata)

# 3D Analysis  
using SMLMData: Emitter3DFit
emitters_3d = [Emitter3DFit{Float64}(x, y, z, photons, bg, σx, σy, σz, σph, σbg) 
               for (...)]
smld_3d = BasicSMLD(emitters_3d, camera, n_frames, n_datasets, metadata)

# Functions automatically dispatch based on emitter type
ji_2d = jaccard(smld_2d_a, smld_2d_b, [0.05, 0.05])
ji_3d = jaccard(smld_3d_a, smld_3d_b, [0.05, 0.05, 0.1])

# Note: All functions are exported by SMLMMetrics, so you can use them directly
# after 'using SMLMMetrics' without needing 'SMLMMetrics.function_name'
```

## Common Workflows

### Basic Accuracy Assessment

```julia
using SMLMMetrics

# Load or create your coordinate data
ground_truth = [1.0 2.0 3.0; 4.0 5.0 6.0]  # True positions
detected = [1.1 2.1 3.2; 4.1 5.1 6.2]      # Algorithm output

# Set analysis parameters
cutoff = [0.1, 0.1]    # 100 nm matching tolerance
α = [1e-2, 1e-2]       # Dimensional weights for RMSE

# Calculate metrics
ji = jaccard(ground_truth, detected, cutoff)
rmse_val = rmse(ground_truth, detected, α)
eff = efficiency(ground_truth, detected, cutoff, α)

println("Jaccard Index: $ji")
println("RMSE: $rmse_val μm")
println("Efficiency: $eff")
```

### Detailed Analysis with Matching

```julia
# Find which detections correspond to which ground truth
assignment = match(ground_truth, detected, cutoff)

# Analyze only successfully matched pairs
matched_truth = ground_truth[:, assignment .> 0]
matched_detected = detected[:, assignment[assignment .> 0]]

# Calculate metrics for matched pairs only
rmse_matched = rmse(matched_truth, matched_detected, α)

# Calculate detection statistics
n_truth = size(ground_truth, 2)
n_detected = size(detected, 2)
n_matched = sum(assignment .> 0)

recall = n_matched / n_truth        # Fraction of truth points detected
precision = n_matched / n_detected  # Fraction of detections that are correct

println("Recall: $recall")
println("Precision: $precision") 
println("RMSE (matched only): $rmse_matched μm")
```

### 3D SMLM Analysis

```julia
# 3D coordinate arrays
truth_3d = rand(3, 100) .* [10.0, 10.0, 2.0]'  # 100 points in 10×10×2 μm volume
detected_3d = truth_3d .+ 0.05 .* randn(3, 100)  # Add 50 nm noise

# 3D analysis parameters
cutoff_3d = [0.1, 0.1, 0.2]    # Looser tolerance in z-direction
α_3d = [1e-2, 1e-2, 0.5e-2]    # Less stringent requirement for axial precision

# 3D metrics
ji_3d = jaccard(truth_3d, detected_3d, cutoff_3d)
eff_3d = efficiency(truth_3d, detected_3d, cutoff_3d, α_3d)

# The efficiency metric automatically handles lateral vs axial analysis
println("3D Jaccard Index: $ji_3d")
println("3D Efficiency: $eff_3d")
```

## Complete Example: Algorithm Comparison

```julia
using SMLMMetrics
using SMLMData

# Simulate ground truth localizations
n_molecules = 50
truth_coords = [
    rand(n_molecules) .* 10.0,      # x: 0-10 μm
    rand(n_molecules) .* 10.0,      # y: 0-10 μm
    (rand(n_molecules) .- 0.5) .* 2.0  # z: -1 to +1 μm
]
ground_truth = hcat(truth_coords...)'  # Convert to 3×50 matrix

# Simulate two different algorithms with different characteristics
# Algorithm A: High precision, lower recall
algorithm_a = ground_truth[:, 1:40] .+ 0.02 .* randn(3, 40)  # 40/50 detected, 20nm noise

# Algorithm B: Lower precision, higher recall  
algorithm_b = ground_truth .+ 0.05 .* randn(3, 50)           # 50/50 detected, 50nm noise

# Analysis parameters
cutoff = [0.1, 0.1, 0.2]      # 100nm lateral, 200nm axial tolerance
α = [1e-2, 1e-2, 0.5e-2]      # Standard dimensional weighting

# Compare algorithms
results = Dict()
for (name, data) in [("Algorithm A", algorithm_a), ("Algorithm B", algorithm_b)]
    assignment = match(ground_truth, data, cutoff)
    
    results[name] = Dict(
        "jaccard" => jaccard(ground_truth, data, cutoff),
        "efficiency" => efficiency(ground_truth, data, cutoff, α),
        "recall" => sum(assignment .> 0) / size(ground_truth, 2),
        "precision" => sum(assignment .> 0) / size(data, 2),
        "rmse" => rmse(ground_truth, data, α, assignment)
    )
end

# Display comparison
for (name, metrics) in results
    println("$name:")
    println("  Jaccard Index: $(round(metrics[\"jaccard\"], digits=3))")
    println("  Efficiency: $(round(metrics[\"efficiency\"], digits=3))")
    println("  Recall: $(round(metrics[\"recall\"], digits=3))")
    println("  Precision: $(round(metrics[\"precision\"], digits=3))")
    println("  RMSE: $(round(metrics[\"rmse\"], digits=4)) μm")
    println()
end
```

## Parameter Guidelines

### Cutoff Distances
- **2D lateral**: 50-200 nm typical (0.05-0.2 μm)
- **3D axial**: 100-500 nm typical (0.1-0.5 μm)
- **Guideline**: 2-3× expected localization precision

### Dimensional Weights (α)
- **Lateral (x,y)**: `1e-2 μm⁻¹` (corresponds to 100 nm scale)
- **Axial (z)**: `0.5e-2 μm⁻¹` (corresponds to 200 nm scale)  
- **Default 2D**: `[1e-2, 1e-2]`
- **Default 3D**: `[1e-2, 1e-2, 0.5e-2]`
- **Guideline**: `α = 1 / (2 × expected_precision)`

### Efficiency Interpretation
- **> 0.8**: Excellent performance
- **0.6 - 0.8**: Good performance  
- **0.4 - 0.6**: Moderate performance
- **< 0.4**: Poor performance

## Common Pitfalls and Important Notes

### Data Format Requirements
- **Coordinate arrays must be `d × n`** (dimensions × points), not `n × d`
- **Units must be consistent** across all inputs (recommend microns)
- **SMLMData containers** require matching emitter types between datasets
- **Function exports**: All main functions (`jaccard`, `match`, `rmse`, `efficiency`) are exported by SMLMMetrics
- **Parameter syntax**: For coordinate arrays, α is positional; for SMLMData containers, α is a keyword argument

### Matching Algorithm Limitations
- Uses **Hungarian algorithm** for optimal assignment but computationally expensive for large datasets
- **Large value threshold** (1e6) used to prevent impossible matches - ensure your distances are much smaller
- **One-to-one matching only** - multiple detections of same molecule treated as separate

### Efficiency Metric Specifics
- **Combines Jaccard Index and RMSE** in a non-linear way
- **3D analysis** averages lateral and axial components separately
- **Default weights** assume nanometer-scale precision requirements

### Performance Considerations
- **Matching scales as O(n³)** due to Hungarian algorithm
- **Large datasets** (>1000 points) may benefit from spatial subdivision
- **Repeated analysis** with same parameters can reuse assignment results

## Type Information for AI Assistants

### Function Signatures
```julia
# Core coordinate array functions (α as positional argument)
jaccard(a::Array{<:Real}, b::Array{<:Real}, cutoff::Vector{<:Real}) -> Float64
match(a::Array{<:Real}, b::Array{<:Real}, cutoff::Vector{<:Real}) -> Vector{Int}
rmse(a::Array{<:Real}, b::Array{<:Real}, α::Vector{<:Real}) -> Float64
efficiency(a::Array{<:Real}, b::Array{<:Real}, cutoff::Vector{<:Real}, α::Vector{<:Real}) -> Float64

# SMLMData integration functions (α as keyword argument, exported by SMLMMetrics)
jaccard(a::BasicSMLD{T,E}, b::BasicSMLD{T,E}, cutoff::Vector{<:Real}) where {T,E<:Union{Emitter2D,Emitter2DFit}} -> Float64
jaccard(a::BasicSMLD{T,E}, b::BasicSMLD{T,E}, cutoff::Vector{<:Real}) where {T,E<:Union{Emitter3D,Emitter3DFit}} -> Float64
rmse(a::BasicSMLD{T,E}, b::BasicSMLD{T,E}; α::Vector{<:Real} = [1e-2, 1e-2]) where {T,E<:Union{Emitter2D,Emitter2DFit}} -> Float64
rmse(a::BasicSMLD{T,E}, b::BasicSMLD{T,E}; α::Vector{<:Real} = [1e-2, 1e-2, 0.5e-2]) where {T,E<:Union{Emitter3D,Emitter3DFit}} -> Float64
efficiency(a::BasicSMLD{T,E}, b::BasicSMLD{T,E}, cutoff::Vector{<:Real}; α::Vector{<:Real} = [1e-2, 1e-2]) where {T,E<:Union{Emitter2D,Emitter2DFit}} -> Float64
efficiency(a::BasicSMLD{T,E}, b::BasicSMLD{T,E}, cutoff::Vector{<:Real}; α::Vector{<:Real} = [1e-2, 1e-2, 0.5e-2]) where {T,E<:Union{Emitter3D,Emitter3DFit}} -> Float64
```

### Input Constraints
- **Arrays**: Must have same number of dimensions (rows), can have different numbers of points (columns)
- **Cutoff**: Length must equal number of dimensions
- **α weights**: Length must equal number of dimensions
- **Assignment**: From `match()` function, contains 0 for unmatched points

### Return Types
- **jaccard()**: Float64 ∈ [0, 1]
- **match()**: Vector{Int} with 0-based indexing for unmatched
- **rmse()**: Float64 ≥ 0 in same units as input coordinates
- **efficiency()**: Float64, typically ∈ [-∞, 1] but usually [0, 1] for reasonable data