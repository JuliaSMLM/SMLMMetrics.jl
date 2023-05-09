# Add this in your SMLMMetrics.jl file
using SMLMData

"""
    jaccard(a::SMLMData.SMLD2D, b::SMLMData.SMLD2D, cutoff::Vector{<:Real})

Computes the Jaccard index for two sets of 2D localizations represented by `SMLD2D` structures `a` and `b`.

# Arguments
- `a::SMLMData.SMLD2D`: First set of localizations
- `b::SMLMData.SMLD2D`: Second set of localizations
- `cutoff::Vector{<:Real}`: A vector of cutoff distances for each dimension

# Returns
- `Float64`: Jaccard index between the two sets of localizations
"""
function jaccard(a::SMLMData.SMLD2D, b::SMLMData.SMLD2D, cutoff::Vector{<:Real})
    a_coords = hcat(a.x, a.y)
    b_coords = hcat(b.x, b.y)
    return jaccard(a_coords, b_coords, cutoff)
end

"""
    jaccard(a::SMLMData.SMLD3D, b::SMLMData.SMLD3D, cutoff::Vector{<:Real})

Computes the Jaccard index for two sets of 3D localizations represented by `SMLD3D` structures `a` and `b`.

# Arguments
- `a::SMLMData.SMLD3D`: First set of localizations
- `b::SMLMData.SMLD3D`: Second set of localizations
- `cutoff::Vector{<:Real}`: A vector of cutoff distances for each dimension

# Returns
- `Float64`: Jaccard index between the two sets of localizations
"""
function jaccard(a::SMLMData.SMLD3D, b::SMLMData.SMLD3D, cutoff::Vector{<:Real})
    a_coords = hcat(a.x, a.y, a.z)
    b_coords = hcat(b.x, b.y, b.z)
    return jaccard(a_coords, b_coords, cutoff)
end

"""
    rmse(a::SMLMData.SMLD2D, b::SMLMData.SMLD2D, α::Vector{<:Real} = ones(2))

Computes the root mean squared error (RMSE) for two sets of 2D localizations represented by `SMLD2D` structures `a` and `b`.

# Arguments
- `a::SMLMData.SMLD2D`: First set of localizations
- `b::SMLMData.SMLD2D`: Second set of localizations
- `α::Vector{<:Real}`: Optional weight vector for each dimension (default is ones(2))

# Returns
- `Float64`: RMSE between the two sets of localizations
"""
function rmse(a::SMLMData.SMLD2D, b::SMLMData.SMLD2D, α::Vector{<:Real} = ones(2))
    a_coords = hcat(a.x, a.y)
    b_coords = hcat(b.x, b.y)
    return rmse(a_coords, b_coords, α)
end

"""
    rmse(a::SMLMData.SMLD3D, b::SMLMData.SMLD3D, α::Vector{<:Real} = ones(3))

Computes the root mean squared error (RMSE) for two sets of 3D localizations represented by `SMLD3D` structures `a` and `b`.

# Arguments
- `a::SMLMData.SMLD3D`: First set of localizations
- `b::SMLMData.SMLD3D`: Second set of localizations
- `α::Vector{<:Real}`: Optional weight vector for each dimension (default is ones(3))

# Returns
- `Float64`: RMSE between the two sets of localizations
"""
function rmse(a::SMLMData.SMLD3D, b::SMLMData.SMLD3D, α::Vector{<:Real} = ones(3))
    a_coords = hcat(a.x, a.y, a.z)
    b_coords = hcat(b.x, b.y, b.z)
    return rmse(a_coords, b_coords, α)
end