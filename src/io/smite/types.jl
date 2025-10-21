"""
SMITE data structures for loading tracking results.

SMITE (Single Molecule Imaging Toolbox Extraordinaire) from LidkeLab outputs
tracking data in MATLAB .mat files with SMD (Single Molecule Data) structures.

This is a reference implementation based on the SMLMData.jl package at:
https://github.com/JuliaSMLM/SMLMData.jl/tree/main/src/io/smite
"""

using SMLMData

"""
    SmiteSMD

Specifies a SMITE .mat file to load.

# Fields
- `filepath::String`: Directory containing the .mat file
- `filename::String`: Name of the .mat file
- `varname::String`: Variable name in .mat file (default: "SMD")
"""
mutable struct SmiteSMD
    filepath::String
    filename::String
    varname::String
end

"""
    SmiteSMD(filepath, filename)

Create a SmiteSMD with default variable name "SMD".
"""
function SmiteSMD(filepath::String, filename::String)
    return SmiteSMD(filepath, filename, "SMD")
end

"""
    SmiteSMLD{T,E<:AbstractEmitter} <: SMLD

Container for SMITE tracking data converted to SMLMData format.

# Fields
- `emitters::Vector{E}`: Vector of emitters (Emitter2DFit or Emitter3DFit)
- `camera::AbstractCamera`: Camera information
- `n_frames::Int`: Total number of frames
- `n_datasets::Int`: Number of datasets
- `metadata::Dict{String,Any}`: Additional metadata from SMITE output
"""
struct SmiteSMLD{T,E<:AbstractEmitter} <: SMLD
    emitters::Vector{E}
    camera::AbstractCamera
    n_frames::Int
    n_datasets::Int
    metadata::Dict{String,Any}
end
