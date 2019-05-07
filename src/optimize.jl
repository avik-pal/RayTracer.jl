import Flux.Optimise.apply!

# ---------- #
# Optimizers #
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
update!(opt, x::T, Δ::T) where {T<:AbstractArray} = x .- apply!(opt, x, Δ)

update!(opt, x::T, Δ::T) where {T<:Real} = x .- (apply!(opt, [x], [Δ]))[1]

function update!(opt, x::T, Δ::T) where {T}
    map(i -> setproperty!(x, i, update!(opt, getfield(x, i), getfield(Δ, i))), fieldnames(T))
    return x
end

