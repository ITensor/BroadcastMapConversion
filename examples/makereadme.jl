using Literate

# Generate the README
input_readme = joinpath(@__DIR__, "README.jl")
output_dir = joinpath(@__DIR__, "..", "docs", "src")
Literate.markdown(
  input_readme, output_dir; flavor=Literate.CommonMarkFlavor(), mdstrings=true, name="index"
)
