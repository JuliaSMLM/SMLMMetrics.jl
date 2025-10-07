using Test
using SMLMMetrics.Tracking

"""
Test cases for particle tracking performance measures.
Based on Supplementary Note 3 from Chenouard et al., Nature Methods 11, 281-289 (2014).
"""

@testset "Particle Tracking Performance Measures" begin

    @testset "Basic Functionality" begin
        # Test Case 1: No estimated tracks (worst case)
        gt = [Track(Dict(
            0 => [0.0, 0.0],
            1 => [1.0, 1.0],
            2 => [2.0, 1.0],
            3 => [1.0, 2.0],
            4 => [3.0, 3.0]
        ))]
        est = Track[]

        metrics = evaluate_tracking(gt, est, T=5)

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
    end

    @testset "Perfect Match" begin
        # Test Case 2: Identical tracks (best case)
        positions = Dict(
            0 => [0.0, 0.0],
            1 => [1.0, 1.0],
            2 => [2.0, 1.0],
            3 => [1.0, 2.0],
            4 => [3.0, 3.0]
        )
        gt = [Track(positions)]
        est = [Track(positions)]

        metrics = evaluate_tracking(gt, est, T=5)

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
    end

    @testset "Small Localization Errors" begin
        # GT track
        gt = [Track(Dict(
            0 => [0.0, 0.0],
            1 => [1.0, 1.0],
            2 => [2.0, 2.0]
        ))]

        # EST track with small errors (all within gate=5.0)
        est = [Track(Dict(
            0 => [0.1, 0.1],
            1 => [1.1, 1.1],
            2 => [2.1, 2.1]
        ))]

        metrics = evaluate_tracking(gt, est, T=3)

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
    end

    @testset "Missing Detection" begin
        # GT has 2 tracks
        gt = [
            Track(Dict(0 => [0.0, 0.0], 1 => [1.0, 1.0])),
            Track(Dict(0 => [5.0, 5.0], 1 => [6.0, 6.0]))
        ]

        # EST has only 1 track (perfect match to first GT)
        est = [Track(Dict(0 => [0.0, 0.0], 1 => [1.0, 1.0]))]

        metrics = evaluate_tracking(gt, est, T=2)

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
        gt = [Track(Dict(0 => [0.0, 0.0], 1 => [1.0, 1.0]))]

        # EST has 2 tracks (one is spurious)
        est = [
            Track(Dict(0 => [0.0, 0.0], 1 => [1.0, 1.0])),  # Matches GT
            Track(Dict(0 => [10.0, 10.0], 1 => [11.0, 11.0]))  # Spurious
        ]

        metrics = evaluate_tracking(gt, est, T=2)

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
        gt = [Track(Dict(
            0 => [0.0, 0.0],
            1 => [1.0, 1.0]
        ))]

        # EST track with one position far outside gate (> 5.0)
        est = [Track(Dict(
            0 => [0.0, 0.0],  # Perfect match
            1 => [10.0, 10.0]  # Distance > 5.0, should not match
        ))]

        metrics = evaluate_tracking(gt, est, T=2)

        @test metrics.TP == 1  # Only first position matches
        @test metrics.FN == 1  # GT position at t=1 doesn't match
        @test metrics.FP == 1  # EST position at t=1 doesn't match
        @test metrics.JSC ≈ 1/3  # 1/(1+1+1)
    end

    @testset "Auto-detect Sequence Length" begin
        # Test that T is automatically detected when not provided
        gt = [Track(Dict(0 => [0.0, 0.0], 5 => [5.0, 5.0]))]
        est = [Track(Dict(0 => [0.0, 0.0], 5 => [5.0, 5.0]))]

        metrics = evaluate_tracking(gt, est)  # No T specified

        # Should work correctly with auto-detected T=6 (0..5)
        @test metrics.TP == 2
        @test metrics.JSC_θ ≈ 1.0
    end

end
