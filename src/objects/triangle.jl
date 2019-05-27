export Triangle

# ------------ #
# - Triangle - #
# ------------ #

# TODO: Use barycentric coordinates and Moller-Trumbore Algorithm
mutable struct Triangle{V} <: Object
    v1::Vec3{V}
    v2::Vec3{V}
    v3::Vec3{V}
    material::Material
end 

@diffops Triangle

# The next 2 functions are just convenience functions for handling
# gradients properly for getproperty function
function Triangle(v::Vec3{T}, sym::Symbol) where {T}
    z = eltype(T)(0)
    mat = Material(PlainColor(rgb(z)), z)
    if sym == :v1
        return Triangle(v, Vec3(z), Vec3(z), mat)
    elseif sym == :v2
        return Triangle(Vec3(z), v, Vec3(z), mat)
    elseif sym == :v3
        return Triangle(Vec3(z), Vec3(z), v, mat)
    end
end

# Symbol argument not needed but helps in writing the adjoint code
function Triangle(mat::Material{S, R}, ::Symbol) where {S, R}
    z = R(0)
    return Triangle(Vec3(z), Vec3(z), Vec3(z), mat)
end

function Triangle(v1::Vec3, v2::Vec3, v3::Vec3; color = rgb(0.5f0), reflection = 0.5f0)
    mat = Material(PlainColor(color), reflection)
    return Triangle(v1, v2, v3, mat)
end

function intersect(t::Triangle, origin, direction)
    normal = normalize(cross(t.v2 - t.v1, t.v3 - t.v1))
    h = - (dot(normal, origin) .+ dot(normal, t.v1)) ./ dot(normal, direction)
    pt = origin + direction * h
    edge1 = t.v2 - t.v1
    edge2 = t.v3 - t.v2
    edge3 = t.v1 - t.v3
    c₁ = pt - t.v1
    c₂ = pt - t.v2
    c₃ = pt - t.v3
    val1 = dot(normal, cross(edge1, c₁))
    val2 = dot(normal, cross(edge2, c₂))
    val3 = dot(normal, cross(edge3, c₃))
    get_intersections(a, b, c, d) =
        (a > 0 && b > 0 && c > 0 && d > 0) ? a : bigmul(a + b + c + d)
    result = broadcast(get_intersections, h, val1, val2, val3)
    return result
end

function get_normal(t::Triangle, pt, dir)
    # normal not expanded
    normal_nexp = normalize(cross(t.v2 - t.v1, t.v3 - t.v1))
    direction = -sign.(dot(normal_nexp, dir))
    normal = Vec3(repeat(normal_nexp.x, inner = size(pt.x)),
                  repeat(normal_nexp.y, inner = size(pt.y)),
                  repeat(normal_nexp.z, inner = size(pt.z)))
    return normal * direction
end
