# SMLMMetrics.jl

SMLMMetrics is a Julia package for analyzing single molecule localization microscopy (SMLM) data. It provides metrics to evaluate the accuracy and precision of localization algorithms by comparing detected coordinates against ground truth data. 

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaSMLM.github.io/SMLMMetrics.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaSMLM.github.io/SMLMMetrics.jl/dev/)
[![Build Status](https://github.com/JuliaSMLM/SMLMMetrics.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaSMLM/SMLMMetrics.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/JuliaSMLM/SMLMMetrics.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaSMLM/SMLMMetrics.jl)

## Features

- **Jaccard Index**: Similarity metric based on optimal point matching using Hungarian algorithm
- **Root Mean Square Error (RMSE)**: Positional accuracy measurement with dimensional weighting
- **Efficiency Metric**: Combined detection rate and localization accuracy assessment
- **Point Matching**: Optimal assignment between detected and ground truth localizations
- **Multi-dimensional Support**: 2D and 3D localization analysis
- **SMLMData Integration**: Native support for SMLMData.jl v0.3+ containers
- **Flexible Data Formats**: Works with both coordinate arrays and structured data containers

## Installation

To install SMLMMetrics, use the Julia package manager:

```julia
using Pkg
Pkg.add("SMLMMetrics")
```

## Documentation

- [**STABLE**](https://JuliaSMLM.github.io/SMLMMetrics.jl/stable/) - Documentation for the most recently tagged version of SMLMMetrics.
- [**DEVELOPMENT**](https://JuliaSMLM.github.io/SMLMMetrics.jl/dev/) - Documentation for the in-development version of SMLMMetrics.

## Quick Start

```julia
using SMLMMetrics

# Example: Compare two sets of 2D localizations
ground_truth = [1.0 2.0 3.0; 4.0 5.0 6.0]  # 2×3 matrix: 3 points in 2D
detected = [1.05 2.05 3.05; 4.05 5.05 6.05]  # Algorithm output with small noise

# Set analysis parameters
cutoff = [0.1, 0.1]    # 100 nm matching tolerance
α = [1e-2, 1e-2]       # Dimensional weights for RMSE

# Calculate metrics
jaccard_index = jaccard(ground_truth, detected, cutoff)
rmse_value = rmse(ground_truth, detected, α)
efficiency_score = efficiency(ground_truth, detected, cutoff, α)

println("Jaccard Index: ", round(jaccard_index, digits=3))
println("RMSE: ", round(rmse_value, digits=3), " μm")
println("Efficiency: ", round(efficiency_score, digits=3))
```

### SMLMData Integration

```julia
using SMLMData, SMLMMetrics
using SMLMData: BasicSMLD, Emitter2DFit, IdealCamera

# Create SMLD containers (compatible with SMLMData.jl v0.3+)
emitters_truth = [Emitter2DFit{Float64}(1.0, 2.0, 1000.0, 10.0, 0.01, 0.01, 50.0, 2.0)]
emitters_detected = [Emitter2DFit{Float64}(1.1, 2.1, 1000.0, 10.0, 0.01, 0.01, 50.0, 2.0)]

camera = IdealCamera(512, 512, 0.1)  # 512×512 pixels, 0.1 μm/pixel
smld_truth = BasicSMLD(emitters_truth, camera, 1, 1, Dict{String,Any}())
smld_detected = BasicSMLD(emitters_detected, camera, 1, 1, Dict{String,Any}())

# All functions work directly with SMLD containers
ji = jaccard(smld_truth, smld_detected, [0.05, 0.05])
rmse_val = rmse(smld_truth, smld_detected)  # Uses default α values
eff = efficiency(smld_truth, smld_detected, [0.05, 0.05])  # Uses default α values
```

## Core Functions

- `jaccard(a, b, cutoff)` - Calculate Jaccard Index between two localization sets
- `match(a, b, cutoff)` - Find optimal point assignments using Hungarian algorithm  
- `rmse(a, b, α)` - Root Mean Square Error with dimensional weighting
- `efficiency(a, b, cutoff, α)` - Combined efficiency metric

All functions support both coordinate arrays (`d × n` matrices) and SMLMData containers.

## Requirements

- Julia ≥ 1.6
- SMLMData.jl ≥ 0.3 (for SMLMData integration)

## Documentation

- [**API Overview**](api.md) - Comprehensive function reference with examples
- [**STABLE**](https://JuliaSMLM.github.io/SMLMMetrics.jl/stable/) - Documentation for the most recently tagged version
- [**DEVELOPMENT**](https://JuliaSMLM.github.io/SMLMMetrics.jl/dev/) - Documentation for the in-development version

## Contributing

Contributions to SMLMMetrics are always welcome! If you have any suggestions, feature requests, or bug reports, please open an issue on [GitHub](https://github.com/JuliaSMLM/SMLMMetrics.jl/issues).

## License

SMLMMetrics.jl is licensed under the [MIT License](LICENSE).
