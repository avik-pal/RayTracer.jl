# ----- #
# Light #
# ----- #

abstract type Light end

function get_shading_info(l::L, pt) where {L<:Light}
    dir = get_direction(l, pt)
    dist = abs(dir)
    intensity = get_intensity(l, pt, dist)
    return dir, intensity
end

# --------------- #
# - Point Light - #
# --------------- #

struct PointLight{I<:AbstractFloat} <: Light
    color::NamedTuple{(:x, :y, :z)}
    intensity::I
    position::NamedTuple{(:x, :y, :z)}
end

get_direction(p::PointLight, pt::NamedTuple{(:x, :y, :z)}) =
    norm(p.position - pt)

get_intensity(p::PointLight, pt::NamedTuple{(:x, :y, :z)}, dist) =
    p.intensity * p.color / (4 .* typeof(p.color.x)(π) .* (dist .^ 2))    

# ----------------- #
# - Distant Light - #
# ----------------- #

struct DistantLight{I<:AbstractFloat} <: Light
    color::NamedTuple{(:x, :y, :z)}
    intensity::I
    position::NamedTuple{(:x, :y, :z)} 
    direction::NamedTuple{(:x, :y, :z)}  # Must be normalized
    DistantLight(c, i, p, d) = new(c, i, p, norm(d))
end

get_direction(d::DistantLight, pt::NamedTuple{(:x, :y, :z)}) =
    d.direction

get_intensity(d::DistantLight, pt::NamedTuple{(:x, :y, :z)}, dist) =
    d.intensity   

