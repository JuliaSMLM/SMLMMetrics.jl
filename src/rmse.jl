# RMSE Errors

"""
    function rmse(a, b) 

Calculate the root mean square error between `a` and `b`.
"""
function rmse(a, b)
    return sqrt(mean(abs2.(a - b)))
end

"""
    function rmse(a::Array{<:Real}, b::Array{<:Real}, α::Vector{<:Real})

Calculate the root mean square error using a dimensional weighting `α`.

`a` and `b` are `d` x `n`, and `d` x `m` arrays, where `d` is the number of dimensions

``RMSE = (\\frac{1}{d}\\frac{1}{N}\\Sigma_{k=1}^{d}\\alpha_k^2\\Sigma_{n=1}^N 
    (a_{k,i}-b_{k,i})^2``)^{1/2}
"""
function rmse(a::Array{<:Real}, b::Array{<:Real}, α::Vector{<:Real})
    return sqrt(mean(mean(abs2.(a - b), dims=2) .* abs2.(α)))
end
