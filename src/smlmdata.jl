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
    rmse(a::SMLMData.SMLD2D, b::SMLMData.SMLD2D; α::Vector{<:Real} = ones(2))

Computes the root mean squared error (RMSE) for two sets of 2D localizations represented by `SMLD2D` structures `a` and `b`.

# Arguments
- `a::SMLMData.SMLD2D`: First set of localizations
- `b::SMLMData.SMLD2D`: Second set of localizations
- `α::Vector{<:Real}`: Optional weight vector for each dimension (default is ones(2))

# Returns
- `Float64`: RMSE between the two sets of localizations
"""
function rmse(a::SMLMData.SMLD2D, b::SMLMData.SMLD2D; α::Vector{<:Real} = ones(2))
    a_coords = hcat(a.x, a.y)
    b_coords = hcat(b.x, b.y)
    return rmse(a_coords, b_coords; α)
end

"""
    rmse(a::SMLMData.SMLD3D, b::SMLMData.SMLD3D; α::Vector{<:Real} = [1e-2, 1e-2, 5e-2])

Computes the root mean squared error (RMSE) for two sets of 3D localizations represented by `SMLD3D` structures `a` and `b`.

# Arguments
- `a::SMLMData.SMLD3D`: First set of localizations
- `b::SMLMData.SMLD3D`: Second set of localizations
- `α::Vector{<:Real}`: Optional weight vector for each dimension (default is [1e-2, 1e-2, 5e-2])

# Returns
- `Float64`: RMSE between the two sets of localizations
"""
function rmse(a::SMLMData.SMLD3D, b::SMLMData.SMLD3D; α::Vector{<:Real} = [1e-2, 1e-2, 5e-2])
    a_coords = hcat(a.x, a.y, a.z)
    b_coords = hcat(b.x, b.y, b.z)
    return rmse(a_coords, b_coords; α)
end


"""
    efficiency(a::SMLMData.SMLD2D, b::SMLMData.SMLD2D, cutoff::Vector{<:Real}; α::Vector{<:Real} = (default is [1e-2, 1e-2, 5e-2]))

Calculate the efficiency between two sets of 2D SMLM data `a` and `b` using a maximum connection distance of `cutoff`.
`α` is an optional argument that provides weights for each dimension. (default is [1e-2 1e-2 5e-2])

The function first converts the data from the SMLD2D format into coordinate arrays, and then calculates the efficiency 
using the provided `cutoff` and `α` parameters.

Returns the calculated efficiency value.

# Examples
```julia
efficiency(data1, data2, [1.0, 1.0])
efficiency(data1, data2, [1.0, 1.0], [0.5, 0.5])
```
"""
function efficiency(a::SMLMData.SMLD2D, b::SMLMData.SMLD2D, cutoff::Vector{<:Real}; α::Vector{<:Real} = [1e-2, 1e-2])
    a_coords = hcat(a.x, a.y)
    b_coords = hcat(b.x, b.y)
    return efficiency(a_coords, b_coords, cutoff; α)
end

"""
    efficiency(a::SMLMData.SMLD3D, b::SMLMData.SMLD3D, cutoff::Vector{<:Real}; α::Vector{<:Real} = ones(3))

Calculate the efficiency between two sets of 3D SMLM data `a` and `b` using a maximum connection distance of `cutoff`.
`α` is an optional argument that provides weights for each dimension.

The function first converts the data from the SMLD3D format into coordinate arrays, and then calculates the efficiency 
using the provided `cutoff` and `α` parameters.

Returns the calculated efficiency value.

# Examples
```julia
efficiency(data1, data2, [1.0, 1.0, 1.0])
efficiency(data1, data2, [1.0, 1.0, 1.0], [0.5, 0.5, 0.5])
```
"""
function efficiency(a::SMLMData.SMLD3D, b::SMLMData.SMLD3D, cutoff::Vector{<:Real}; α::Vector{<:Real} = ones(3))
    a_coords = hcat(a.x, a.y, a.z)
    b_coords = hcat(b.x, b.y, b.z)
    return efficiency(a_coords, b_coords, cutoff; α)
end
