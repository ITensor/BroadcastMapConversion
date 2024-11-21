using Pkg: Pkg
Pkg.develop(; path=joinpath(@__DIR__, ".."))

using BroadcastMapConversion
using Documenter

DocMeta.setdocmeta!(
  BroadcastMapConversion, :DocTestSetup, :(using BroadcastMapConversion); recursive=true
)

makedocs(;
  modules=[BroadcastMapConversion],
  authors="ITensor developers",
  sitename="BroadcastMapConversion.jl",
  format=Documenter.HTML(;
    canonical="https://ITensor.github.io/BroadcastMapConversion.jl",
    edit_link="main",
    assets=String[],
  ),
  pages=["Home" => "index.md", "Lib" => "lib.md"],
)

deploydocs(; repo="github.com/ITensor/BroadcastMapConversion.jl", devbranch="main")
