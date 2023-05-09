var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = SMLMMetrics","category":"page"},{"location":"#SMLMMetrics","page":"Home","title":"SMLMMetrics","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for SMLMMetrics.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [SMLMMetrics]","category":"page"},{"location":"#SMLMMetrics.jaccard-Tuple{Any, Any, Any}","page":"Home","title":"SMLMMetrics.jaccard","text":"jaccard(a, b, cutoff)\n\nCalculate the Jaccard Index between the two sets a and b  using a maximum connection distance of cutoff.    \n\nThe Jaccard index is defined as:\n\nJ(A,B) =  |A ∩ B| / |A ∪ B|\n\nThe intersecting elements of A and B found by building and minimizing   a cost matrix whose elements are:\n\nC_{i,j} =\n    \\begin{cases}\n        \\|A_i - B_j\\|  & \\text{if all } A_{i,k} - B_{j,k} < d_k \\\\\n        \\infty           & \\text{otherwise}\n    \\end{cases}\n\nwhere d is a vector of cutoff values for each dimension of the data.\n\n\n\n\n\n","category":"method"},{"location":"#SMLMMetrics.jaccard-Tuple{Array{<:Real}, Array{<:Real}, Vector{<:Real}}","page":"Home","title":"SMLMMetrics.jaccard","text":"jaccard(a::Array{<:Real}, b::Array{<:Real}, cutoff::Vector{<:Real})\n\na and b are d x n, and d x m arrays, where d is the number of dimensions  \n\ncutoff contains the maximum matching distance for each dimension.\n\n\n\n\n\n","category":"method"},{"location":"#SMLMMetrics.match-Tuple{Array{<:Real}, Array{<:Real}, Vector{<:Real}}","page":"Home","title":"SMLMMetrics.match","text":"function match(a::Array{<:Real}, b::Array{<:Real}, cutoff::Vector{<:Real})\n\nFind best match between points in a and b. \n\n\n\n\n\n","category":"method"},{"location":"#SMLMMetrics.rmse-Tuple{Any, Any}","page":"Home","title":"SMLMMetrics.rmse","text":"function rmse(a, b)\n\nCalculate the root mean square error between a and b.\n\n\n\n\n\n","category":"method"},{"location":"#SMLMMetrics.rmse-Tuple{Array{<:Real}, Array{<:Real}, Vector{<:Real}}","page":"Home","title":"SMLMMetrics.rmse","text":"function rmse(a::Array{<:Real}, b::Array{<:Real}, α::Vector{<:Real})\n\nCalculate the root mean square error using a dimensional weighting α.\n\na and b are d x n, and d x m arrays, where d is the number of dimensions\n\nRMSE = (frac1dfrac1NSigma_k=1^dalpha_k^2Sigma_n=1^N      (a_ki-b_ki)^2)^{1/2}\n\n\n\n\n\n","category":"method"}]
}
