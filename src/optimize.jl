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

### Example:

```julia
julia> opt = ADAM()

julia> gs = gradient(loss_function, θ)

julia> update!(opt, θ, gs[1])
```
"""
function update!(opt, x::AbstractArray, Δ::AbstractArray)
    x .-= apply!(opt, x, Δ)
    return x
end

update!(opt, x::T, Δ::T) where {T<:Real} = (update!(opt, [x], [Δ]))[]

update!(opt, x::FixedParams, Δ::FixedParams) = x 

update!(opt, x, Δ::Nothing) = x

function update!(opt, x::T, Δ::T) where {T}
    map(i -> update!(opt, getfield(x, i), getfield(Δ, i)), fieldnames(T))
    return x
end

