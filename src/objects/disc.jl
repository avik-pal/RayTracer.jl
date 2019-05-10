import Base.setproperty!

export Disc

# -------- #
# - Disc - #
# -------- #

mutable struct Disc{V,T<:Real} <: Object
    center::Vec3{V}
    normal::Vec3{V} # This needs to be normalized everytime before usage
    radius::T
    material::Material
end 

@diffops Disc

# The next 3 functions are just convenience functions for handling
# gradients properly for getproperty function
function Disc(v::Vec3{T}, sym::Symbol) where {T}
    z = eltype(T)(0)
    mat = Material(PlainColor(rgb(z)), z)
    if sym == :center
        return Disc(v, Vec3(z), z, mat)
    else
        return Disc(Vec3(z), v, z, mat)
    end
end

function Disc(r::T, ::Symbol) where {T<:Real}
    z = T(0)
    mat = Material(PlainColor(rgb(z)), z)
    return Disc(Vec3(z), Vec3(z), r, mat)
end

function Disc(mat::Material{S, R}, ::Symbol) where {S, R}
    z = R(0)
    return Disc(Vec3(z), Vec3(z), z, mat)
end

function Disc(c::Vec3, n::Vec3, r::T; color = rgb(0.5f0), reflection = 0.5f0) where {T<:Real}
    mat = Material(PlainColor(color), reflection)
    n = normalize(n)
    return Disc(c, n, r, mat)
end

function intersect(d::Disc, origin, direction)
    normal = normalize(d.normal)
    dot_dn = dot(direction, normal)
    p_org = d.center - origin
    t = dot(p_org, normal) ./ dot_dn
    pt = origin + direction * t
    dist = l2norm(pt - d.center)
    r2 = d.radius ^ 2
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

function get_normal(d::Disc, pt)
    normal = normalize(d.normal)
    return Vec3(repeat(normal.x, inner = size(pt.x)),
                repeat(normal.y, inner = size(pt.y)),
                repeat(normal.z, inner = size(pt.z)))
end
