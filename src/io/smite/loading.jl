"""
Functions for loading SMITE tracking data and converting to SMLMData format.

Based on the reference implementation in SMLMData.jl:
https://github.com/JuliaSMLM/SMLMData.jl/tree/main/src/io/smite
"""

using MAT
using SMLMData
using SMLMData: Emitter2DFit, Emitter3DFit, IdealCamera

"""
    check_complex_fields(s::Dict, field_names::Vector{String})

Check for complex numbers with non-zero imaginary parts in SMITE data.

SMITE sometimes produces complex numbers in position and photometry fields.
This function identifies which emitters have non-zero imaginary components.

# Returns
- `has_complex::Bool`: True if any complex fields were found
- `complex_indices::Dict{String, Vector{Int}}`: Mapping of field name to indices with complex values
"""
function check_complex_fields(s::Dict, field_names::Vector{String})
    complex_indices = Dict{String, Vector{Int}}()
    has_complex = false

    for field in field_names
        if haskey(s, field)
            data = s[field]
            if eltype(data) <: Complex
                # Find indices with non-zero imaginary parts
                complex_idx = findall(x -> abs(imag(x)) > 1e-10, data)
                if !isempty(complex_idx)
                    complex_indices[field] = complex_idx
                    has_complex = true
                end
            end
        end
    end

    return has_complex, complex_indices
end

"""
    get_valid_indices(s::Dict, complex_indices::Dict{String, Vector{Int}})

Get indices of emitters that don't have complex values.

# Returns
- Vector of valid indices (emitters without complex values)
"""
function get_valid_indices(s::Dict, complex_indices::Dict{String, Vector{Int}})
    # Combine all complex indices from all fields
    all_complex_idx = Set{Int}()
    for (field, indices) in complex_indices
        union!(all_complex_idx, indices)
    end

    # Get total number of emitters
    n_total = length(s["X"])

    # Valid indices are those not in the complex set
    valid_indices = filter(i -> !(i in all_complex_idx), 1:n_total)

    return valid_indices
end

"""
    load_smite_2d(smd::SmiteSMD)

Load SMITE 2D tracking results and convert to SMLMData format.

# Arguments
- `smd::SmiteSMD`: Specification of SMITE .mat file to load

# Returns
- `SmiteSMLD{Float64, Emitter2DFit{Float64}}`: Converted tracking data

# Notes
- Automatically handles complex numbers by excluding emitters with non-zero imaginary parts
- Extracts pixel size from metadata (default 0.1 μm if not specified)
- Maps SMITE ConnectID to track_id in SMLMData
"""
function load_smite_2d(smd::SmiteSMD)
    # Load MATLAB file
    file_path = joinpath(smd.filepath, smd.filename)
    mat_data = matread(file_path)

    if !haskey(mat_data, smd.varname)
        error("Variable '$(smd.varname)' not found in $(file_path)")
    end

    s = mat_data[smd.varname]

    # Check for complex fields
    fields_to_check = ["X", "Y", "Photons", "Bg", "X_SE", "Y_SE", "Photons_SE", "Bg_SE"]
    has_complex, complex_indices = check_complex_fields(s, fields_to_check)

    # Get valid indices (excluding complex emitters)
    if has_complex
        valid_indices = get_valid_indices(s, complex_indices)
        n_removed = length(s["X"]) - length(valid_indices)
        @warn "Found $n_removed emitters with non-zero imaginary components. These will be excluded."
    else
        valid_indices = 1:length(s["X"])
    end

    # Extract metadata
    pixel_size = get(s, "PixelSize", 0.1)  # Default 0.1 microns
    x_size = Int(s["XSize"])
    y_size = Int(s["YSize"])
    n_frames = Int(s["NFrames"])
    n_datasets = Int(s["NDatasets"])

    # Create camera
    camera = IdealCamera(1:x_size, 1:y_size, pixel_size)

    # Create emitters
    emitters = Vector{Emitter2DFit{Float64}}(undef, length(valid_indices))

    for (new_idx, i) in enumerate(valid_indices)
        # Extract and convert to Float64, taking real part
        x = Float64(real(s["X"][i]))
        y = Float64(real(s["Y"][i]))
        photons = Float64(real(s["Photons"][i]))
        bg = Float64(real(s["Bg"][i]))
        σ_x = Float64(real(s["X_SE"][i]))
        σ_y = Float64(real(s["Y_SE"][i]))
        σ_photons = Float64(real(s["Photons_SE"][i]))
        σ_bg = Float64(real(s["Bg_SE"][i]))

        emitters[new_idx] = Emitter2DFit{Float64}(
            x, y, photons, bg,
            σ_x, σ_y, σ_photons, σ_bg;
            frame=Int(s["FrameNum"][i]),
            dataset=Int(s["DatasetNum"][i]),
            track_id=Int(s["ConnectID"][i]),  # KEY: ConnectID maps to track_id
            id=i
        )
    end

    # Create metadata
    metadata = Dict{String,Any}(
        "original_file" => smd.filename,
        "method" => "SMITE",
        "data_size" => [y_size, x_size],
        "pixel_size" => pixel_size
    )

    # Add complex field information if any were removed
    if has_complex
        metadata["complex_fields_removed"] = true
        metadata["complex_fields"] = collect(keys(complex_indices))
        metadata["original_emitter_count"] = length(s["X"])
        metadata["removed_emitter_count"] = n_removed
    end

    return SmiteSMLD{Float64, Emitter2DFit{Float64}}(
        emitters,
        camera,
        n_frames,
        n_datasets,
        metadata
    )
end

"""
    load_smite_3d(smd::SmiteSMD)

Load SMITE 3D tracking results and convert to SMLMData format.

Similar to `load_smite_2d` but includes z-coordinates and uses `Emitter3DFit`.

# Arguments
- `smd::SmiteSMD`: Specification of SMITE .mat file to load

# Returns
- `SmiteSMLD{Float64, Emitter3DFit{Float64}}`: Converted 3D tracking data
"""
function load_smite_3d(smd::SmiteSMD)
    # Load MATLAB file
    file_path = joinpath(smd.filepath, smd.filename)
    mat_data = matread(file_path)

    if !haskey(mat_data, smd.varname)
        error("Variable '$(smd.varname)' not found in $(file_path)")
    end

    s = mat_data[smd.varname]

    # Check for complex fields (including Z and Z_SE)
    fields_to_check = ["X", "Y", "Z", "Photons", "Bg", "X_SE", "Y_SE", "Z_SE", "Photons_SE", "Bg_SE"]
    has_complex, complex_indices = check_complex_fields(s, fields_to_check)

    # Get valid indices
    if has_complex
        valid_indices = get_valid_indices(s, complex_indices)
        n_removed = length(s["X"]) - length(valid_indices)
        @warn "Found $n_removed emitters with non-zero imaginary components. These will be excluded."
    else
        valid_indices = 1:length(s["X"])
    end

    # Extract metadata
    pixel_size = get(s, "PixelSize", 0.1)
    x_size = Int(s["XSize"])
    y_size = Int(s["YSize"])
    z_size = Int(get(s, "ZSize", 1))
    n_frames = Int(s["NFrames"])
    n_datasets = Int(s["NDatasets"])

    # Create camera
    camera = IdealCamera(1:x_size, 1:y_size, pixel_size)

    # Create emitters
    emitters = Vector{Emitter3DFit{Float64}}(undef, length(valid_indices))

    for (new_idx, i) in enumerate(valid_indices)
        # Extract and convert to Float64, including z-coordinate
        x = Float64(real(s["X"][i]))
        y = Float64(real(s["Y"][i]))
        z = Float64(real(s["Z"][i]))
        photons = Float64(real(s["Photons"][i]))
        bg = Float64(real(s["Bg"][i]))
        σ_x = Float64(real(s["X_SE"][i]))
        σ_y = Float64(real(s["Y_SE"][i]))
        σ_z = Float64(real(s["Z_SE"][i]))
        σ_photons = Float64(real(s["Photons_SE"][i]))
        σ_bg = Float64(real(s["Bg_SE"][i]))

        emitters[new_idx] = Emitter3DFit{Float64}(
            x, y, z, photons, bg,
            σ_x, σ_y, σ_z, σ_photons, σ_bg;
            frame=Int(s["FrameNum"][i]),
            dataset=Int(s["DatasetNum"][i]),
            track_id=Int(s["ConnectID"][i]),
            id=i
        )
    end

    # Create metadata
    metadata = Dict{String,Any}(
        "original_file" => smd.filename,
        "method" => "SMITE",
        "data_size" => [y_size, x_size, z_size],
        "pixel_size" => pixel_size
    )

    if has_complex
        metadata["complex_fields_removed"] = true
        metadata["complex_fields"] = collect(keys(complex_indices))
        metadata["original_emitter_count"] = length(s["X"])
        metadata["removed_emitter_count"] = n_removed
    end

    return SmiteSMLD{Float64, Emitter3DFit{Float64}}(
        emitters,
        camera,
        n_frames,
        n_datasets,
        metadata
    )
end
