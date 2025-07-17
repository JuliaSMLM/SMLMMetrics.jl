# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SMLMMetrics.jl is a Julia package for analyzing single molecule super-resolution microscopy (SMLM) data. It provides metrics to evaluate the accuracy and precision of SMLM coordinate data.

## Common Development Commands

### Testing
```bash
# Run full test suite
julia --project=. -e "using Pkg; Pkg.test()"

# Interactive development (use dev/ directory)
julia --project=dev
```

### Documentation
```bash
# Build documentation
julia --project=docs docs/make.jl
```

### Package Management
```bash
# Install dependencies
julia --project=. -e "using Pkg; Pkg.instantiate()"

# Update dependencies
julia --project=. -e "using Pkg; Pkg.update()"
```

## Code Architecture

### Core Module Structure
- **SMLMMetrics.jl** - Main module that exports all functions
- **jaccard.jl** - Jaccard Index calculation and point matching using Hungarian algorithm
- **rmse.jl** - Root Mean Square Error calculations with dimensional weighting
- **efficiency.jl** - Combined efficiency metric calculation
- **smlmdata.jl** - Integration with SMLMData types (SMLD2D, SMLD3D)

### Key Functions
- `jaccard(a, b, cutoff)` - Jaccard Index for comparing localization sets
- `match(a, b, cutoff)` - Point matching using Hungarian algorithm
- `rmse(a, b, α)` - RMSE with optional dimensional weighting parameter α
- `efficiency(a, b, cutoff, α)` - Combined efficiency metric

### Data Support
The package supports both raw coordinate arrays (d × n matrices) and SMLMData structures (SMLD2D, SMLD3D) for 2D and 3D localization data.

### Dependencies
- `Distances` - Distance calculations
- `Hungarian` - Hungarian algorithm for optimal matching
- `SMLMData` - SMLM data structures
- `SparseArrays` - Sparse array operations

## Development Workflow

### Interactive Development
Use the `dev/` directory with Revise.jl for interactive development. This directory contains development-specific dependencies like CairoMakie for plotting.

### CI/CD Pipeline
- GitHub Actions runs tests on Julia 1.6, 1.8, and nightly
- Documentation auto-deployed to GitHub Pages
- CompatHelper manages dependency updates
- TagBot handles automatic version tagging

### Code Style
Follow standard Julia package conventions. The codebase uses:
- Modular design with separate files for each metric
- DocStrings for all exported functions
- Comprehensive test coverage in test/runtests.jl