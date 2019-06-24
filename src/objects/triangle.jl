export Triangle

# ------------ #
# - Triangle - #
# ------------ #

struct Triangle{V, P, Q, R, S, T, U} <: Object
    v1::Vec3{V}
    v2::Vec3{V}
    v3::Vec3{V}
    material::Material{P, Q, R, S, T, U}
end

show(io::IO, t::Triangle) =
    print(io, "Triangle Object:\n    Vertex 1 - ", t.v1, "\n    Vertex 2 - ", t.v2,
          "\n    Vertex 3 - ", t.v3, "\n    ", t.material)

@diffops Triangle

function intersect(t::Triangle, origin, direction)
    normal = normalize(cross(t.v2 - t.v1, t.v3 - t.v1))
    h = (-dot(normal, origin) .+ dot(normal, t.v1)) ./ dot(normal, direction)
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
