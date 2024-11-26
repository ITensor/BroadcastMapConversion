using Literate: Literate
using BroadcastMapConversion: BroadcastMapConversion

Literate.markdown(
  joinpath(pkgdir(BroadcastMapConversion), "examples", "README.jl"),
  joinpath(pkgdir(BroadcastMapConversion), "docs", "src");
  flavor=Literate.DocumenterFlavor(),
  name="index",
)
