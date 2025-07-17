# Add this in your SMLMMetrics.jl file
using SMLMData
using SMLMData: BasicSMLD, Emitter2D, Emitter2DFit, Emitter3D, Emitter3DFit

"""
    jaccard(a::BasicSMLD{T,E}, b::BasicSMLD{T,E}, cutoff::Vector{<:Real}) where {T,E<:Union{Emitter2D,Emitter2DFit}}

Computes the Jaccard index for two sets of 2D localizations represented by `BasicSMLD` structures `a` and `b` with 2D emitters.

# Arguments
- `a::BasicSMLD{T,E}`: First set of localizations with 2D emitters
- `b::BasicSMLD{T,E}`: Second set of localizations with 2D emitters
- `cutoff::Vector{<:Real}`: A vector of cutoff distances for each dimension

# Returns
- `Float64`: Jaccard index between the two sets of localizations
"""
function jaccard(a::BasicSMLD{T,E}, b::BasicSMLD{T,E}, cutoff::Vector{<:Real}) where {T,E<:Union{Emitter2D,Emitter2DFit}}
    a_coords = [[emitter.x for emitter in a.emitters]'; [emitter.y for emitter in a.emitters]']
    b_coords = [[emitter.x for emitter in b.emitters]'; [emitter.y for emitter in b.emitters]']
    return jaccard(a_coords, b_coords, cutoff)
end

"""
    jaccard(a::BasicSMLD{T,E}, b::BasicSMLD{T,E}, cutoff::Vector{<:Real}) where {T,E<:Union{Emitter3D,Emitter3DFit}}

Computes the Jaccard index for two sets of 3D localizations represented by `BasicSMLD` structures `a` and `b` with 3D emitters.

# Arguments
- `a::BasicSMLD{T,E}`: First set of localizations with 3D emitters
- `b::BasicSMLD{T,E}`: Second set of localizations with 3D emitters
- `cutoff::Vector{<:Real}`: A vector of cutoff distances for each dimension

# Returns
- `Float64`: Jaccard index between the two sets of localizations
"""
function jaccard(a::BasicSMLD{T,E}, b::BasicSMLD{T,E}, cutoff::Vector{<:Real}) where {T,E<:Union{Emitter3D,Emitter3DFit}}
    a_coords = [[emitter.x for emitter in a.emitters]'; [emitter.y for emitter in a.emitters]'; [emitter.z for emitter in a.emitters]']
    b_coords = [[emitter.x for emitter in b.emitters]'; [emitter.y for emitter in b.emitters]'; [emitter.z for emitter in b.emitters]']
    return jaccard(a_coords, b_coords, cutoff)
end

"""
    rmse(a::BasicSMLD{T,E}, b::BasicSMLD{T,E}; α::Vector{<:Real} = ones(2)) where {T,E<:Union{Emitter2D,Emitter2DFit}}

Computes the root mean squared error (RMSE) for two sets of 2D localizations represented by `BasicSMLD` structures `a` and `b` with 2D emitters.

# Arguments
- `a::BasicSMLD{T,E}`: First set of localizations with 2D emitters
- `b::BasicSMLD{T,E}`: Second set of localizations with 2D emitters
- `α::Vector{<:Real}`: Optional weight vector for each dimension (default is [1e-2, 1e-2])

# Returns
- `Float64`: RMSE between the two sets of localizations
"""
function rmse(a::BasicSMLD{T,E}, b::BasicSMLD{T,E}; α::Vector{<:Real} = [1e-2, 1e-2]) where {T,E<:Union{Emitter2D,Emitter2DFit}}
    a_coords = [[emitter.x for emitter in a.emitters]'; [emitter.y for emitter in a.emitters]']
    b_coords = [[emitter.x for emitter in b.emitters]'; [emitter.y for emitter in b.emitters]']
    return rmse(a_coords, b_coords, α)
end

"""
    rmse(a::BasicSMLD{T,E}, b::BasicSMLD{T,E}; α::Vector{<:Real} = [1e-2, 1e-2, 5e-2]) where {T,E<:Union{Emitter3D,Emitter3DFit}}

Computes the root mean squared error (RMSE) for two sets of 3D localizations represented by `BasicSMLD` structures `a` and `b` with 3D emitters.

# Arguments
- `a::BasicSMLD{T,E}`: First set of localizations with 3D emitters
- `b::BasicSMLD{T,E}`: Second set of localizations with 3D emitters
- `α::Vector{<:Real}`: Optional weight vector for each dimension (default is [1e-2, 1e-2, 0.5e-2])

# Returns
- `Float64`: RMSE between the two sets of localizations
"""
function rmse(a::BasicSMLD{T,E}, b::BasicSMLD{T,E}; α::Vector{<:Real} = [1e-2, 1e-2, 0.5e-2]) where {T,E<:Union{Emitter3D,Emitter3DFit}}
    a_coords = [[emitter.x for emitter in a.emitters]'; [emitter.y for emitter in a.emitters]'; [emitter.z for emitter in a.emitters]']
    b_coords = [[emitter.x for emitter in b.emitters]'; [emitter.y for emitter in b.emitters]'; [emitter.z for emitter in b.emitters]']
    return rmse(a_coords, b_coords, α)
end


"""
    efficiency(a::BasicSMLD{T,E}, b::BasicSMLD{T,E}, cutoff::Vector{<:Real}; α::Vector{<:Real} = [1e-2, 1e-2]) where {T,E<:Union{Emitter2D,Emitter2DFit}}

Calculate the efficiency between two sets of 2D SMLM data `a` and `b` using a maximum connection distance of `cutoff`.
`α` is an optional argument that provides weights for each dimension. (default is [1e-2, 1e-2])

The function first converts the data from the BasicSMLD format into coordinate arrays, and then calculates the efficiency 
using the provided `cutoff` and `α` parameters.

Returns the calculated efficiency value.

# Examples
```julia
efficiency(data1, data2, [1.0, 1.0])
efficiency(data1, data2, [1.0, 1.0], α=[0.5, 0.5])
```
"""
function efficiency(a::BasicSMLD{T,E}, b::BasicSMLD{T,E}, cutoff::Vector{<:Real}; α::Vector{<:Real} = [1e-2, 1e-2]) where {T,E<:Union{Emitter2D,Emitter2DFit}}
    a_coords = [[emitter.x for emitter in a.emitters]'; [emitter.y for emitter in a.emitters]']
    b_coords = [[emitter.x for emitter in b.emitters]'; [emitter.y for emitter in b.emitters]']
    return efficiency(a_coords, b_coords, cutoff, α)
end

"""
    efficiency(a::BasicSMLD{T,E}, b::BasicSMLD{T,E}, cutoff::Vector{<:Real}; α::Vector{<:Real} = ones(3)) where {T,E<:Union{Emitter3D,Emitter3DFit}}

Calculate the efficiency between two sets of 3D SMLM data `a` and `b` using a maximum connection distance of `cutoff`.
`α` is an optional argument that provides weights for each dimension.

The function first converts the data from the BasicSMLD format into coordinate arrays, and then calculates the efficiency 
using the provided `cutoff` and `α` parameters.

Returns the calculated efficiency value.

# Examples
```julia
efficiency(data1, data2, [1.0, 1.0, 1.0])
efficiency(data1, data2, [1.0, 1.0, 1.0], α=[0.5, 0.5, 0.5])
```
"""
function efficiency(a::BasicSMLD{T,E}, b::BasicSMLD{T,E}, cutoff::Vector{<:Real}; α::Vector{<:Real} = [1e-2, 1e-2, 0.5e-2]) where {T,E<:Union{Emitter3D,Emitter3DFit}}
    a_coords = [[emitter.x for emitter in a.emitters]'; [emitter.y for emitter in a.emitters]'; [emitter.z for emitter in a.emitters]']
    b_coords = [[emitter.x for emitter in b.emitters]'; [emitter.y for emitter in b.emitters]'; [emitter.z for emitter in b.emitters]']
    return efficiency(a_coords, b_coords, cutoff, α)
end
