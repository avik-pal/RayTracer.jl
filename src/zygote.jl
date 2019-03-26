using Zygote: @adjoint

@adjoint dot(a::NamedTuple{(:x, :y, :z)}, b::NamedTuple{(:x, :y, :z)}) =
    dot(a, b), Δ -> (Δ * b, Δ * a)

