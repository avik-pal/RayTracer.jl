import Flux.Optimise.apply!

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
