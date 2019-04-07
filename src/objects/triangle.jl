# ------------ #
# - Triangle - #
# ------------ #

# TODO: Use barycentric coordinates and Moller-Trumbore Algorithm
struct Triangle{V} <: Object
    v1::Vec3{V}
    v2::Vec3{V}
    v3::Vec3{V}
# NOTE: We only support double sided. Here is the defination of single and double sided
# http://www.scratchapixel.com/lessons/3d-basic-rendering/ray-tracing-rendering-a-triangle/single-vs-double-sided-triangle-backface-culling
    normal::Vec3{V}
    material::Material
end 

t1::Triangle + t2::Triangle = Triangle(t1.v1 + t2.v1,
                                       t1.v2 + t2.v2,
                                       t1.v3 + t2.v3,
                                       t1.normal + t2.normal,
                                       t1.material + t2.material)

# The next 2 functions are just convenience functions for handling
# gradients properly for getproperty function
function Triangle(v::Vec3{T}, sym::Symbol) where {T}
    z = eltype(T)(0)
    mat = Material(PlainColor(rgb(z)), z)
    if sym == :v1
        return Triangle(v, Vec3(z), Vec3(z), Vec3(z), mat)
    elseif sym == :v2
        return Triangle(Vec3(z), v, Vec3(z), Vec3(z), mat)
    elseif sym == :v3
        return Triangle(Vec3(z), Vec3(z), v, Vec3(z), mat)
    else # :normal
        return Triangle(Vec3(z), Vec3(z), Vec3(z), v, mat)
    end
end

# Symbol argument not needed but helps in writing the adjoint code
function Triangle(mat::Material{S, R}, ::Symbol) where {S, R}
    z = R(0)
    return Cylinder(Vec3(z), Vec3(z), Vec3(z), Vec3(z), mat)
end

function Triangle(v1::Vec3, v2::Vec3, v3::Vec3; color = rgb(0.5f0), reflection = 0.5f0)
    mat = Material(PlainColor(color), reflection)
    normal = normalize(cross(v2 - v1, v3 - v1)) 
    return Triangle(v1, v2, v3, normal, mat)
end

function intersect(t::Triangle, origin, direction)
    h = - (dot(t.normal, origin) .+ dot(t.normal, t.v1)) ./ dot(t.normal, direction)
    pt = origin + direction * h
    edge1 = t.v2 - t.v1
    edge2 = t.v3 - t.v2
    edge3 = t.v1 - t.v3
    c₁ = pt - t.v1
    c₂ = pt - t.v2
    c₃ = pt - t.v3
    val1 = dot(t.normal, cross(edge1, c₁))
    val2 = dot(t.normal, cross(edge2, c₂))
    val3 = dot(t.normal, cross(edge3, c₃))
    get_intersections(a, b, c, d) =
        (a > 0 && b > 0 && c > 0 && d > 0) ? a : bigmul(a + b + c + d)
    result = broadcast(get_intersections, h, val1, val2, val3)
    return result
end

function get_normal(t::Triangle, pt)
    normal = Vec3(fill(t.normal.x, size(pt.x)),
                  fill(t.normal.y, size(pt.y)),
                  fill(t.normal.z, size(pt.z)))
    return normal
end