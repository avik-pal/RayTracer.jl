# -------- #
# - Disc - #
# -------- #

# TODO: Use barycentric coordinates and Moller-Trumbore Algorithm
struct Disc{V,T<:Real} <: Object
    normal::Vec3{V}
    radius::T
    material::Material
end 

@diffops Disc

# The next 3 functions are just convenience functions for handling
# gradients properly for getproperty function
function Disc(v::Vec3{T}) where {T}
    z = eltype(T)(0)
    mat = Material(PlainColor(rgb(z)), z)
    return Disc(v, z, mat)
end

function Disc(r::T) where {T<:Real}
    z = T(0)
    mat = Material(PlainColor(rgb(z)), z)
    return Disc(Vec3(z), r, mat)
end

function Disc(mat::Material{S, R}) where {S, R}
    z = R(0)
    return Disc(Vec3(z), z, mat)
end

function Disc(n::Vec3, r::T; color = rgb(0.5f0), reflection = 0.5f0) where {T<:Real}
    mat = Material(PlainColor(color), reflection)
    n = normalize(n)
    return Disc(n, r, mat)
end

# function intersect(t::Triangle, origin, direction)
#     normal = normalize(cross(t.v2 - t.v1, t.v3 - t.v1))
#     h = - (dot(normal, origin) .+ dot(normal, t.v1)) ./ dot(normal, direction)
#     pt = origin + direction * h
#     edge1 = t.v2 - t.v1
#     edge2 = t.v3 - t.v2
#     edge3 = t.v1 - t.v3
#     c₁ = pt - t.v1
#     c₂ = pt - t.v2
#     c₃ = pt - t.v3
#     val1 = dot(normal, cross(edge1, c₁))
#     val2 = dot(normal, cross(edge2, c₂))
#     val3 = dot(normal, cross(edge3, c₃))
#     get_intersections(a, b, c, d) =
#         (a > 0 && b > 0 && c > 0 && d > 0) ? a : bigmul(a + b + c + d)
#     result = broadcast(get_intersections, h, val1, val2, val3)
#     return result
# end

function get_normal(t::Disc, pt, direction)
    normal_dir = dot(t.normal, direction)
    mult_factor = broadcast(x -> x < 0 ? one(typeof(x)) : -one(typeof(x)), normal_dir)
    normal = Vec3(repeat(t.normal.x, inner = size(pt.x)),
                  repeat(t.normal.y, inner = size(pt.y)),
                  repeat(t.normal.z, inner = size(pt.z)))
    return normal * mult_factor
end
