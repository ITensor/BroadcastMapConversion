# BroadcastMapConversion

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ITensor.github.io/BroadcastMapConversion.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ITensor.github.io/BroadcastMapConversion.jl/dev/)
[![Build Status](https://github.com/ITensor/BroadcastMapConversion.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ITensor/BroadcastMapConversion.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/ITensor/BroadcastMapConversion.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/ITensor/BroadcastMapConversion.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

This is a small package that provides a way to convert a `Broadcasted` object into a call to `map`.
It contains a slightly generalized version of the logic used in [Strided.jl](https://github.com/Jutho/Strided.jl), as can be seen [here](https://github.com/Jutho/Strided.jl/blob/v2.0.4/src/broadcast.jl).

The core idea is to capture non-`AbstractArray` objects, such as `Number`s, as these have to be repeated across the dimensions of the `Broadcasted` object.
In `Strided.jl`, the logic is only used to capture non-`StridedView` objects, while here it is generalized to non-`AbstractArray` types.

## Installation

```julia
julia> import Pkg

julia> Pkg.add("https://github.com/ITensor/BroadcastMapConversion.jl")
```
