module SMLMMetrics

using Distances
using Hungarian
using Statistics
using SparseArrays
using SMLMData
using MAT

include("jaccard.jl")
include("rmse.jl")
include("efficiency.jl")
include("smlmdata.jl")
include("tracking/tracking.jl")
include("io/io.jl")
include("synthetic/synthetic.jl")

export jaccard, match, rmse, efficiency
export Tracking

# Export IO types and functions
export SmiteSMD, SmiteSMLD, load_smite_2d, load_smite_3d
export UTrackSMD, UTrackSMLD, load_utrack_2d, load_utrack_3d
export BNPTrackSMD, BNPTrackSMLD, load_bnptrack_2d, load_bnptrack_3d
export TrackingChallengeGT, ChallengeSMLD, load_challenge_gt, load_challenge_gt_2d, load_challenge_gt_3d

# Export Synthetic module
export Synthetic

end
