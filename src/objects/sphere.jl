export Sphere, SimpleSphere, CheckeredSphere

# ---------- #
# - Sphere - #
# ---------- #

struct Sphere{C, S, R} <: Object
    center::Vec3{C}
    radius::C
    material::Material{S, R}
end

show(io::IO, s::Sphere) =
    print(io, "Sphere Object:\n    Center - ", s.center, "\n    Radius - ", s.radius[],
          "\n    ", s.material)

@diffops Sphere

# The next 3 functions are just convenience functions for handling
# gradients properly for getproperty function
function Sphere(center::Vec3{T}) where {T}
    z = eltype(T)(0)
    mat = Material(PlainColor(Vec3(z)), z)
    return Sphere(center, [z], mat)
end

function Sphere(radius::T) where {T<:AbstractArray}
    z = eltype(T)(0)
    mat = Material(PlainColor(Vec3(z)), z)
    return Sphere(Vec3(z), radius, mat)
end

function Sphere(mat::Material{S, R}) where {S, R}
    z = R(0)
    return Sphere(Vec3(z), [z], mat)
end

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

# ---------------------- #
# -- Helper Functions -- #
# ---------------------- #

function SimpleSphere(center, radius; color = Vec3(0.5f0), reflection = 0.5f0)
    mat = Material(PlainColor(color), reflection)
    return Sphere(center, [radius], mat)
end

function CheckeredSphere(center, radius; color1 = Vec3(0.1f0), color2 = Vec3(0.9f0),
                         reflection = 0.5f0)
    mat = Material(CheckeredSurface(color1, color2), reflection)
    return Sphere(center, [radius], mat)
end

