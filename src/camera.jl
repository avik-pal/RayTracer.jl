export Camera, get_primary_rays

# ------ #
# Camera #
# ------ #

"""
    FixedCameraParams

The Parameters of the [`Camera`](@ref) which should not be updated in inverse rendering
are wrapped into this object.

### Fields:

* `vup`    - Stores the World UP Vector (In most cases this is the Y-Axis Vec3(0.0, 1.0, 0.0))
* `width`  - Width of the image to be rendered
* `height` - Height of the image to be rendered
"""
struct FixedCameraParams{T} <: FixedParams
    vup::Vec3{T}
    width::Int
    height::Int
end

Base.show(io::IO, fcp::FixedCameraParams) =
    print(io, "    Fixed Parameters:\n        World UP - ", fcp.vup,
          "\n        Screen Dimensions - ", fcp.height, " × ", fcp.width)

Base.zero(fcp::FixedCameraParams) = FixedCameraParams(zero(fcp.vup), zero(fcp.width),
                                                      zero(fcp.height))

"""
    Camera

The Perspective View Camera Model

### Fields:

* `lookfrom`    - Position of the Camera in 3D World Space
* `lookat`      - Point in the 3D World Space where the Camera is Pointing
* `vfov`        - Field of View of the Camera
* `focus`       - The focal length of the Camera
* `fixedparams` - An instance of [`FixedCameraParams`](@ref)

### Available Constructors:

* `Camera(;lookfrom = Vec3(0.0f0), lookat = Vec3(0.0f0),
           vup = Vec3(0.0f0, 1.0f0, 0.0f0), vfov = 90.0f0,
           focus = 1.0f0, width = 128, height = 128)`
* `Camera(lookfrom::Vec3{T}, lookat::Vec3{T}, vup::Vec3{T}, vfov::R,
          focus::R, width::Int, height::Int) where {T<:AbstractArray, R<:Real}` 
"""
struct Camera{T}
    lookfrom::Vec3{T}
    lookat::Vec3{T}
    vfov::T
    focus::T
    fixedparams::FixedCameraParams{T}
end

Base.show(io::IO, cam::Camera) =
    print(io, "CAMERA Configuration:\n    Lookfrom - ", cam.lookfrom,
          "\n    Lookat - ", cam.lookat, "\n    Field of View - ", cam.vfov[],
          "\n    Focus - ", cam.focus[], "\n", cam.fixedparams)
                                       
@diffops Camera

Camera(;lookfrom = Vec3(0.0f0), lookat = Vec3(0.0f0),
        vup = Vec3(0.0f0, 1.0f0, 0.0f0), vfov = 90.0f0,
        focus = 1.0f0, width = 128, height = 128) =
    Camera(lookfrom, lookat, vup, vfov, focus, width, height)

function Camera(lookfrom::Vec3{T}, lookat::Vec3{T}, vup::Vec3{T}, vfov::R,
                focus::R, width::Int, height::Int) where {T<:AbstractArray, R<:Real}
    fixedparams = FixedCameraParams(vup, width, height)
    return Camera(lookfrom, lookat, [vfov], [focus], fixedparams)
end

"""
    get_primary_rays(c::Camera)

Takes the configuration of the camera and returns the origin and the direction
of the primary rays.
"""
function get_primary_rays(c::Camera)
    width = c.fixedparams.width
    height = c.fixedparams.height
    vup = c.fixedparams.vup
    vfov = c.vfov[]
    focus = c.focus[]

    aspect_ratio = width / height
    half_height = tan(deg2rad(vfov / 2))
    half_width = typeof(half_height)(aspect_ratio * half_height)

    origin = c.lookfrom
    w = normalize(c.lookfrom - c.lookat)
    u = normalize(cross(vup, w))
    v = normalize(cross(w, u))

    # Lower Left Corner
    llc = origin - half_width * focus * u - half_height * focus * v - w
    hori = 2 * half_width * focus * u
    vert = 2 * half_height * focus * v

    s = repeat((collect(0:(width - 1)) .+ 0.5f0) ./ width, outer = height)
    t = repeat((collect((height - 1):-1:0) .+ 0.5f0) ./ height, inner = width)
    
    direction = normalize(llc + s * hori + t * vert - origin)

    return (origin, direction)
end

"""
    get_transformation_matrix(c::Camera)

Returns the `camera_to_world` transformation matrix. This is used for transforming
the coordinates of a Point in 3D Camera Space to 3D World Space using the
[`camera2world`](@ref) function.
"""
function get_transformation_matrix(c::Camera{T}) where {T}
    forward = normalize(c.lookfrom - c.lookat)
    right = normalize(cross(c.fixedparams.vup, forward))
    up = normalize(cross(forward, right))

    return [     right.x[]      right.y[]      right.z[] zero(eltype(T));
                    up.x[]         up.y[]         up.z[] zero(eltype(T));
               forward.x[]    forward.y[]    forward.z[] zero(eltype(T));
            c.lookfrom.x[] c.lookfrom.y[] c.lookfrom.z[]  one(eltype(T))]
end

"""
    compute_screen_coordinates(c::Camera, film_aperture::Tuple,
                               inch_to_mm::Real = 25.4)

Computes the coordinates of the 4 corners of the screen and returns
`top`, `right`, `bottom`, and `left`.
"""
function compute_screen_coordinates(c::Camera, film_aperture::Tuple,
                                    inch_to_mm::Real = 25.4)
    width = c.fixedparams.width
    height = c.fixedparams.height
    vfov = c.vfov[]
    focus = c.focus[]
    
    film_aspect_ratio = film_aperture[1] / film_aperture[2]
    device_aspect_ratio = width / height
    
    top = ((film_aperture[2] * inch_to_mm / 2) / focus)
    right = ((film_aperture[1] * inch_to_mm / 2) / focus)

    xscale = 1
    yscale = 1

    if film_aspect_ratio > device_aspect_ratio
        xscale = device_aspect_ratio / film_aspect_ratio
    else
        yscale = film_aspect_ratio / device_aspect_ratio
    end

    right *= xscale
    top *= yscale

    bottom = -top
    left = -right

    return top, right, bottom, left
end 
