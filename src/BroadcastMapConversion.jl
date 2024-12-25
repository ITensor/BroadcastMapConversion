module BroadcastMapConversion
# Convert broadcast call to map call by capturing array arguments
# with `map_args` and creating a map function with `map_function`.
# Logic from https://github.com/Jutho/Strided.jl/blob/v2.0.4/src/broadcast.jl.

using Base.Broadcast:
  Broadcast, BroadcastStyle, Broadcasted, broadcasted, combine_eltypes, instantiate

const WrappedScalarArgs = Union{AbstractArray{<:Any,0},Ref{<:Any}}

# Get the arguments of the map expression that
# is equivalent to the broadcast expression.
function map_args(bc::Broadcasted, rest...)
  return (map_args(bc.args...)..., map_args(rest...)...)
end
map_args(a::AbstractArray, rest...) = (a, map_args(rest...)...)
map_args(a, rest...) = map_args(rest...)
map_args() = ()

struct MapFunction{F,Args<:Tuple} <: Function
  f::F
  args::Args
end
struct Arg end

# Get the function of the map expression that
# is equivalent to the broadcast expression.
# Returns a `MapFunction`.
function map_function(bc::Broadcasted)
  args = map_function_tuple(bc.args)
  return MapFunction(bc.f, args)
end
map_function_tuple(t::Tuple{}) = t
map_function_tuple(t::Tuple) = (map_function(t[1]), map_function_tuple(Base.tail(t))...)
map_function(a::WrappedScalarArgs) = a[]
map_function(a::AbstractArray) = Arg()
map_function(a) = a

# Evaluate MapFunction
(f::MapFunction)(args...) = apply(f, args)[1]
function apply(f::MapFunction, args)
  args, newargs = apply_tuple(f.args, args)
  return f.f(args...), newargs
end
apply(a::Arg, args::Tuple) = args[1], Base.tail(args)
apply(a, args) = a, args
apply_tuple(t::Tuple{}, args) = t, args
function apply_tuple(t::Tuple, args)
  t1, newargs1 = apply(t[1], args)
  ttail, newargs = apply_tuple(Base.tail(t), newargs1)
  return (t1, ttail...), newargs
end

abstract type AbstractMapped <: Base.AbstractBroadcasted end

struct Mapped{Style<:Union{Nothing,BroadcastStyle},Axes,F,Args<:Tuple} <: AbstractMapped
  style::Style
  f::F
  args::Args
  axes::Axes
end

function Mapped(bc::Broadcasted)
  return Mapped(bc.style, map_function(bc), map_args(bc), bc.axes)
end
function Broadcast.Broadcasted(m::Mapped)
  return Broadcasted(m.style, m.f, m.args, m.axes)
end

# Convert `Broadcasted` to `Mapped` when `Broadcasted`
# is known to already be a map expression.
function map_broadcast_to_mapped(bc::Broadcasted)
  return Mapped(bc.style, bc.f, bc.args, bc.axes)
end

mapped(f, args...) = Mapped(broadcasted(f, args...))

Base.similar(m::Mapped, elt::Type) = similar(Broadcasted(m), elt)
Base.similar(m::Mapped, elt::Type, ax::Tuple) = similar(Broadcasted(m), elt, ax)
Base.axes(m::Mapped) = axes(Broadcasted(m))
# Equivalent to:
# map(m.f, m.args...)
# copy(Broadcasted(m))
function Base.copy(m::Mapped)
  elt = combine_eltypes(m.f, m.args)
  # TODO: Handle case of non-concrete eltype.
  @assert Base.isconcretetype(elt)
  return copyto!(similar(m, elt), m)
end
Base.copyto!(dest::AbstractArray, m::Mapped) = map!(m.f, dest, m.args...)
Broadcast.instantiate(m::Mapped) = map_broadcast_to_mapped(instantiate(Broadcasted(m)))

end
