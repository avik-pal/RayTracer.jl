export numderiv

# --------------------- #
# Numerical Derivatives #
# --------------------- #

# The arguments to `f` must be of type Float64.
# For Float32, the gradients are too unstable to give any meaningful result.
function ngradient(f, xs::AbstractArray...)
    grads = zero.(xs)
    for (x, Δ) in zip(xs, grads), i in 1:length(x)
        # This gives reasonable results
        δ = 5.0e-3
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

get_params(x::T) where {T<:AbstractArray} = x

get_params(x::T) where {T<:Real} = [x]

get_params(x::T) where {T} = foldl((a, b) -> [a; b],
                                   [map(i -> get_params(getfield(x, i)), fieldnames(T))...])

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

# NOTE: This is not a generalized method for getting the gradients.
#       For that please use Zygote. However, this can be used to
#       debug you model, incase you feel the gradients obtained by
#       other methods is sketchy.
numderiv(f, θ::AbstractArray) = ngradient(f, θ)

numderiv(f, θ::Real) = ngradient(f, [θ])

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

