using Base.Broadcast: broadcasted
using BroadcastMapConversion: Mapped, mapped
using Test: @test, @testset

@testset "BroadcastMapConversion (eltype=$elt)" for elt in (
  Float32, Float64, Complex{Float32}, Complex{Float64}
)
  c = elt(2.2)
  a = randn(elt, 2, 3)
  b = randn(elt, 2, 3)
  for (bc, m′, ref) in (
    (broadcasted(*, c, a), mapped(x -> c * x, a), c * a),
    (broadcasted(+, a, broadcasted(*, c, b)), mapped((x, y) -> x + c * y, a, b), a + c * b),
  )
    m = Mapped(bc)
    @test copy(m) ≈ ref
    @test copy(m′) ≈ ref
    @test map(m.f, m.args...) ≈ ref
    @test map(m′.f, m′.args...) ≈ ref
    @test axes(m) == axes(bc)
    @test axes(m′) == axes(bc)
    @test copyto!(similar(m, elt), m) ≈ ref
    @test copyto!(similar(m′, elt), m) ≈ ref
  end
end
