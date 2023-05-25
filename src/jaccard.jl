# Jaccard Index function and methods

"""
    jaccard(a, b, cutoff)

Calculate the Jaccard Index between the two sets `a` and `b` 
using a maximum connection distance of `cutoff`.    

The Jaccard index is defined as:

    J(A,B) =  |A ∩ B| / |A ∪ B|

The intersecting elements of A and B found by building and minimizing  
a cost matrix whose elements are:

```math
C_{i,j} =
\\begin{cases}
\\left\\| A_{i,:} - B_{j,:} \\right\\| & \\text{if all } A_{i,k} - B_{j,k} < d_k \\\\
\\infty & \\text{otherwise}
\\end{cases}
```

where d is a vector of cutoff values for each dimension of the data.

"""
function jaccard(a, b, cutoff)
end


"""
    jaccard(a::Array{<:Real}, b::Array{<:Real}, cutoff::Vector{<:Real})

`a` and `b` are `d` x `n`, and `d` x `m` arrays, where `d` is the number of dimensions  

`cutoff` contains the maximum matching distance for each dimension.

"""
function jaccard(a::Array{<:Real}, b::Array{<:Real}, cutoff::Vector{<:Real})

    assignment = match(a, b, cutoff)

    n_a = size(a, 2)
    n_b = size(b, 2)
    n_match = sum(assignment .> 0.0)
    return (n_match) / (n_a + n_b - n_match)

end

"""
    match(a::Array{<:Real}, b::Array{<:Real}, cutoff::Vector{<:Real})

Find the best matching pairs of points between `a` and `b` based on Euclidean distance, 
with a specified maximum acceptable distance for each dimension defined in `cutoff`.

The function uses the Hungarian algorithm to find the optimal assignment that minimizes
the total distance between pairs. 

Parameters:
- `a` and `b` are `d` x `n` and `d` x `m` arrays, respectively, where `d` is the number of dimensions.
- `cutoff` is a `d`-dimensional vector, specifying the maximum acceptable distance in each dimension.

The function returns a `n`-dimensional vector, where the `i`th element is the index of the point in `b`
that is matched with the `i`th point in `a`. If the `i`th point in `a` has no match in `b` (i.e., the distance
to all points in `b` is larger than the `cutoff`), then the `i`th element of the returned vector is 0.

The function uses a cost matrix approach, where the cost is the Euclidean distance between points. If the 
distance between a pair of points exceeds the `cutoff`, the cost is set to a large value to effectively eliminate 
that pairing from consideration. The Hungarian algorithm is then used to find the assignment that minimizes the 
total cost. The cost matrix and the assignment are adjusted such that pairs with a cost equal to the large value 
are unassigned (i.e., set to 0 in the assignment vector).

"""
function match(a::Array{<:Real}, b::Array{<:Real}, cutoff::Vector{<:Real})
    
    n_a = size(a, 2)
    n_b = size(b, 2)
    n_d = size(a, 1)

    largevalue = 1e6
    costmatrix = largevalue .+ zeros(Float32, n_a, n_b)

    # Pairwise distance for valid points 
    for i in 1:n_a, j in 1:n_b
        if prod([abs(a[k, i] - b[k, j]) < cutoff[k] for k in 1:n_d])
            costmatrix[i, j] = sqrt(sum([abs2(a[k, i] - b[k, j]) for k in 1:n_d]))
        end
    end
   
    # Use hungarian. NOTE: Hungarian hangs when using 'missing', thus the workaround
    assignment, cost = hungarian(Array(costmatrix))

    # Unassign those with cost of largevalue
    for i in 1:lastindex(assignment)
        if (assignment[i] > 0) 
            if costmatrix[i, assignment[i]] ≈ largevalue
                assignment[i] = 0
            end
        end
    end

    return assignment
end
