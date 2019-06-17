import Base: +, *, -, /, %, intersect, minimum, maximum, size, getindex

export Vec3, rgb, clip01

# -------- #
# Vector 3 #
# -------- #

"""
This is the central type for RayTracer. All of the other types are defined building
upon this.                                                      

All the fields of the Vec3 instance contains `Array`s. This ensures that we can collect
the gradients w.r.t the fields using the `Params` API of Zygote.

### Defined Operations for Vec3:

* `+`, `-`, `*` -- These operations will be broadcasted even though there is no explicit
                   mention of broadcasting.
* `dot`, `l2norm`
* `cross`
* `clamp`, `clip01`
* `zero`, `similar`, `one`
* `place`
* `maximum`, `minimum`
* `size`
"""
mutable struct Vec3{T<:AbstractArray}
    x::T
    y::T
    z::T
    function Vec3(x::T, y::T, z::T) where {T<:AbstractArray}
        @assert size(x) == size(y) == size(z)
        new{T}(x, y, z)
    end
    function Vec3(x::T1, y::T2, z::T3) where {T1<:AbstractArray, T2<:AbstractArray, T3<:AbstractArray}
        # Yes, I know it is a terrible hack but Zygote.FillArray was pissing me off.
        T = eltype(x) <: Real ? eltype(x) : eltype(y) <: Real ? eltype(y) : eltype(z)
        @warn "Converting the type to $(T) by default" maxlog=1
        @assert size(x) == size(y) == size(z)
        new{AbstractArray{T, ndims(x)}}(T.(x), T.(y), T.(z))
    end
end    

Vec3(a::T) where {T<:Real} = Vec3([a], [a], [a])

Vec3(a::T) where {T<:AbstractArray} = Vec3(copy(a), copy(a), copy(a))

Vec3(a::T, b::T, c::T) where {T<:Real} = Vec3([a], [b], [c])

function show(io::IO, v::Vec3)
    l = size(v)[1]
    if l == 1
        print(io, "x = ", v.x[], ", y = ", v.y[], ", z = ", v.z[])
    elseif l <= 5
        print(io, "Vec3 Object\n    Length = ", l, "\n    x = ", v.x,
              "\n    y = ", v.y, "\n    z = ", v.z)
    else
        print(io, "Vec3 Object\n    Length = ", l, "\n    x = ", v.x[1:5],
              "...\n    y = ", v.y[1:5], "...\n    z = ", v.z[1:5], "...")
    end
end

for op in (:+, :*, :-)
    @eval begin
        @inline function $(op)(a::Vec3, b::Vec3)
            return Vec3(broadcast($(op), a.x, b.x),
                        broadcast($(op), a.y, b.y),
                        broadcast($(op), a.z, b.z)) 
        end
    end
end

for op in (:+, :*, :-, :/, :%)
    @eval begin
        @inline function $(op)(a::Vec3, b)
            return Vec3(broadcast($(op), a.x, b),
                        broadcast($(op), a.y, b),
                        broadcast($(op), a.z, b))
        end
        
        @inline function $(op)(b, a::Vec3)
            return Vec3(broadcast($(op), a.x, b),
                        broadcast($(op), a.y, b),
                        broadcast($(op), a.z, b))
        end
    end
end

@inline -(a::Vec3) = Vec3(-a.x, -a.y, -a.z)

@inline dot(a::Vec3, b::Vec3) = a.x .* b.x .+ a.y .* b.y .+ a.z .* b.z

@inline l2norm(a::Vec3) = dot(a, a)

@inline function normalize(a::Vec3)
    l2 = l2norm(a)
    l2 = map(x -> x == 0 ? typeof(x)(1) : x, l2)
    return (a / sqrt.(l2))
end

@inline cross(a::Vec3{T}, b::Vec3{T}) where {T} =
    Vec3(a.y .* b.z .- a.z .* b.y, a.z .* b.x .- a.x .* b.z,
         a.x .* b.y .- a.y .* b.x)

@inline maximum(v::Vec3) = max(maximum(v.x), maximum(v.y), maximum(v.z))

@inline minimum(v::Vec3) = min(minimum(v.x), minimum(v.y), minimum(v.z))

@inline clip01(v::Vec3) = (v - minimum(v)) / maximum(v)

@inline size(v::Vec3) = size(v.x)

@inline getindex(v::Vec3, idx) = (x = v.x[idx], y = v.y[idx], z = v.z[idx])

"""
    place(a::Vec3, cond)

Constructs a new `Vec3` with array length equal to that of `cond` filled with zeros.
Then it fills the positions corresponding to the `true` values of `cond` with the values
in `a`.

The length of each array in `a` must be equal to the number of `true` values in the 
`cond` array.
"""
function place(a::Vec3, cond)
    r = Vec3(zeros(eltype(a.x), size(cond)...),
             zeros(eltype(a.y), size(cond)...),
             zeros(eltype(a.z), size(cond)...))
    r.x[cond] .= a.x
    r.y[cond] .= a.y
    r.z[cond] .= a.z
    return r
end

Base.clamp(v::Vec3, lo, hi) = Vec3(clamp.(v.x, lo, hi), clamp.(v.y, lo, hi), clamp.(v.z, lo, hi))

for f in (:zero, :similar, :one)
    @eval begin
        Base.$(f)(v::Vec3) = Vec3($(f)(v.x), $(f)(v.y), $(f)(v.z))
    end
end


# ----- #
# Color #
# ----- #

"""
`rgb` is an alias for `Vec3`. It makes more sense to use this while defining colors. 
"""
rgb = Vec3

# ----- #
# Utils #
# ----- #

"""
    extract(cond, x<:Number)
    extract(cond, x<:AbstractArray)
    extract(cond, x::Vec3)

Extracts the elements of `x` (in case it is an array) for which the indices corresponding to the `cond`
are `true`.

!!! note
    `extract` has a performance penalty when used on GPUs.

### Example:

```julia
julia> a = rand(4)
4-element Array{Float64,1}:
 0.7201598586590607 
 0.5829718552672327 
 0.1177531256556108 
 0.3083157590071375 

julia> cond = a .> 0.5
4-element BitArray{1}:
  true
  true
 false
 false

julia> RayTracer.extract(cond, a)
2-element Array{Float64,1}:
 0.7201598586590607
 0.5829718552672327
```
"""
@inline extract(cond, x::T) where {T<:Number} = x

@inline extract(cond, x::T) where {T<:AbstractArray} = x[cond]

extract(cond, a::Vec3) = length(a.x) == 1 ? Vec3(a.x, a.y, a.z) : Vec3(extract(cond, a.x),
                                                                       extract(cond, a.y),
                                                                       extract(cond, a.z))

"""
    bigmul(x)

Returns the output same as `typemax`. However, in case gradients are computed, it will return
the gradient to be `0` instead of `nothing` as in case of typemax.
"""
@inline bigmul(x) = typemax(x)

# ----------------- #
# - Helper Macros - #
# ----------------- #

"""
    @diffops MyType::DataType

Generates functions for performing gradient based optimizations on this custom type.
5 functions are generated.

1. `x::MyType + y::MyType` -- For Gradient Accumulation
2. `x::MyType - y::MyType` -- For Gradient Based Updates
3. `x::MyType * η<:Real  ` -- For Multiplication of the Learning Rate with Gradient
4. `η<:Real   * x::MyType` -- For Multiplication of the Learning Rate with Gradient
5. `x::MyType * y::MyType` -- Just for the sake of completeness.

Most of these functions do not make semantic sense. For example, adding 2 `PointLight`
instances do not make sense but in case both of them are gradients, it makes perfect
sense to accumulate them in a third `PointLight` instance.
"""
macro diffops(a)
    quote
        # Addition for gradient accumulation
        function $(esc(:+))(x::$(esc(a)), y::$(esc(a)))
            return $(esc(a))([getfield(x, i) + getfield(y, i) for i in fieldnames($(esc(a)))]...)
        end
        # Subtraction for gradient updates
        function $(esc(:-))(x::$(esc(a)), y::$(esc(a)))
            return $(esc(a))([getfield(x, i) - getfield(y, i) for i in fieldnames($(esc(a)))]...)
        end
        # Multiply for learning rate and misc ops
        function $(esc(:*))(x::T, y::$(esc(a))) where {T<:Real}
            return $(esc(a))([x * getfield(y, i) for i in fieldnames($(esc(a)))]...)
        end
        function $(esc(:*))(x::$(esc(a)), y::T) where {T<:Real}
            return $(esc(a))([getfield(x, i) * y for i in fieldnames($(esc(a)))]...)
        end
        function $(esc(:*))(x::$(esc(a)), y::$(esc(a)))
            return $(esc(a))([getfield(x, i) * getfield(y, i) for i in fieldnames($(esc(a)))]...)
        end
    end
end

# ---------------- #
# Fixed Parameters #
# ---------------- #

"""
    FixedParams

Any subtype of FixedParams is not optimized using the `update!` API. For example,
we don't want the screen size to be altered while inverse rendering, this is
ensured by wrapping those parameters in a subtype of FixedParams.
"""
abstract type FixedParams; end

for op in (:+, :*, :-, :/, :%)
    @eval begin
        @inline $(op)(a::FixedParams, b::FixedParams) = a

        @inline $(op)(a::FixedParams, b) = a

        @inline $(op)(a, b::FixedParams) = b
    end
end

