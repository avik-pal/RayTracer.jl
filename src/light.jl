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

mutable struct PointLight{T<:AbstractArray} <: Light
    color::Vec3{T}
    intensity::T
    position::Vec3{T}
end
    
PointLight(c, i::I, p) where {I<:AbstractFloat} =
    PointLight(clamp(c, 0.0f0, 1.0f0), [i], p)

show(io::IO, pl::PointLight) =
    print(io, "Point Light\n    Color - ", pl.color, "\n    Intensity - ",
          pl.intensity[], "\n    Position - ", pl.position)

@diffops PointLight

get_direction(p::PointLight, pt::Vec3) = p.position - pt

get_intensity(p::PointLight, pt::Vec3, dist) =
    p.intensity[] * p.color / (4 .* (eltype(p.color.x))(π) .* (dist .^ 2))    

# ----------------- #
# - Distant Light - #
# ----------------- #

mutable struct DistantLight{T<:AbstractArray} <: Light
    color::Vec3{T}
    intensity::T
    direction::Vec3{T}  # Must be normalized
end
    
DistantLight(c, i::I, d) where {I<:AbstractFloat} =
    DistantLight(clamp(c, 0.0f0, 1.0f0), [i], normalize(d))

show(io::IO, dl::DistantLight) =
    print(io, "Distant Light\n    Color - ", dl.color, "\n    Intensity - ",
          dl.intensity[], "\n    Direction - ", dl.direction)

@diffops DistantLight

get_direction(d::DistantLight, pt::Vec3) = d.direction

get_intensity(d::DistantLight, pt::Vec3, dist) = d.intensity[]

