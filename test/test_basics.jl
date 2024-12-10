using Base.Broadcast: Broadcasted
using BroadcastMapConversion: map_function, map_args
using Test: @test, @testset

@testset "BroadcastMapConversion" begin
  c = 2.2
  a = randn(2, 3)
  b = randn(2, 3)
  bc = Broadcasted(*, (c, a))
  @test copy(bc) ≈ c * a ≈ map(map_function(bc), map_args(bc)...)
  bc = Broadcasted(+, (a, b))
  @test copy(bc) ≈ a + b ≈ map(map_function(bc), map_args(bc)...)
end
