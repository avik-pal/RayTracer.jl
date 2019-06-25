export numderiv

# --------------------- #
# Numerical Derivatives #
# --------------------- #

"""
    ngradient(f, xs::AbstractArray...)

Computes the numerical gradients of `f` w.r.t `xs`. The function `f` must return
a scalar value for this to work. This function is not meant for general usage as
the value of the parameter `δ` has been tuned for this package specifically.

Also, it should be noted that these gradients are highly unstable and should be
used only for confirming the values obtained through other methods. For meaningful
results be sure to use `Float64` as `Float32` is too numerically unstable.
"""
function ngradient(f, xs::AbstractArray...)
    grads = zero.(xs)
    for (x, Δ) in zip(xs, grads), i in 1:length(x)
        δ = 1.0e-11
        tmp = x[i]
        x[i] = tmp - δ/2
        y1 = f(xs...)
        x[i] = tmp + δ/2
        y2 = f(xs...)
        x[i] = tmp
        Δ[i] = (y2 - y1)/δ
    end
    return grads
end

# ---------- #
# Parameters #
# ---------- #

"""
    get_params(x)

Get the parameters from a struct that can be tuned. The output is in
the form of an array.

### Example:

```jldoctest
julia> using RayTracer;

julia> scene = Triangle(Vec3(-1.9f0, 1.6f0, 1.0f0), Vec3(1.0f0, 1.0f0, 0.0f0), Vec3(-0.5f0, -1.0f0, 0.0f0),
                        Material())
Triangle Object:
    Vertex 1 - x = -1.9, y = 1.6, z = 1.0
    Vertex 2 - x = 1.0, y = 1.0, z = 0.0
    Vertex 3 - x = -0.5, y = -1.0, z = 0.0
    Material{Array{Float32,1},Array{Float32,1},Nothing,Nothing,Nothing,Nothing}(x = 1.0, y = 1.0, z = 1.0, x = 1.0, y = 1.0, z = 1.0, x = 1.0, y = 1.0, z = 1.0, Float32[50.0], Float32[0.5], nothing, nothing, nothing, nothing)

julia> RayTracer.get_params(scene)
20-element Array{Float32,1}:
 -1.9
  1.6
  1.0
  1.0
  1.0
  0.0
 -0.5
 -1.0
  0.0
  1.0
  1.0
  1.0
  1.0
  1.0
  1.0
  1.0
  1.0
  1.0
 50.0
  0.5
```
"""
get_params(x::T, typehelp = Float32) where {T<:AbstractArray} = x

get_params(x::T, typehelp = Float32) where {T<:Real} = [x]

get_params(::Nothing, typehelp = Float32) = typehelp[]

get_params(x::T, typehelp = Float32) where {T} =
    foldl((a, b) -> [a; b], [map(i -> get_params(getfield(x, i), typehelp),
                                 fieldnames(T))...])
                     
"""
    set_params!(x, y::AbstractArray)

Sets the tunable parameters of the struct `x`. The index of the last element
set into the struct is returned as output. This may be used to confirm that
the size of the input array was as expected.

### Example:

```jldoctest
julia> using RayTracer;

julia> scene = Triangle(Vec3(-1.9f0, 1.6f0, 1.0f0), Vec3(1.0f0, 1.0f0, 0.0f0), Vec3(-0.5f0, -1.0f0, 0.0f0),
                        Material())
Triangle Object:
    Vertex 1 - x = -1.9, y = 1.6, z = 1.0
    Vertex 2 - x = 1.0, y = 1.0, z = 0.0
    Vertex 3 - x = -0.5, y = -1.0, z = 0.0
    Material{Array{Float32,1},Array{Float32,1},Nothing,Nothing,Nothing,Nothing}(x = 1.0, y = 1.0, z = 1.0, x = 1.0, y = 1.0, z = 1.0, x = 1.0, y = 1.0, z = 1.0, Float32[50.0], Float32[0.5], nothing, nothing, nothing, nothing)

julia> new_params = collect(1.0f0:20.0f0)
20-element Array{Float32,1}:
  1.0
  2.0
  3.0
  4.0
  5.0
  6.0
  7.0
  8.0
  9.0
 10.0
 11.0
 12.0
 13.0
 14.0
 15.0
 16.0
 17.0
 18.0
 19.0
 20.0

julia> RayTracer.set_params!(scene, new_params);

julia> scene
Triangle Object:
    Vertex 1 - x = 1.0, y = 2.0, z = 3.0
    Vertex 2 - x = 4.0, y = 5.0, z = 6.0
    Vertex 3 - x = 7.0, y = 8.0, z = 9.0
    Material{Array{Float32,1},Array{Float32,1},Nothing,Nothing,Nothing,Nothing}(x = 10.0, y = 11.0, z = 12.0, x = 13.0, y = 14.0, z = 15.0, x = 16.0, y = 17.0, z = 18.0, Float32[19.0], Float32[20.0], nothing, nothing, nothing, nothing)
```
"""
function set_params!(x::AbstractArray, y::AbstractArray)
    l = length(x)
    x .= y[1:l]
    return l
end

# FIXME: This update strategy fails for real parameters. Will need to deal with
#        this later. But currently I am not much concered about these parameters.
set_params!(x::T, y::AbstractArray) where {T<:Real} = set_params!([x], y)

function set_params!(x, y::AbstractArray)
    start = 1
    for i in 1:nfields(x)
        isnothing(getfield(x, i)) && continue
        start += set_params!(getfield(x, i), y[start:end])
    end
    return start - 1
end

# ------------------------- #
# Numerical Differentiation #
# ------------------------- #
"""
    numderiv(f, θ)
    numderiv(f, θ::AbstractArray)
    numderiv(f, θ::Real)

Compute the numerical derivates wrt one of the scene parameters.
The parameter passed cannot be enclosed in an Array, thus making
this not a general method for differentiation.

!!! note
    This is not a generalized method for getting the gradients.
    For that please use Zygote. However, this can be used to
    debug you model, incase you feel the gradients obtained by
    other methods is sketchy.
"""
function numderiv(f, θ)
    arr = get_params(θ)
    function modified_f(x::AbstractArray)
        θ₂ = deepcopy(θ)
        set_params!(θ₂, x)
        return f(θ₂)
    end
    grads = ngradient(modified_f, arr)[1]
    grad_θ = deepcopy(θ)
    set_params!(grad_θ, grads)
    return grad_θ
end

numderiv(f, θ::AbstractArray) = ngradient(f, θ)

numderiv(f, θ::Real) = ngradient(f, [θ])

