export Disc

# -------- #
# - Disc - #
# -------- #

struct Disc{V, P, Q, R, S, T, U} <: Object
    center::Vec3{V}
    normal::Vec3{V} # This needs to be normalized everytime before usage
    radius::V
    material::Material{P, Q, R, S, T, U}
end

show(io::IO, d::Disc) =
    print(io, "Disc Object:\n    Center - ", d.center, "\n    Normal - ", d.normal,
          "\n    Radius - ", d.radius[], "\n    ", d.material)

@diffops Disc

function intersect(d::Disc, origin, direction)
    normal = normalize(d.normal)
    dot_dn = dot(direction, normal)
    p_org = d.center - origin
    t = dot(p_org, normal) ./ dot_dn
    pt = origin + direction * t
    dist = l2norm(pt - d.center)
    r2 = d.radius[] ^ 2
    function get_intersection(t₀, dst)
        t_ = t₀
        if t₀ < 0 || dst > r2
            t_ = bigmul(t₀ + dst + r2)
        end
        return t_
    end
    result = broadcast(get_intersection, t, dist)
    return result
end

function get_normal(d::Disc, pt, dir)
    normal = normalize(d.normal)
    direction = -sign.(dot(normal, dir))
    normal_uni = Vec3(repeat(normal.x, inner = size(pt.x)),
                      repeat(normal.y, inner = size(pt.y)),
                      repeat(normal.z, inner = size(pt.z)))
    return normal_uni * direction
end
