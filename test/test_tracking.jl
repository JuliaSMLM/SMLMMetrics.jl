using Test

"""
Test cases for particle tracking performance measures.
Based on Supplementary Note 3 from Chenouard et al., Nature Methods 11, 281-289 (2014).
"""

@testset "Particle Tracking Performance Measures" begin

    @testset "Basic Functionality" begin
        # Test Case 1: No estimated tracks (worst case)
        gt_traj = Trajectory(
            id=1,
            frames=[1, 2, 3, 4, 5],
            x=[0.0, 1.0, 2.0, 1.0, 3.0],
            y=[0.0, 1.0, 2.0, 2.0, 3.0],
            z=nothing,
            dt=0.01
        )
        gt_tracks = Tracks(trajectories=[gt_traj], frame_range=(1, 5), metadata=Dict{String,Any}())
        est_tracks = Tracks(trajectories=Trajectory[], frame_range=(1, 5), metadata=Dict{String,Any}())

        metrics = evaluate_tracking(gt_tracks, est_tracks)

        @test metrics.α ≈ 0.0
        @test metrics.β ≈ 0.0
        @test metrics.TP == 0
        @test metrics.FN == 5
        @test metrics.FP == 0
        @test metrics.JSC ≈ 0.0
        @test metrics.TP_θ == 0
        @test metrics.FN_θ == 1
        @test metrics.FP_θ == 0
        @test metrics.JSC_θ ≈ 0.0
        @test metrics.RMSE ≈ 0.0
        @test metrics.min_error ≈ 0.0
        @test metrics.max_error ≈ 0.0
    end

    @testset "Perfect Match" begin
        # Test Case 2: Identical tracks (best case)
        positions = (
            frames=[1, 2, 3, 4, 5],
            x=[0.0, 1.0, 2.0, 1.0, 3.0],
            y=[0.0, 1.0, 2.0, 2.0, 3.0]
        )

        gt_traj = Trajectory(id=1, frames=positions.frames, x=positions.x, y=positions.y, z=nothing, dt=0.01)
        est_traj = Trajectory(id=1, frames=positions.frames, x=positions.x, y=positions.y, z=nothing, dt=0.01)

        gt_tracks = Tracks(trajectories=[gt_traj], frame_range=(1, 5), metadata=Dict{String,Any}())
        est_tracks = Tracks(trajectories=[est_traj], frame_range=(1, 5), metadata=Dict{String,Any}())

        metrics = evaluate_tracking(gt_tracks, est_tracks)

        @test metrics.α ≈ 1.0
        @test metrics.β ≈ 1.0
        @test metrics.TP == 5
        @test metrics.FN == 0
        @test metrics.FP == 0
        @test metrics.JSC ≈ 1.0
        @test metrics.TP_θ == 1
        @test metrics.FN_θ == 0
        @test metrics.FP_θ == 0
        @test metrics.JSC_θ ≈ 1.0
        @test metrics.RMSE ≈ 0.0
        @test metrics.RMSE_θ ≈ 0.0
        @test metrics.min_error ≈ 0.0
        @test metrics.max_error ≈ 0.0
    end

    @testset "Small Localization Errors" begin
        # GT track
        gt_traj = Trajectory(
            id=1,
            frames=[1, 2, 3],
            x=[0.0, 1.0, 2.0],
            y=[0.0, 1.0, 2.0],
            z=nothing,
            dt=0.01
        )
        gt_tracks = Tracks(trajectories=[gt_traj], frame_range=(1, 3), metadata=Dict{String,Any}())

        # EST track with small errors (all within gate=5.0)
        est_traj = Trajectory(
            id=1,
            frames=[1, 2, 3],
            x=[0.1, 1.1, 2.1],
            y=[0.1, 1.1, 2.1],
            z=nothing,
            dt=0.01
        )
        est_tracks = Tracks(trajectories=[est_traj], frame_range=(1, 3), metadata=Dict{String,Any}())

        metrics = evaluate_tracking(gt_tracks, est_tracks)

        # All positions should match
        @test metrics.TP == 3
        @test metrics.FN == 0
        @test metrics.FP == 0
        @test metrics.JSC ≈ 1.0
        @test metrics.TP_θ == 1
        @test metrics.FN_θ == 0
        @test metrics.FP_θ == 0
        @test metrics.JSC_θ ≈ 1.0

        # α and β should be high (less than 1 due to localization errors)
        @test metrics.α > 0.9
        @test metrics.β > 0.9

        # RMSE should be small
        expected_rmse = sqrt(3 * (0.1^2 + 0.1^2) / 3)  # sqrt(mean of squared errors)
        @test metrics.RMSE ≈ expected_rmse atol=0.001
        @test metrics.RMSE_θ ≈ expected_rmse atol=0.001

        # Min/Max errors
        @test metrics.min_error ≈ sqrt(0.1^2 + 0.1^2) atol=0.001
        @test metrics.max_error ≈ sqrt(0.1^2 + 0.1^2) atol=0.001
    end

    @testset "Missing Detection" begin
        # GT has 2 tracks
        gt_traj1 = Trajectory(id=1, frames=[1, 2], x=[0.0, 1.0], y=[0.0, 1.0], z=nothing, dt=0.01)
        gt_traj2 = Trajectory(id=2, frames=[1, 2], x=[5.0, 6.0], y=[5.0, 6.0], z=nothing, dt=0.01)
        gt_tracks = Tracks(trajectories=[gt_traj1, gt_traj2], frame_range=(1, 2), metadata=Dict{String,Any}())

        # EST has only 1 track (perfect match to first GT)
        est_traj = Trajectory(id=1, frames=[1, 2], x=[0.0, 1.0], y=[0.0, 1.0], z=nothing, dt=0.01)
        est_tracks = Tracks(trajectories=[est_traj], frame_range=(1, 2), metadata=Dict{String,Any}())

        metrics = evaluate_tracking(gt_tracks, est_tracks)

        @test metrics.TP == 2  # Only first track's positions
        @test metrics.FN == 2  # Second track's positions are missing
        @test metrics.FP == 0
        @test metrics.JSC ≈ 0.5  # 2/(2+2+0)
        @test metrics.TP_θ == 1
        @test metrics.FN_θ == 1
        @test metrics.FP_θ == 0
        @test metrics.JSC_θ ≈ 0.5
    end

    @testset "Spurious Tracks" begin
        # GT has 1 track
        gt_traj = Trajectory(id=1, frames=[1, 2], x=[0.0, 1.0], y=[0.0, 1.0], z=nothing, dt=0.01)
        gt_tracks = Tracks(trajectories=[gt_traj], frame_range=(1, 2), metadata=Dict{String,Any}())

        # EST has 2 tracks (one is spurious)
        est_traj1 = Trajectory(id=1, frames=[1, 2], x=[0.0, 1.0], y=[0.0, 1.0], z=nothing, dt=0.01)  # Matches GT
        est_traj2 = Trajectory(id=2, frames=[1, 2], x=[10.0, 11.0], y=[10.0, 11.0], z=nothing, dt=0.01)  # Spurious
        est_tracks = Tracks(trajectories=[est_traj1, est_traj2], frame_range=(1, 2), metadata=Dict{String,Any}())

        metrics = evaluate_tracking(gt_tracks, est_tracks)

        @test metrics.TP == 2
        @test metrics.FN == 0
        @test metrics.FP == 2  # Spurious track positions
        @test metrics.JSC ≈ 0.5  # 2/(2+0+2)
        @test metrics.TP_θ == 1
        @test metrics.FN_θ == 0
        @test metrics.FP_θ == 1  # One spurious track
        @test metrics.JSC_θ ≈ 0.5

        # β should be lower than α due to spurious tracks
        @test metrics.β < metrics.α
    end

    @testset "Position Outside Gate" begin
        # GT track
        gt_traj = Trajectory(id=1, frames=[1, 2], x=[0.0, 1.0], y=[0.0, 1.0], z=nothing, dt=0.01)
        gt_tracks = Tracks(trajectories=[gt_traj], frame_range=(1, 2), metadata=Dict{String,Any}())

        # EST track with one position far outside gate (> 5.0)
        est_traj = Trajectory(
            id=1,
            frames=[1, 2],
            x=[0.0, 10.0],  # Second position distance > 5.0
            y=[0.0, 10.0],
            z=nothing,
            dt=0.01
        )
        est_tracks = Tracks(trajectories=[est_traj], frame_range=(1, 2), metadata=Dict{String,Any}())

        metrics = evaluate_tracking(gt_tracks, est_tracks)

        @test metrics.TP == 1  # Only first position matches
        @test metrics.FN == 1  # GT position at frame 2 doesn't match
        @test metrics.FP == 1  # EST position at frame 2 doesn't match
        @test metrics.JSC ≈ 1/3  # 1/(1+1+1)
    end

    @testset "Using Vector{Trajectory} directly" begin
        # Test the alternative API that takes Vector{Trajectory} directly
        gt_traj = Trajectory(id=1, frames=[1,2,3], x=[0.0,1.0,2.0], y=[0.0,1.0,2.0], z=nothing, dt=0.01)
        est_traj = Trajectory(id=1, frames=[1,2,3], x=[0.1,1.1,2.1], y=[0.1,1.1,2.1], z=nothing, dt=0.01)

        metrics = evaluate_tracking([gt_traj], [est_traj])

        # Should work correctly with auto-detected frame range
        @test metrics.TP == 3
        @test metrics.JSC_θ ≈ 1.0
    end

end
