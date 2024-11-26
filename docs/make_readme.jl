using Literate: Literate
using BroadcastMapConversion: BroadcastMapConversion

Literate.markdown(
  joinpath(pkgdir(BroadcastMapConversion), "examples", "README.jl"),
  joinpath(pkgdir(BroadcastMapConversion));
  flavor=Literate.CommonMarkFlavor(),
  name="README",
)
