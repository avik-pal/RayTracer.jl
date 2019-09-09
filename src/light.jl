export PointLight, DistantLight

# ----- #
# Light #
# ----- #

"""
    Light

All objects emitting light should be a subtype of this. To add a custom light
source, two only two functions need to be defined.

* `get_direction(l::MyCustomLightSource, pt::Vec3)` - `pt` is the point receiving the
                                                      light from this source
* `get_intensity(l::MyCustomLightSource, pt::Vec3, dist::Array)` - `dist` is the array
                                                                   representing the distance
                                                                   of the point from the light
                                                                   source
"""
abstract type Light end

"""
    get_shading_info(l::Light, pt::Vec3)

Returns the `direction` of light incident from the light source onto that
Point and the intensity of that light ray. It computes these by internally
calling the `get_direction` and `get_intensity` functions and hence this
function never has to be modified for any `Light` subtype.

### Arguments:

* `l`  - The Object of the [`Light`](@ref) subtype
* `pt` - The Point in 3D Space for which the shading information is queried
"""
function get_shading_info(l::Light, pt::Vec3)
    dir = get_direction(l, pt)
    dist = sqrt.(l2norm(dir))
    intensity = get_intensity(l, pt, dist)
    return normalize(dir), intensity
end

"""
    get_direction(l::Light, pt::Vec3)

Returns the direction of light incident from the light source to `pt`.
"""
function get_direction(l::Light, pt::Vec3) end

"""
    get_intensity(l::Light, pt::Vec3, dist::Array)

Computed the intensity of the light ray incident at `pt`.
"""
function get_intensity(l::Light, pt::Vec3, dist::AbstractArray) end

# --------------- #
# - Point Light - #
# --------------- #

"""
    PointLight

A source of light which emits light rays from a point in 3D space. The
intensity for this light source diminishes as inverse square of the distance
from the point.

### Fields:

* `color`     - Color of the Light Rays emitted from the source.
* `intensity` - Intensity of the Light Source. This decreases as ``\\frac{1}{r^2}``
                where ``r`` is the distance of the point from the light source.
* `position`  - Location of the light source in 3D world space.

### Available Constructors:

* `PointLight(;color = Vec3(1.0f0), intensity::Real = 100.0f0, position = Vec3(0.0f0))`
* `PointLight(color, intensity::Real, position)`
"""
struct PointLight{T<:AbstractArray} <: Light
    color::Vec3{T}
    intensity::T
    position::Vec3{T}
end

PointLight(;color = Vec3(1.0f0), intensity::Real = 100.0f0, position = Vec3(0.0f0)) =
    PointLight(color, intensity, position)
    
PointLight(c, i::Real, p) = PointLight(clamp(c, 0.0f0, 1.0f0), [i], p)

show(io::IO, pl::PointLight) =
    print(io, "Point Light\n    Color - ", pl.color, "\n    Intensity - ",
          pl.intensity[], "\n    Position - ", pl.position)

@diffops PointLight

get_direction(p::PointLight, pt::Vec3) = p.position - pt

get_intensity(p::PointLight, pt::Vec3, dist::AbstractArray) =
    p.intensity[] * p.color / (4 .* (eltype(p.color.x))(π) .* (dist .^ 2))    

# ----------------- #
# - Distant Light - #
# ----------------- #

"""
    DistantLight

A source of light that is present at infinity as such the rays from it are
in a constant direction. The intensity for this light source always remains
constant. This is extremely useful when we are trying to render a large scene
like a city.

### Fields:

* `color`     - Color of the Light Rays emitted from the Source.
* `intensity` - Intensity of the Light Source.
* `direction` - Direction of the Light Rays emitted by the Source.

### Available Constructors:

* `DistantLight(;color = Vec3(1.0f0), intensity::Real = 1.0f0,
                 direction = Vec3(0.0f0, 1.0f0, 0.0f0))`
* `DistantLight(color, intensity::Real, direction)`
"""
struct DistantLight{T<:AbstractArray} <: Light
    color::Vec3{T}
    intensity::T
    direction::Vec3{T}  # Must be normalized
end

DistantLight(;color = Vec3(1.0f0), intensity::Real = 1.0f0,
              direction = Vec3(0.0f0, 1.0f0, 0.0f0)) =
    DistantLight(color, intensity, direction)

DistantLight(c, i::Real, d) = DistantLight(clamp(c, 0.0f0, 1.0f0), [i], normalize(d))

show(io::IO, dl::DistantLight) =
    print(io, "Distant Light\n    Color - ", dl.color, "\n    Intensity - ",
          dl.intensity[], "\n    Direction - ", dl.direction)

@diffops DistantLight

get_direction(d::DistantLight, pt::Vec3) = d.direction

get_intensity(d::DistantLight, pt::Vec3, dist::AbstractArray) = d.intensity[]

