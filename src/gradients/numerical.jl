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
        # This gives reasonable results
        δ = 1.0e-12
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
"""
get_params(x::T) where {T<:AbstractArray} = x

get_params(x::T) where {T<:Real} = [x]

get_params(x::T) where {T} = foldl((a, b) -> [a; b],
                                   [map(i -> get_params(getfield(x, i)), fieldnames(T))...])
                     
"""
    set_params!(x, y::AbstractArray)

Sets the tunable parameters of the struct `x`. The index of the last element
set into the struct is returned as output. This may be used to confirm that
the size of the input array was as expected.

### Example

```julia
julia> scene = Triangle(Vec3(-1.9, 1.3, 0.1), Vec3(1.2, 1.1, 0.3), Vec3(0.8, -1.2, -0.15),
                    color = rgb(1.0, 1.0, 1.0), reflection = 0.5)
Triangle{Array{Float64,1}}(Vec3{Array{Float64,1}}([-1.9], [1.3], [0.1]), Vec3{Array{Float64,1}}([1.2], [1.1], [0.3]), Vec3{Array{Float64,1}}([0.8], [-1.2], [-0.15]), RayTracer.Material{RayTracer.PlainColor,Float64}(RayTracer.PlainColor(Vec3{Array{Float64,1}}([1.0], [1.0], [1.0])), 0.5))

julia> x = rand(13)
13-element Array{Float64,1}:
 0.39019817669623835
 0.940810689314205
 .
 .
 .
 0.5590307650917048
 0.7551647340674075

julia> RayTracer.set_params!(scene, x)
13
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

