import Flux.Optimise.apply!

# ---------- #
# Optimizers #
# ---------- #

# NOTE: This function allows us to directly use all of Flux's Optimizers
function update!(opt, x::T, Δ::T) where {T}
    if T <: AbstractArray
        return x .- apply!(opt, x, Δ)
    elseif T <: Real
        return x .- (apply!(opt, [x], [Δ]))[1]
    else
        map(i -> setfield!(x, i, update!(opt, getfield(x, i), getfield(Δ, i))), fieldnames(T))
        return x
    end
end
