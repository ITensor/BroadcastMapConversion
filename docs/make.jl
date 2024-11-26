using BroadcastMapConversion: BroadcastMapConversion
using Documenter: Documenter, DocMeta, deploydocs, makedocs

DocMeta.setdocmeta!(
  BroadcastMapConversion, :DocTestSetup, :(using BroadcastMapConversion); recursive=true
)

include("make_index.jl")

makedocs(;
  modules=[BroadcastMapConversion],
  authors="ITensor developers <support@itensor.org> and contributors",
  sitename="BroadcastMapConversion.jl",
  format=Documenter.HTML(;
    canonical="https://ITensor.github.io/BroadcastMapConversion.jl",
    edit_link="main",
    assets=String[],
  ),
  pages=["Home" => "index.md"],
)

deploydocs(;
  repo="github.com/ITensor/BroadcastMapConversion.jl", devbranch="main", push_preview=true
)
