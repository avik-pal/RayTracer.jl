using Zygote: @adjoint

@adjoint dot(a::Vec3, b::Vec3) = dot(a, b), Δ -> (Δ * b, Δ * a)

# Hack to avoid nothing in the gradient due to typemax
@adjoint bigmul(x::T) where {T} = bigmul(x), Δ -> (zero(T),)
