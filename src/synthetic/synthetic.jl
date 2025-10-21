# Synthetic Data Generation Module for SMLMMetrics
#
# This module provides tools for generating synthetic SMLM tracking data
# using SMLMSim for realistic particle tracking benchmarks.

module Synthetic

using SMLMData
using SMLMData: BasicSMLD, Emitter2DFit, Emitter3DFit, IdealCamera
using Random
using SMLMSim
using LightXML
using MAT

# Include submodules
include("types.jl")
include("generation.jl")
include("export.jl")

# Export types
export SyntheticConfig, SyntheticDataset
export Presets

# Export main generation functions
export generate_synthetic_data

# Export export functions
export export_ground_truth_xml, export_ground_truth_mat, export_noisy_data_mat
export save_dataset

end # module Synthetic
