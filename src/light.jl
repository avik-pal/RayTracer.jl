export PointLight, DistantLight

# ----- #
# Light #
# ----- #

abstract type Light end

function get_shading_info(l::L, pt) where {L<:Light}
    dir = get_direction(l, pt)
    dist = sqrt.(l2norm(dir))
    intensity = get_intensity(l, pt, dist)
    return (dir / dist), intensity
end

# --------------- #
# - Point Light - #
# --------------- #

mutable struct PointLight{I<:AbstractFloat} <: Light
    color::Vec3
    intensity::I
    position::Vec3
    PointLight(c, i, p) = new{typeof(i)}(clamp(c, 0.0f0, 1.0f0), i, p)
end

@diffops PointLight

get_direction(p::PointLight, pt::Vec3) = p.position - pt

get_intensity(p::PointLight, pt::Vec3, dist) =
    p.intensity * p.color / (4 .* (eltype(p.color.x))(π) .* (dist .^ 2))    

# ----------------- #
# - Distant Light - #
# ----------------- #

mutable struct DistantLight{I<:AbstractFloat} <: Light
    color::Vec3
    intensity::I
    direction::Vec3  # Must be normalized
    DistantLight(c, i, d) = new{typeof(i)}(c, i, normalize(d))
end

@diffops DistantLight

get_direction(d::DistantLight, pt::Vec3) = d.direction

get_intensity(d::DistantLight, pt::Vec3, dist) = d.intensity

# -------------- #
# - Area Light - #
# -------------- #


