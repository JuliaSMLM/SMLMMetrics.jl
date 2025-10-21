"""
Utility functions for BNP-Track data processing.
"""

using Statistics

"""
    extract_map_estimate(chain_samples::AbstractMatrix, burn_in::Int=0)

Extract Maximum A Posteriori (MAP) estimate from MCMC chain samples.

# Arguments
- `chain_samples`: Matrix of MCMC samples (iterations × particles)
- `burn_in`: Number of initial samples to discard (default: 0)

# Returns
- MAP estimate (median of post-burn-in samples)
"""
function extract_map_estimate(chain_samples::AbstractMatrix, burn_in::Int=0)
    if burn_in >= size(chain_samples, 1)
        @warn "Burn-in ($burn_in) >= chain length ($(size(chain_samples, 1))). Using all samples."
        burn_in = 0
    end

    # Use samples after burn-in
    valid_samples = chain_samples[(burn_in+1):end, :]

    # Use median as robust MAP estimate
    map_estimate = vec(median(valid_samples, dims=1))

    return map_estimate
end

"""
    extract_posterior_std(chain_samples::AbstractMatrix, burn_in::Int=0)

Extract posterior standard deviations from MCMC chain samples.

# Arguments
- `chain_samples`: Matrix of MCMC samples (iterations × particles)
- `burn_in`: Number of initial samples to discard

# Returns
- Posterior standard deviations for each particle
"""
function extract_posterior_std(chain_samples::AbstractMatrix, burn_in::Int=0)
    if burn_in >= size(chain_samples, 1)
        burn_in = 0
    end

    valid_samples = chain_samples[(burn_in+1):end, :]
    posterior_std = vec(std(valid_samples, dims=1))

    return posterior_std
end

"""
    compute_credible_interval(chain_samples::AbstractMatrix,
                             credible_level::Float64=0.95,
                             burn_in::Int=0)

Compute credible intervals from MCMC chain samples.

# Arguments
- `chain_samples`: Matrix of MCMC samples (iterations × particles)
- `credible_level`: Credible interval level (default: 0.95 for 95% CI)
- `burn_in`: Number of initial samples to discard

# Returns
- `lower_bound`: Lower bounds of credible intervals
- `upper_bound`: Upper bounds of credible intervals
"""
function compute_credible_interval(chain_samples::AbstractMatrix,
                                  credible_level::Float64=0.95,
                                  burn_in::Int=0)
    if burn_in >= size(chain_samples, 1)
        burn_in = 0
    end

    valid_samples = chain_samples[(burn_in+1):end, :]

    α = (1 - credible_level) / 2
    lower_quantile = α
    upper_quantile = 1 - α

    n_particles = size(valid_samples, 2)
    lower_bound = zeros(n_particles)
    upper_bound = zeros(n_particles)

    for i in 1:n_particles
        sorted_samples = sort(valid_samples[:, i])
        lower_bound[i] = quantile(sorted_samples, lower_quantile)
        upper_bound[i] = quantile(sorted_samples, upper_quantile)
    end

    return lower_bound, upper_bound
end

"""
    filter_active_particles(b::AbstractVector)

Filter to get indices of active (non-zero) particles based on existence indicator b.

BNP-Track uses a binary indicator `b` where b[i] = 1 means particle i exists.

# Arguments
- `b`: Binary existence indicator vector (1 × M where M is max particles)

# Returns
- Vector of indices where b[i] == 1
"""
function filter_active_particles(b::AbstractVector)
    return findall(x -> x > 0.5, b)  # Use 0.5 threshold for robustness
end

"""
    extract_track_timepoints(K::AbstractVector, active_particles::Vector{Int})

Extract time indices for each active track from atom assignment K.

BNP-Track's K assigns each time point to an atom (particle) index.

# Arguments
- `K`: Vector of atom assignments (1 × M where K[m] is the atom at time m)
- `active_particles`: Indices of active particles

# Returns
- Dict mapping particle_id => vector of time indices
"""
function extract_track_timepoints(K::AbstractVector, active_particles::Vector{Int})
    track_times = Dict{Int, Vector{Int}}()

    for particle_id in active_particles
        # Find all time indices assigned to this particle
        time_indices = findall(k -> k == particle_id, K)
        if !isempty(time_indices)
            track_times[particle_id] = time_indices
        end
    end

    return track_times
end
