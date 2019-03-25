# Imports
import Base: +, *, -, /, %, abs, intersect

# Vector 3

Vec3(a) = (x = a, y = a, z = a)

Vec3(a::T, b::T, c::T) where {T} = (x = a, y = b, z = c)

for op in (:+, :*, :-)
    @eval begin
        function $(op)(a::NamedTuple{(:x, :y, :z)}, b::NamedTuple{(:x, :y, :z)})
            return Vec3(broadcast($(op), a.x, b.x),
                        broadcast($(op), a.y, b.y),
                        broadcast($(op), a.z, b.z)) 
        end
    end
end

for op in (:+, :*, :-, :/, :%)
    @eval begin
        function $(op)(a::NamedTuple{(:x, :y, :z)}, b)
            return Vec3(broadcast($(op), a.x, b),
                        broadcast($(op), a.y, b),
                        broadcast($(op), a.z, b))
        end
        
        function $(op)(b, a::NamedTuple{(:x, :y, :z)})
            return Vec3(broadcast($(op), a.x, b),
                        broadcast($(op), a.y, b),
                        broadcast($(op), a.z, b))
        end
    end
end

-(a::NamedTuple{(:x, :y, :z)}) = Vec3(-a.x, -a.y, -a.z)

dot(a::NamedTuple{(:x, :y, :z)}, b::NamedTuple{(:x, :y, :z)}) =
    a.x .* b.x .+ a.y .* b.y .+ a.z .* b.z

abs(a::NamedTuple{(:x, :y, :z)}) = dot(a, a)

norm(a::NamedTuple{(:x, :y, :z)}) = a / sqrt.(abs(a))

cross(a::NamedTuple{(:x, :y, :z)}, b::NamedTuple{(:x, :y, :z)}) =
    Vec3(a.y .* b.z .- a.z .* b.y, a.z .* b.x .- a.x .* b.z,
         a.x .* b.y .- a.y .* b.x)

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
