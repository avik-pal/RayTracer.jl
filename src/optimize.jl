import Flux.Optimise.apply!

export update!

# ---------- #
# Optimisers #
# ---------- #

"""
    update!(opt, x, Δ)

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
function update!(opt, x::AbstractArray, Δ::AbstractArray)
    x .-= apply!(opt, x, Δ)
    return x
end

update!(opt, x::T, Δ::T) where {T<:Real} = (update!(opt, [x], [Δ]))[1]

# This makes sure we donot end up optimizing the value of the material.
# We cannot do this update in a stable manner for now. So it is wise
# to just avoid it for now.
update!(opt, x::Material, Δ::Material) = x

update!(opt, x::SurfaceColor, Δ::SurfaceColor) = x

update!(opt, x::FixedParams, Δ::FixedParams) = x 

update!(opt, x, Δ::Nothing) = x

function update!(opt, x::T, Δ::T) where {T}
    map(i -> update!(opt, getfield(x, i), getfield(Δ, i)), fieldnames(T))
    return x
end

