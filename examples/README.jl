md"""
# BroadcastMapConversion

[![Docs][docs-img]][docs-url]
[![Build Status][ci-img]][ci-url]
[![Coverage][codecov-img]][codecov-url]
[![Code Style][style-img]][style-url]
[![Aqua][aqua-img]][aqua-url]

[docs-img]: https://img.shields.io/badge/docs-latest%20release-blue.svg
[docs-url]: https://ITensor.github.io/BroadcastMapConversion.jl/stable/

[ci-img]: https://github.com/ITensor/BroadcastMapConversion.jl/actions/workflows/CI.yml/badge.svg?branch=main
[ci-url]: https://github.com/ITensor/BroadcastMapConversion.jl/actions/workflows/CI.yml?query=branch%3Amain

[codecov-img]: https://codecov.io/gh/ITensor/BroadcastMapConversion.jl/branch/main/graph/badge.svg
[codecov-url]: https://codecov.io/gh/ITensor/BroadcastMapConversion.jl

[style-img]: https://img.shields.io/badge/code%20style-blue-4495d1.svg
[style-url]: https://github.com/invenia/BlueStyle

[aqua-img]: https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg
[aqua-url]: https://github.com/JuliaTesting/Aqua.jl

This is a small package that provides a way to convert a `Broadcasted` object into a call to `map`.
It contains a slightly generalized version of the logic used in [Strided.jl](https://github.com/Jutho/Strided.jl), as can be seen [here](https://github.com/Jutho/Strided.jl/blob/v2.0.4/src/broadcast.jl).

The core idea is to capture non-`AbstractArray` objects, such as `Number`s, as these have to be repeated across the dimensions of the `Broadcasted` object.
In `Strided.jl`, the logic is only used to capture non-`StridedView` objects, while here it is generalized to non-`AbstractArray` types.

## Installation

The package can be installed with the Julia package manager via its GitHub link.
From the Julia REPL, you can run:
"""

using Pkg: Pkg
Pkg.add("https://github.com/ITensor/BroadcastMapConversion.jl")
