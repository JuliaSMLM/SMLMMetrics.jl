#!/usr/bin/env julia
"""
Check which detections u-track found vs ground truth
"""

using MAT
using SMLMMetrics

# Load ground truth
function load_custom_trajectories(filepath::String; dt::Float64=0.01)
    mat_data = matread(filepath)
    n_traj = Int(mat_data["n_trajectories"])
    trajectories = SMLMMetrics.Trajectory[]

    for i in 1:n_traj
        frames = vec(Int.(mat_data["trajectory_$(i)_frames"]))
        x = vec(Float64.(mat_data["trajectory_$(i)_x"]))
        y = vec(Float64.(mat_data["trajectory_$(i)_y"]))
        traj = SMLMMetrics.Trajectory(id=i, frames=frames, x=x, y=y, z=nothing, dt=dt)
        push!(trajectories, traj)
    end

    min_frame = minimum(minimum(t.frames) for t in trajectories)
    max_frame = maximum(maximum(t.frames) for t in trajectories)
    return SMLMMetrics.Tracks(trajectories=trajectories, frame_range=(min_frame, max_frame), metadata=Dict{String,Any}())
end

println("=== GROUND TRUTH POSITIONS (Frame 1) ===")
gt = load_custom_trajectories("results/tracking/ground_truth.mat")
for traj in gt.trajectories
    if 1 in traj.frames
        idx = findfirst(==(1), traj.frames)
        x = traj.x[idx]
        y = traj.y[idx]
        println("GT Track $(traj.id): ($(round(x, digits=2)), $(round(y, digits=2))) μm")
    end
end

println("\n=== U-TRACK POSITIONS (Frame 1) ===")
utrack = load_tracks(UTrackFormat(), "results/tracking/utrack_tracking_results.mat", pixel_size=0.1)
for traj in utrack.trajectories
    if 1 in traj.frames
        idx = findfirst(==(1), traj.frames)
        x = traj.x[idx]
        y = traj.y[idx]
        println("U-track $(traj.id): ($(round(x, digits=2)), $(round(y, digits=2))) μm")
    end
end

# Check the raw u-track file
println("\n=== RAW U-TRACK DATA ===")
utrack_raw = matread("results/tracking/utrack_tracking_results.mat")
tf = utrack_raw["tracksFinal"]
println("Number of compound tracks in tracksFinal: $(length(tf))")

# Also check SMITE to see if it detected all 5
println("\n=== SMITE POSITIONS (Frame 1) ===")
smite = load_tracks(SmiteFormat(), "results/tracking/smite_tracking_results.mat", varname="SMD_TR")
for traj in smite.trajectories
    if 1 in traj.frames
        idx = findfirst(==(1), traj.frames)
        x = traj.x[idx]
        y = traj.y[idx]
        println("SMITE Track $(traj.id): ($(round(x, digits=2)), $(round(y, digits=2))) μm")
    end
end
