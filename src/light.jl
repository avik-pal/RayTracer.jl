# ----- #
# Light #
# ----- #

abstract type Light end

function get_shading_info(l::L, pt) where {L<:Light}
    dir = get_direction(l, pt)
    dist = l2norm(dir)
    intensity = get_intensity(l, pt, dist)
    return dir, intensity
end

# --------------- #
# - Point Light - #
# --------------- #

struct PointLight{I<:AbstractFloat} <: Light
    color::Vec3
    intensity::I
    position::Vec3
    PointLight(c, i, p) = new{typeof(i)}(clamp(c, 0.0f0, 1.0f0), i, p)
end

# Needed for gradient accumulation
p1::PointLight + p2::PointLight = PointLight(p1.color + p2.color,
                                             p1.intensity + p2.intensity,
                                             p1.position + p2.position)

get_direction(p::PointLight, pt::Vec3) = normalize(p.position - pt)

get_intensity(p::PointLight, pt::Vec3, dist) =
    p.intensity * p.color / (4 .* (eltype(p.color.x))(π) .* (dist .^ 2))    

# ----------------- #
# - Distant Light - #
# ----------------- #

struct DistantLight{I<:AbstractFloat} <: Light
    color::Vec3
    intensity::I
    position::Vec3 
    direction::Vec3  # Must be normalized
    DistantLight(c, i, p, d) = new{typeof(i)}(c, i, p, normalize(d))
end

get_direction(d::DistantLight, pt::Vec3) = d.direction

get_intensity(d::DistantLight, pt::Vec3, dist) = d.intensity   

