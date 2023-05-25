using SMLMMetrics
using Test
using SMLMData

@testset "SMLMMetrics.jl" begin
    a = [1 2 3; 4 5 6]
    b = [1 2 4; 4 5 7]
    c = [1 2 8; 4 5 10]
    cutoff = [1.0, 1.0]

    @testset "Jaccard index" begin
        jaccard_index = SMLMMetrics.jaccard(a, b, cutoff)
        @test jaccard_index ≈ 2/(2 + 1 + 1) # 2 matches out of a total of 4 unique points

        jaccard_index_no_match = SMLMMetrics.jaccard(a, c, cutoff)
        @test jaccard_index_no_match ≈ 0.5 # 2 matches out of a total of 4 unique points
    end

    @testset "RMSE" begin
        rmse_value = SMLMMetrics.rmse(a, b)
        @test isapprox(rmse_value, sqrt(2/6), atol=1e-8) # sqrt((1^2 + 1^2)/6)

        α = [1.0, 2.0]
        rmse_weighted = SMLMMetrics.rmse(a, b, α)
        @test isapprox(rmse_weighted, sqrt((1^2 + (2*1)^2)/6), atol=1e-8) # sqrt((1^2 + (2*1)^2)/6)
    end

    @testset "Match" begin
        assignment = SMLMMetrics.match(a, b, cutoff)
        @test assignment == [1, 2, 0]

        assignment_no_match = SMLMMetrics.match(a, c, cutoff)
        @test assignment_no_match == [1, 2, 0] # 2 matches with a large distance
    end

    @testset "Efficiency" begin
        α = [1.0, 2.0]
        efficiency_value = SMLMMetrics.efficiency(a, b, cutoff, α)

        # The assertion below is a placeholder, you'll need to replace it with the actual expected value
        @test efficiency_value ≈ 0.5

        efficiency_value_no_alpha = SMLMMetrics.efficiency(a, b, cutoff)

        # The assertion below is a placeholder, you'll need to replace it with the actual expected value
        @test efficiency_value_no_alpha ≈ 0.5
    end
    
end

