using SafeTestsets: @safetestset

@time @safetestset "BroadcastMapConversion" begin
  using Test: @test, @testset
  using BroadcastMapConversion: map_function, map_args
  using Base.Broadcast: Broadcasted

  c = 2.2
  a = randn(2, 3)
  b = randn(2, 3)
  bc = Broadcasted(*, (c, a))
  @test copy(bc) ≈ c * a ≈ map(map_function(bc), map_args(bc)...)
  bc = Broadcasted(+, (a, b))
  @test copy(bc) ≈ a + b ≈ map(map_function(bc), map_args(bc)...)
end

@time @safetestset "Aqua tests" begin
  using Aqua: Aqua
  using BroadcastMapConversion: BroadcastMapConversion
  Aqua.test_all(BroadcastMapConversion)
end
