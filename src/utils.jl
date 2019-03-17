# Imports
import Base: +, *, -, /, %, abs, intersect

# Vector 3

Vec3(a) = (x = a, y = a, z = a)

Vec3(a::T, b::T, c::T) where {T} = (x = a, y = b, z = c)

+(a::NamedTuple{(:x, :y, :z)}, b::NamedTuple{(:x, :y, :z)}) =
    Vec3(a.x .+ b.x, a.y .+ b.y, a.z .+ b.z)

*(a::NamedTuple{(:x, :y, :z)}, b::NamedTuple{(:x, :y, :z)}) =
    Vec3(a.x .* b.x, a.y .* b.y, a.z .* b.z)

-(a::NamedTuple{(:x, :y, :z)}, b::NamedTuple{(:x, :y, :z)}) =
    Vec3(a.x .- b.x, a.y .- b.y, a.z .- b.z)

+(a::NamedTuple{(:x, :y, :z)}, b) = Vec3(a.x .+ b, a.y .+ b, a.z .+ b)

*(a::NamedTuple{(:x, :y, :z)}, b) = Vec3(a.x .* b, a.y .* b, a.z .* b)

-(a::NamedTuple{(:x, :y, :z)}, b) = Vec3(a.x .- b, a.y .- b, a.z .- b)

/(a::NamedTuple{(:x, :y, :z)}, b) = Vec3(a.x ./ b, a.y ./ b, a.z ./ b)

%(a::NamedTuple{(:x, :y, :z)}, b) = Vec3(a.x .% b, a.y .% b, a.z .% b)

dot(a::NamedTuple{(:x, :y, :z)}, b::NamedTuple{(:x, :y, :z)}) =
    a.x .* b.x .+ a.y .* b.y .+ a.z .* b.z

abs(a::NamedTuple{(:x, :y, :z)}) = dot(a, a)

norm(a::NamedTuple{(:x, :y, :z)}) = a / sqrt.(abs(a))

function place(a::NamedTuple{(:x, :y, :z)}, cond)
    r = Vec3(zeros(eltype(a.x), size(cond)...),
             zeros(eltype(a.y), size(cond)...),
             zeros(eltype(a.z), size(cond)...))
    r.x[cond] .= a.x
    r.y[cond] .= a.y
    r.z[cond] .= a.z
    return r
end

# Color

rgb = Vec3

# Utils

extract(cond, x::T) where {T<:Number} = x

extract(cond, x::T) where {T<:AbstractArray} = x[cond]

extract(cond, a::NamedTuple{(:x, :y, :z)}) =
    Vec3(a.x[cond], a.y[cond], a.z[cond])

extract(cond, a::NamedTuple{(:x, :y, :z), Tuple{T, T, T}}) where {T<:Number} =
    Vec3(a.x, a.y, a.z)
