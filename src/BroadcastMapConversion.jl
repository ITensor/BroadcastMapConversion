module BroadcastMapConversion
# Convert broadcast call to map call by capturing array arguments
# with `map_args` and creating a map function with `map_function`.
# Logic from https://github.com/Jutho/Strided.jl/blob/v2.0.4/src/broadcast.jl.

using Base.Broadcast:
  Broadcast, BroadcastStyle, Broadcasted, broadcasted, combine_eltypes, instantiate

const WrappedScalarArgs = Union{AbstractArray{<:Any,0},Ref{<:Any}}

# Get the arguments of the map expression that
# is equivalent to the broadcast expression.
function map_args(bc::Broadcasted)
  return map_args_flatten(bc)
end

function map_args_flatten(bc::Broadcasted, args_rest...)
  return (map_args_flatten(bc.args...)..., map_args_flatten(args_rest...)...)
end
function map_args_flatten(arg1::AbstractArray, args_rest...)
  return (arg1, map_args_flatten(args_rest...)...)
end
map_args_flatten(arg1, args_rest...) = map_args_flatten(args_rest...)
map_args_flatten() = ()

struct MapFunction{F,Args<:Tuple} <: Function
  f::F
  args::Args
end
struct Arg end

# Get the function of the map expression that
# is equivalent to the broadcast expression.
# Returns a `MapFunction`.
function map_function(bc::Broadcasted)
  return map_function_arg(bc)
end
map_function_args(args::Tuple{}) = args
function map_function_args(args::Tuple)
  return (map_function_arg(args[1]), map_function_args(Base.tail(args))...)
end
function map_function_arg(bc::Broadcasted)
  return MapFunction(bc.f, map_function_args(bc.args))
end
map_function_arg(a::WrappedScalarArgs) = a[]
map_function_arg(a::AbstractArray) = Arg()
map_function_arg(a) = a

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

is_map_expr_or_arg(arg::AbstractArray) = true
is_map_expr_or_arg(arg::Any) = false
function is_map_expr_or_arg(bc::Broadcasted)
  return all(is_map_expr_or_arg, bc.args)
end
function is_map_expr(bc::Broadcasted)
  return is_map_expr_or_arg(bc)
end

abstract type ExprStyle end
struct MapExpr <: ExprStyle end
struct NotMapExpr <: ExprStyle end

ExprStyle(bc::Broadcasted) = is_map_expr(bc) ? MapExpr() : NotMapExpr()

abstract type AbstractMapped <: Base.AbstractBroadcasted end

struct Mapped{Style<:Union{Nothing,BroadcastStyle},Axes,F,Args<:Tuple} <: AbstractMapped
  style::Style
  f::F
  args::Args
  axes::Axes
end

# SimpleTraits.trait(Tr{X})

function Mapped(bc::Broadcasted)
  return Mapped(ExprStyle(bc), bc)
end
function Mapped(::NotMapExpr, bc::Broadcasted)
  return Mapped(bc.style, map_function(bc), map_args(bc), bc.axes)
end
function Mapped(::MapExpr, bc::Broadcasted)
  return Mapped(bc.style, bc.f, bc.args, bc.axes)
end

function Broadcast.Broadcasted(m::Mapped)
  return Broadcasted(m.style, m.f, m.args, m.axes)
end

## # Convert `Broadcasted` to `Mapped` when `Broadcasted`
## # is known to already be a map expression.
## function map_broadcast_to_mapped(bc::Broadcasted)
##   return Mapped(bc.style, bc.f, bc.args, bc.axes)
## end

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
Broadcast.instantiate(m::Mapped) = Mapped(instantiate(Broadcasted(m)))

end
