# Imports
import Base: +, *, -, /, %, intersect

# Vector 3

struct Vec3{T}
    x::T
    y::T
    z::T
end    

Vec3(a) = Vec3(a, a, a)

Vec3(a::T) where {T<:AbstractArray} = Vec3(copy(a), copy(a), copy(a))

for op in (:+, :*, :-)
    @eval begin
        function $(op)(a::Vec3, b::Vec3)
            return Vec3(broadcast($(op), a.x, b.x),
                        broadcast($(op), a.y, b.y),
                        broadcast($(op), a.z, b.z)) 
        end
    end
end

for op in (:+, :*, :-, :/, :%)
    @eval begin
        function $(op)(a::Vec3, b)
            return Vec3(broadcast($(op), a.x, b),
                        broadcast($(op), a.y, b),
                        broadcast($(op), a.z, b))
        end
        
        function $(op)(b, a::Vec3)
            return Vec3(broadcast($(op), a.x, b),
                        broadcast($(op), a.y, b),
                        broadcast($(op), a.z, b))
        end
    end
end

-(a::Vec3) = Vec3(-a.x, -a.y, -a.z)

dot(a::Vec3, b::Vec3) =
    a.x .* b.x .+ a.y .* b.y .+ a.z .* b.z

l2norm(a::Vec3) = dot(a, a)

normalize(a::Vec3) = a / sqrt.(l2norm(a))

cross(a::Vec3, b::Vec3) =
    Vec3(a.y .* b.z .- a.z .* b.y, a.z .* b.x .- a.x .* b.z,
         a.x .* b.y .- a.y .* b.x)

function place(a::Vec3, cond)
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

extract(cond, a::Vec3) =
    Vec3(a.x[cond], a.y[cond], a.z[cond])

extract(cond, a::Vec3{T}) where {T<:Number} =
    Vec3(a.x, a.y, a.z)

bigmul(x::T) where {T} = typemax(x)
