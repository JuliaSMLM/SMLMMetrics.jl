# SMLMMetrics.jl

SMLMMetrics is a Julia package for analyzing single molecule super-resolution data. It provides metrics to evaluate the accuracy and precision of your SMLM coordinate data. 

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaSMLM.github.io/SMLMMetrics.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaSMLM.github.io/SMLMMetrics.jl/dev/)
[![Build Status](https://github.com/JuliaSMLM/SMLMMetrics.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaSMLM/SMLMMetrics.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/JuliaSMLM/SMLMMetrics.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaSMLM/SMLMMetrics.jl)

## Features

- Jaccard Index calculation for comparing localization sets
- Root Mean Square Error (RMSE) calculation for evaluating localization accuracy
- Dimensional weighting for RMSE calculations
- Flexible support for various data dimensions

## Installation

To install SMLMMetrics, use the Julia package manager:

```julia
using Pkg
Pkg.add("SMLMMetrics")
```

## Documentation

- [**STABLE**](https://JuliaSMLM.github.io/SMLMMetrics.jl/stable/) - Documentation for the most recently tagged version of SMLMMetrics.
- [**DEVELOPMENT**](https://JuliaSMLM.github.io/SMLMMetrics.jl/dev/) - Documentation for the in-development version of SMLMMetrics.

## Usage

After installing the package, you can start using SMLMMetrics in your project:

```julia
using SMLMMetrics
```

For more details and examples, please refer to the [documentation](https://JuliaSMLM.github.io/SMLMMetrics.jl/stable/).

## Contributing

Contributions to SMLMMetrics are always welcome! If you have any suggestions, feature requests, or bug reports, please open an issue on [GitHub](https://github.com/JuliaSMLM/SMLMMetrics.jl/issues).

## License

SMLMMetrics.jl is licensed under the [MIT License](LICENSE).
