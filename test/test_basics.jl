using Base.Broadcast: broadcasted
using BroadcastMapConversion: Mapped, is_map_expr, mapped
using Test: @inferred, @test, @test_throws, @testset

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
    x = similar(m, Float32, Base.OneTo.((3, 2)))
    @test x isa Matrix{Float32}
    @test size(x) == (3, 2)
  end

  @test @inferred is_map_expr(
    Broadcast.broadcasted(+, [2], Broadcast.broadcasted(sin, [2]))
  )
  @test @inferred !is_map_expr(Broadcast.broadcasted(+, 2, Broadcast.broadcasted(sin, [2])))

  # Logic handling singleton dimensions in broadcasting.
  for (a, b) in (
    (randn(elt, 2, 2), randn(elt, 2)),
    (randn(elt, 2, 2), randn(elt, 1, 2)),
    (randn(elt, 2, 1), randn(elt, 1, 2)),
    (randn(elt, 2, 2, 2), randn(elt, 2)),
    (randn(elt, 2, 2, 2), randn(elt, 1, 2)),
    (randn(elt, 2, 2, 2), randn(elt, 1, 1, 2)),
    (randn(elt, 2, 2, 2), randn(elt, 2, 2)),
    (randn(elt, 2, 2, 2), randn(elt, 1, 2, 2)),
  )
    @test_throws DimensionMismatch mapped(+, a, b)
    bc = broadcasted(+, a, b)
    m = Mapped(bc)
    @test copy(m) == copy(bc)
  end
end
