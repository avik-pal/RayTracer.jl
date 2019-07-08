export Sphere

# ---------- #
# - Sphere - #
# ---------- #

struct Sphere{C, P, Q, R, S, T, U} <: Object
    center::Vec3{C}
    radius::C
    material::Material{P, Q, R, S, T, U}
end

show(io::IO, s::Sphere) =
    print(io, "Sphere Object:\n    Center - ", s.center, "\n    Radius - ", s.radius[],
          "\n    ", s.material)

@diffops Sphere

function intersect(s::Sphere, origin, direction)
    b = dot(direction, origin - s.center)  # direction is a vec3 with array
    c = l2norm(s.center) .+ l2norm(origin) .- 2 .* dot(s.center, origin) .- (s.radius .^ 2)
    disc = (b .^ 2) .- c
    function get_intersections(x, y)
        t = bigmul(x + y) # Hack to split the 0.0 gradient to both. Otherwise one gets nothing
        if y > 0
            sqrty = sqrt(y)
            z1 = -x - sqrty 
            z2 = -x + sqrty
            if z1 <= 0 && z2 > 0
                t = z2
            elseif z1 > 0
                t = z1
            end
        end
        return t
    end
    result = broadcast(get_intersections, b, disc)
    return result
end

get_normal(s::Sphere, pt, dir) = normalize(pt - s.center)

