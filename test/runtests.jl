using SMLMMetrics
using Test

@testset "SMLMMetrics.jl" begin
    @testset "Trajectory Construction" begin
        # Test 2D trajectory
        traj_2d = Trajectory(
            id=1,
            frames=[1, 2, 3],
            x=[0.0, 1.0, 2.0],
            y=[0.0, 1.0, 2.0],
            z=nothing,
            dt=0.01
        )
        @test traj_2d.id == 1
        @test length(traj_2d.frames) == 3
        @test !is_3d(traj_2d)
        @test dimensionality(traj_2d) == 2
        @test num_positions(traj_2d) == 3
        @test temporal_length(traj_2d) == 3
        @test num_gaps(traj_2d) == 0

        # Test 3D trajectory
        traj_3d = Trajectory(
            id=2,
            frames=[1, 2, 3],
            x=[0.0, 1.0, 2.0],
            y=[0.0, 1.0, 2.0],
            z=[0.0, 0.5, 1.0],
            dt=0.01
        )
        @test is_3d(traj_3d)
        @test dimensionality(traj_3d) == 3

        # Test trajectory with gaps
        traj_gaps = Trajectory(
            id=3,
            frames=[1, 2, 4, 5],  # Gap at frame 3
            x=[0.0, 1.0, 3.0, 4.0],
            y=[0.0, 1.0, 3.0, 4.0],
            z=nothing,
            dt=0.01
        )
        @test num_positions(traj_gaps) == 4
        @test temporal_length(traj_gaps) == 5
        @test num_gaps(traj_gaps) == 1
        @test has_position(traj_gaps, 1)
        @test has_position(traj_gaps, 2)
        @test !has_position(traj_gaps, 3)  # Gap
        @test has_position(traj_gaps, 4)

        # Test get_position
        pos = get_position(traj_2d, 2)
        @test pos == [1.0, 1.0]
        @test isnothing(get_position(traj_gaps, 3))  # Gap
    end

    @testset "Tracks Construction" begin
        traj1 = Trajectory(id=1, frames=[1,2,3], x=[0.0,1.0,2.0], y=[0.0,1.0,2.0], z=nothing, dt=0.01)
        traj2 = Trajectory(id=2, frames=[2,3,4], x=[5.0,6.0,7.0], y=[5.0,6.0,7.0], z=nothing, dt=0.01)

        tracks = Tracks(
            trajectories=[traj1, traj2],
            frame_range=(1, 4),
            metadata=Dict{String,Any}("test" => "data")
        )

        @test num_trajectories(tracks) == 2
        @test num_frames(tracks) == 4
        @test total_positions(tracks) == 6
        @test !is_3d(tracks)
        @test tracks.metadata["test"] == "data"
    end

    # Include tracking evaluation tests
    include("test_tracking.jl")
end
