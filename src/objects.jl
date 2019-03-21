# Objects

# NOTE: All objects **MUST** have the material field
abstract type Object end

function Base.getproperty(obj::O, k::Symbol) where {O<:Object}
    if k in fieldnames(O)
        return getfield(obj, k)
    else
        return getfield(getfield(obj, :material), k)
    end
end

diffusecolor(obj::O, pt::NamedTuple{(:x, :y, :z)}) where {O<:Object} =
    diffusecolor(obj.material, pt)

## Sphere

struct Sphere{C, R} <: Object
    center::C
    radius::R
    material::Material
end

function SimpleSphere(center, radius; color = rgb(0.5f0), reflection = 0.5f0)
    mat = Material(PlainColor(color), reflection)
    return Sphere(center, radius, mat)
end

function CheckeredSphere(center, radius; color1 = rgb(0.1f0), color2 = rgb(0.9f0),
                         reflection = 0.5f0)
    mat = Material(CheckeredSurface(color1, color2), reflection)
    return Sphere(center, radius, mat)
end

function intersect(s::Sphere, origin, direction)
    b = 2 * dot(direction, origin - s.center)  # direction is a vec3 with array
    c = abs(s.center) .+ abs(origin) .- 2 * dot(s.center, origin) .- (s.radius ^ 2)
    disc = (b .^ 2) .- (4.0f0 .* c)
    sq = sqrt.(max.(disc, 0.0f0))
    h₀ = 0.5f0 * (-b .- sq)
    h₁ = 0.5f0 * (-b .+ sq)
    pos₁ = (h₀ .> 0.0f0) .& (h₀ .< h₁)
    h₁[pos₁] .= h₀[pos₁]
    result = h₁
    # FIXME: Need to modify this for running properly on GPUs
    result[(disc .<= zero(eltype(disc))) .| (h₁ .<= zero(eltype(h₁)))] .=
        typemax(eltype(h₁)) 
    return result
end

get_normal(s::Sphere, pt, direction) = norm(pt - s.center)

## Cylinder

# TODO: Specialize the function for length == Inf. We don't need to consider
#       intersection will 2 slabs in that case
struct Cylinder{C, R, L} <: Object
    center::C
    radius::R
    axis::C
    length::L
    material::Material
end

function SimpleCylinder(center, radius, axis; color = rgb(0.5f0), reflection = 0.5f0)
    mat = Material(PlainColor(color), reflection)
    return Cylinder(center, radius, norm(axis), abs(axis), mat)
end

function SimpleCylinder(center, radius, axis, length; color = rgb(0.5f0),
                        reflection = 0.5f0)
    mat = Material(PlainColor(color), reflection)
    return Cylinder(center, radius, norm(axis), length, mat)
end

function CheckeredCylinder(center, radius, axis; color1 = rgb(0.1f0), color2 = rgb(0.9f0),
                           reflection = 0.5f0)
    mat = Material(CheckeredSurface(color1, color2), reflection)
    return Cylinder(center, radius, norm(axis), abs(axis), mat)
end

function CheckeredCylinder(center, radius, axis, length; color1 = rgb(0.1f0),
                          color2 = rgb(0.9f0), reflection = 0.5f0)
    mat = Material(CheckeredSurface(color1, color2), reflection)
    return Cylinder(center, radius, norm(axis), length, mat)
end

# Currently Cylinder means Solid Cyclinder. Generalize for Hollow Cylinder
# FIXME: intersect is for infinite cylinder
function intersect(c::Cylinder, origin, direction)
    diff = origin - c.center
    a_vec = direction - dot(c.axis, direction) * c.axis
    c_vec = diff - dot(diff, c.axis) * c.axis 
    a = 2 .* abs(a_vec) # No point in doing 2 .* a everywhere so doing it here itself
    b = 2 .* dot(a_vec, c_vec)
    c = abs(c_vec) .- (c.radius ^ 2)
    disc = (b .^ 2) .- 2 .* a .* c
    sq = sqrt.(max.(disc, 0.0f0))
    h₀ = (-b .- sq) ./ a
    h₁ = (-b .+ sq) ./ a
    pos₁ = (h₀ .> 0.0f0) .& (h₀ .< h₁)
    h₁[pos₁] .= h₀[pos₁]
    result = h₁
    # FIXME: Need to modify this for running properly on GPUs
    result[(disc .<= zero(eltype(disc))) .| (h₁ .<= zero(eltype(h₁)))] .=
        typemax(eltype(h₁)) 
    return result
end

function get_normal(c::Cylinder, pt, direction)
    pt_c = pt - c.center
    return norm(pt_c - dot(pt_c, c.axis) * c.axis)
end

## General Object Properties

# NOTE: We should be good to go for any arbitrary object if we implement
#       `get_normal` and `intersect` functions for that object.
#       Additionally it must have the `mirror` field.
function light(s::S, origin, direction, dist, light_pos, eye_pos,
               scene, obj_num, bounce) where {S<:Object}
    pt = origin + direction * dist
    normal = get_normal(s, pt, direction)
    dir_light = norm(light_pos - pt)
    dir_origin = norm(eye_pos - pt)
    nudged = pt + normal * 0.0001f0
    
    # Shadow
    light_distances = [intersect(obj, nudged, dir_light) for obj in scene]
    light_nearest = map(min, light_distances...)
    seelight = light_distances[obj_num] .== light_nearest    

    # Ambient
    color = rgb(0.05f0)

    # Lambert Shading (diffuse)
    lv = max.(dot(normal, dir_light), 0.0f0)
    color += diffusecolor(s, pt) * (lv .* seelight)

    # Reflection
    if bounce < 2
        rayD = norm(direction - normal * 2.0f0 * dot(direction, normal))
        color += raytrace(nudged, rayD, scene, light_pos, eye_pos, bounce + 1) * s.reflection
    end

    # Blinn-Phong shading (specular)
    phong = dot(normal, norm(dir_light + dir_origin))
    color += rgb(1.0f0) * ((clamp.(phong, 0.0f0, 1.0f0) .^ 50) .* seelight)

    return color
end

