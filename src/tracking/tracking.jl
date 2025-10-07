"""
Particle tracking performance evaluation based on optimal track pairing.

This module implements the performance measures described in:
Chenouard et al., "Objective comparison of particle tracking methods"
Nature Methods 11, 281-289 (2014), Supplementary Note 3.

# Main Types
- `Track`: Temporal series of spatial positions
- `TrackingMetrics`: Container for all performance measures

# Main Function
- `evaluate_tracking(ground_truth, estimated)`: Compute all performance measures

# Performance Measures
- **α**: Overall quality measure (0-1, higher is better)
- **β**: Quality measure penalizing spurious tracks (0-1, higher is better)
- **JSC**: Jaccard similarity coefficient for positions (0-1, higher is better)
- **JSC_θ**: Jaccard similarity coefficient for tracks (0-1, higher is better)
- **RMSE**: Root mean square error of localization (lower is better)

# Example
```julia
using SMLMMetrics

# Define ground truth track
gt = [Track(Dict(0 => [0.0, 0.0], 1 => [1.0, 1.0], 2 => [2.0, 2.0]))]

# Define estimated track with small errors
est = [Track(Dict(0 => [0.1, 0.1], 1 => [1.1, 1.1], 2 => [2.1, 2.1]))]

# Evaluate
metrics = evaluate_tracking(gt, est)
println("JSC: ", metrics.JSC)
println("RMSE: ", metrics.RMSE)
println("α: ", metrics.α)
```
"""
module Tracking

include("track_types.jl")
include("track_pairing.jl")
include("tracking_metrics.jl")

# Export types
export Track, TrackingMetrics

# Export main evaluation function
export evaluate_tracking

# Export constants
export DEFAULT_GATE

end # module
