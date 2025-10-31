"""
Particle tracking performance evaluation based on optimal track pairing.

This module implements the performance measures described in:
Chenouard et al., "Objective comparison of particle tracking methods"
Nature Methods 11, 281-289 (2014), Supplementary Note 3.

# Main Types
- `Trajectory`: Single particle trajectory with frame numbers and positions
- `Tracks`: Collection of trajectories from a tracking dataset
- `TrackingMetrics`: Container for all performance measures

# Main Function
- `evaluate_tracking(ground_truth, estimated)`: Compute all performance measures

# Performance Measures (14 from Chenouard et al. 2014)
- **α**: Overall quality measure (0-1, higher is better)
- **β**: Quality measure penalizing spurious tracks (0-1, higher is better)
- **JSC**: Jaccard similarity coefficient for positions (0-1, higher is better)
- **JSC_θ**: Jaccard similarity coefficient for tracks (0-1, higher is better)
- **RMSE**: Root mean square error of localization (lower is better)
- **RMSE_θ**: Track-averaged RMSE (lower is better)
- **min_error**: Minimum localization error (lower is better)
- **max_error**: Maximum localization error (lower is better)
- **TP, FN, FP**: Position-level true/false positives/negatives (counts)
- **TP_θ, FN_θ, FP_θ**: Track-level true/false positives/negatives (counts)

# Example
```julia
using SMLMMetrics

# Define ground truth trajectory
gt_traj = Trajectory(id=1, frames=[1,2,3], x=[0.0,1.0,2.0], y=[0.0,1.0,2.0], z=nothing, dt=0.01)
gt_tracks = Tracks(trajectories=[gt_traj], frame_range=(1,3), metadata=Dict{String,Any}())

# Define estimated trajectory with small errors
est_traj = Trajectory(id=1, frames=[1,2,3], x=[0.1,1.1,2.1], y=[0.1,1.1,2.1], z=nothing, dt=0.01)
est_tracks = Tracks(trajectories=[est_traj], frame_range=(1,3), metadata=Dict{String,Any}())

# Evaluate
metrics = evaluate_tracking(gt_tracks, est_tracks)
println("JSC: ", metrics.JSC)
println("RMSE: ", metrics.RMSE)
println("α: ", metrics.α)
```
"""
module Tracking

include("types.jl")
include("track_pairing.jl")
include("tracking_metrics.jl")

# Export types
export Trajectory, Tracks, TrackingMetrics

# Export main evaluation function
export evaluate_tracking

# Export utility functions
export is_3d, dimensionality, num_positions, temporal_length, num_gaps
export has_position, get_position
export num_trajectories, num_frames, total_positions

# Export constants
export DEFAULT_GATE

end # module
