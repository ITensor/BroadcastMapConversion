module BroadcastMapConversion
# Convert broadcast call to map call by capturing array arguments
# with `map_args` and creating a map function with `map_function`.
# Logic from https://github.com/Jutho/Strided.jl/blob/v2.0.4/src/broadcast.jl.

using Base.Broadcast:
  Broadcast, BroadcastStyle, Broadcasted, broadcasted, combine_eltypes, instantiate
using Compat: allequal

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
(f::MapFunction)(args...) = apply_arg(f, args)[1]
function apply_arg(f::MapFunction, args)
  mapfunction_args, args′ = apply_args(f.args, args)
  return f.f(mapfunction_args...), args′
end
apply_arg(mapfunction_arg::Arg, args) = args[1], Base.tail(args)
apply_arg(mapfunction_arg, args) = mapfunction_arg, args
function apply_args(mapfunction_args::Tuple, args)
  mapfunction_args1, args′ = apply_arg(mapfunction_args[1], args)
  mapfunction_args_rest, args′′ = apply_args(Base.tail(mapfunction_args), args′)
  return (mapfunction_args1, mapfunction_args_rest...), args′′
end
apply_args(mapfunction_args::Tuple{}, args) = mapfunction_args, args

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

function check_shape(::Type{Bool}, args...)
  return allequal(axes, args)
end
function check_shape(args...)
  if !check_shape(Bool, args...)
    throw(DimensionMismatch("Mismatched shapes $(axes.(args))."))
  end
  return nothing
end

# Promote the shape of the arguments to support broadcasting
# over dimensions by expanding singleton dimensions.
function promote_shape(ax, args::AbstractArray...)
  if allequal((ax, axes.(args)...))
    return args
  end
  return promote_shape_tile(ax, args...)
end
function promote_shape_tile(common_axes, args::AbstractArray...)
  return map(arg -> tile_to_shape(arg, common_axes), args)
end

using BlockArrays: mortar
using FillArrays: Fill

# Extend by repeating value up to length.
function extend(t::Tuple, value, length)
  return ntuple(i -> get(t, i, value), length)
end

# Handles logic of expanding singleton dimensions
# to match an array shape in broadcasting.
function tile_to_shape(a::AbstractArray, ax)
  axes(a) == ax && return a
  # Must be one-based for now.
  @assert all(isone, first.(ax))
  @assert all(isone, first.(axes(a)))
  ndim = length(ax)
  size′ = extend(size(a), 1, ndim)
  a′ = reshape(a, size′)
  target_size = length.(ax)
  fillsize = ntuple(ndim) do dim
    size′[dim] == target_size[dim] && return 1
    isone(size′[dim]) && return target_size[dim]
    return throw(DimensionMismatch("Dimensions $(axes(a)) and $ax don't match."))
  end
  return mortar(Fill(a′, fillsize))
end

struct Mapped{Style<:Union{Nothing,BroadcastStyle},Axes,F,Args<:Tuple} <: AbstractMapped
  style::Style
  f::F
  args::Args
  axes::Axes
  function Mapped(style, f, args, axes)
    check_shape(args...)
    return new{typeof(style),typeof(axes),typeof(f),typeof(args)}(style, f, args, axes)
  end
end

function Mapped(bc::Broadcasted)
  return Mapped(ExprStyle(bc), bc)
end
function Mapped(::NotMapExpr, bc::Broadcasted)
  f = map_function(bc)
  ax = axes(bc)
  args = promote_shape(ax, map_args(bc)...)
  return Mapped(bc.style, f, args, ax)
end
function Mapped(::MapExpr, bc::Broadcasted)
  f = bc.f
  ax = axes(bc)
  args = promote_shape(ax, bc.args...)
  return Mapped(bc.style, f, args, ax)
end

function Broadcast.Broadcasted(m::Mapped)
  return Broadcasted(m.style, m.f, m.args, m.axes)
end

function mapped(f, args...)
  check_shape(args...)
  return Mapped(broadcasted(f, args...))
end

Base.similar(m::Mapped, elt::Type) = similar(Broadcasted(m), elt)
Base.similar(m::Mapped, elt::Type, ax) = similar(Broadcasted(m), elt, ax)
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
