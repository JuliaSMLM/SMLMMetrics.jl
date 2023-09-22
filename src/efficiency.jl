"""
efficiency(a::Array{<:Real}, b::Array{<:Real}, cutoff::Vector{<:Real}, α::Union{Nothing, Vector{<:Real}}=nothing)

Calculate the efficiency metric between two sets `a` and `b` 
using a maximum connection distance of `cutoff` for the Jaccard Index, 
and a dimensional weighting `α` for the RMSE. The efficiency is defined as:

``E = 1 - \\sqrt{(1 - JI)^2 + α^2 * RMSE^2}``

`a` and `b` are `d` x `n`, and `d` x `m` arrays, where `d` is the number of dimensions.  
`cutoff` contains the maximum matching distance for each dimension for the Jaccard Index.  
`α` contains the dimensional weighting for the RMSE.

Lateral and axial efficiencies are calculated separately and then averaged to obtain the overall efficiency. 
The first two dimensions are considered lateral and the third dimension is considered axial. 
The default alpha values are `α = 1 × 10^{-2} nm^{-1}` for lateral and `α = 0.5 × 10^{-2} nm^{-1}` for axial.

Detection accuracy is expressed in units of 0 to 1. 
The efficiency ranges up to 100% for a perfect fitting algorithm.
"""
function efficiency(a::Array{<:Real}, b::Array{<:Real}, cutoff::Vector{<:Real}, α::Union{Nothing, Vector{<:Real}}=nothing)
    # If α is not provided, use the default values
    if isnothing(α)
        d = size(a, 1)
        α = d == 1 ? [1e-2] : (d == 2 ? [1e-2, 1e-2] : [1e-2, 1e-2, 0.5e-2])
    end

    # Find the matching pairs
    assignment = match(a, b, cutoff)

    # Calculate the Jaccard Index
    ji = jaccard(a, b, cutoff)

    # Calculate the lateral and axial RMSE for the matched pairs
    matched_a = a[:, assignment .> 0]
    matched_b = b[:, assignment[assignment .> 0]]
    lateral_rmse = rmse(matched_a[1:2, :], matched_b[1:2, :], α[1:2])
    axial_rmse = size(a, 1) == 3 ? rmse(matched_a[3, :], matched_b[3, :], α[3:3]) : 0.0

    # Calculate the efficiency
    e_lateral = 1 - sqrt((1 - ji)^2 +2.0*lateral_rmse^2)
    e_axial = size(a, 1) == 3 ? (1 - sqrt((1 - ji)^2 +axial_rmse^2)) : 0.0
    eff = (size(a, 1) == 3 ? (e_lateral + e_axial) / 2 : e_lateral)

    return eff
end



