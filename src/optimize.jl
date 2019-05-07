# import Flux.Optimise.apply!

# ---------- #
# Optimisers #
# ---------- #

"""
    update!(opt, x, Δ)

NOTE: This API is currently broken. I shall fix it once the Flux Optimisers
are more Zygote friendly. Using this will allow you to use optimisers
that are defined in this package. These optimisers are not designed to
be efficient but are there as a proof of concept.

Provides an interface to use all of the Optimizers provided by Flux.
The type of `x` can be anything as long as the operations defined by
`@diffops` are available for it. By default all the differentiable
types inside the Package can be used with it.

The type of `Δ` must be same as that of `x`. This prevent silent
type conversion of `x` which can significantly slow doen the raytracer.

Example:

```julia
opt = ADAM()

gs = gradient(loss_function, θ)

update!(opt, θ, gs[1])
```
"""
update!(opt, x::T, Δ::T) where {T<:AbstractArray} = x .- apply!(opt, x, Δ)

update!(opt, x::T, Δ::T) where {T<:Real} = x .- (apply!(opt, [x], [Δ]))[1]

# This makes sure we donot end up optimizing the value of the material.
# We cannot do this update in a stable manner for now. So it is wise
# to just avoid it for now.
update!(opt, x::Material, Δ::Material) = x

function update!(opt, x::T, Δ::T) where {T}
    map(i -> setproperty!(x, i, update!(opt, getfield(x, i), getfield(Δ, i))), fieldnames(T))
    return x
end


# -------- #
# - Adam - #
# -------- #

export Adam

const ϵ = 1e-8

mutable struct Adam
    η::Float64
    β::Tuple{Float64, Float64}
    state::IdDict
end

Adam(η = 0.001, β = (0.9, 0.999)) = Adam(η, β, IdDict())

function apply!(o::Adam, x, Δ)
    η, β = o.η, o.β
    # NOTE: Using length(x) for storing current state is a terrible thing to do.
    #       Let's hope not a lot of things will be broken when using this with
    #       Flux
    mt, vt, βp = get!(o.state, length(x), (zero(x), zero(x), β))
    @. mt = β[1] * mt + (1 - β[1]) * Δ
    @. vt = β[2] * vt + (1 - β[2]) * Δ^2
    @. Δ =  mt / (1 - βp[1]) / (√(vt / (1 - βp[2])) + ϵ) * η
    o.state[length(x)] = (mt, vt, βp .* β)
    return Δ
end

