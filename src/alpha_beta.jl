# Alpha and Beta metrics implementation
# Based on "Objective comparison of particle tracking methods" (Nature Methods 2014)

"""
    alpha(a::Array{<:Real}, b::Array{<:Real}, cutoff::Vector{<:Real})

Calculate the α measure: α(X, Y) = 1 - d(X, Y)/d(X, Ø)

The α measure evaluates the overall degree of matching between ground-truth and 
estimated tracks without penalizing spurious (non-paired estimated) tracks.

# Arguments
- `a` and `b` are `d` x `n` and `d` x `m` arrays, where `d` is the number of dimensions
- `cutoff` contains the maximum matching distance for each dimension (gate parameter ε)

# Returns
- `Float64`: α measure in range [0, 1], where 1 indicates perfect matching

# Details
The α measure is defined as α(X, Y) = 1 - d(X, Y)/d(X, Ø), where:
- d(X, Y) is the total distance between optimally paired tracks
- d(X, Ø) is the maximum possible distance (all ground truth paired with dummy tracks)
- Uses gated Euclidean distance with gate parameter ε = norm(cutoff)

# References
Chenouard et al., "Objective comparison of particle tracking methods", Nature Methods (2014)
"""
function alpha(a::Array{<:Real}, b::Array{<:Real}, cutoff::Vector{<:Real})
    # Use existing match function to get optimal assignment
    assignment = match(a, b, cutoff)
    
    # Calculate total distance for current assignment
    n_a = size(a, 2)
    n_d = size(a, 1)
    ε = norm(cutoff)  # Use norm as overall gate parameter
    
    d_xy = 0.0
    for i in 1:n_a
        if assignment[i] > 0
            # Paired assignment - calculate actual distance
            dist = sqrt(sum(abs2.(a[:, i] - b[:, assignment[i]])))
            d_xy += min(dist, ε)  # Apply gate
        else
            # Unpaired - assign penalty ε
            d_xy += ε
        end
    end
    
    # Calculate maximum possible distance (all ground truth to dummy)
    d_x_dummy = n_a * ε
    
    # α = 1 - d(X,Y) / d(X,Ø)
    return d_x_dummy > 0 ? 1.0 - (d_xy / d_x_dummy) : 1.0
end

"""
    beta(a::Array{<:Real}, b::Array{<:Real}, cutoff::Vector{<:Real})

Calculate the β measure: β(X, Y) = (d(X, Ø) - d(X, Y))/(d(X, Ø) + d(Ȳ, Ø))

The β measure is similar to α but includes penalization for spurious (non-paired estimated) tracks.
It provides a more comprehensive evaluation than α by accounting for false positives.

# Arguments
- `a` and `b` are `d` x `n` and `d` x `m` arrays, where `d` is the number of dimensions
- `cutoff` contains the maximum matching distance for each dimension

# Returns
- `Float64`: β measure in range [0, α], where higher values indicate better performance

# Details
The β measure is defined as β(X, Y) = (d(X, Ø) - d(X, Y))/(d(X, Ø) + d(Ȳ, Ø)), where:
- d(X, Y) is the total distance between optimally paired tracks
- d(X, Ø) is the maximum possible distance for ground truth tracks
- d(Ȳ, Ø) is the penalty for spurious estimated tracks
- More comprehensive than α as it accounts for false positives

# References
Chenouard et al., "Objective comparison of particle tracking methods", Nature Methods (2014)
"""
function beta(a::Array{<:Real}, b::Array{<:Real}, cutoff::Vector{<:Real})
    # Use existing match function to get optimal assignment
    assignment = match(a, b, cutoff)
    
    n_a = size(a, 2)
    n_b = size(b, 2)
    ε = norm(cutoff)
    
    # Calculate d(X, Y) - total distance for current assignment
    d_xy = 0.0
    matched_b_indices = Set{Int}()
    
    for i in 1:n_a
        if assignment[i] > 0
            # Paired assignment
            dist = sqrt(sum(abs2.(a[:, i] - b[:, assignment[i]])))
            d_xy += min(dist, ε)
            push!(matched_b_indices, assignment[i])
        else
            # Unpaired ground truth
            d_xy += ε
        end
    end
    
    # Calculate d(X, Ø) - maximum distance for ground truth
    d_x_dummy = n_a * ε
    
    # Calculate d(Ȳ, Ø) - penalty for spurious estimated tracks
    n_spurious = n_b - length(matched_b_indices)
    d_y_spurious_dummy = n_spurious * ε
    
    # β = (d(X,Ø) - d(X,Y)) / (d(X,Ø) + d(Ȳ,Ø))
    denominator = d_x_dummy + d_y_spurious_dummy
    return denominator > 0 ? (d_x_dummy - d_xy) / denominator : 1.0
end