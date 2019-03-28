# ------- #
# Objects #
# ------- #

# NOTE: All objects **MUST** have the material field
abstract type Object end

function Base.getproperty(obj::O, k::Symbol) where {O<:Object}
    if k in fieldnames(O)
        return getfield(obj, k)
    else
        return getfield(getfield(obj, :material), k)
    end
end

diffusecolor(obj::O, pt::Vec3) where {O<:Object} =
    diffusecolor(obj.material, pt)

# ---------- #
# - Sphere - #
# ---------- #

struct Sphere{C, R<:Real} <: Object
    center::Vec3{C}
    radius::R
    material::Material
end

s1::Sphere + s2::Sphere = Sphere(s1.center + s2.center,
                                 s1.radius + s2.radius,
                                 s1.material + s2.material)

# The next 3 functions are just convenience functions for handling
# gradients properly for getproperty function
function Sphere(center::Vec3{T}) where {T}
    z = eltype(T)(0)
    mat = Material(PlainColor(rgb(z)), z)
    return Sphere(center, z, mat)
end

function Sphere(radius::T) where {T<:Real}
    z = T(0)
    mat = Material(PlainColor(rgb(z)), z)
    return Sphere(Vec3(z), radius, mat)
end

function Sphere(mat::Material{S, R}) where {S, R}
    z = R(0)
    return Sphere(Vec3(z), z, mat)
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
    b = dot(direction, origin - s.center)  # direction is a vec3 with array
    c = l2norm(s.center) .+ l2norm(origin) .- 2 .* dot(s.center, origin) .- (s.radius ^ 2)
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

get_normal(s::Sphere, pt) = normalize(pt - s.center)

# ------------ #
# - Cylinder - #
# ------------ #

struct Cylinder{C, R, L} <: Object
    center::C
    radius::R
    axis::C
    length::L
    material::Material
end

function SimpleCylinder(center, radius, axis; color = rgb(0.5f0), reflection = 0.5f0)
    mat = Material(PlainColor(color), reflection)
    return Cylinder(center, radius, normalize(axis), l2norm(axis), mat)
end

function SimpleCylinder(center, radius, axis, length; color = rgb(0.5f0),
                        reflection = 0.5f0)
    mat = Material(PlainColor(color), reflection)
    return Cylinder(center, radius, normalize(axis), length, mat)
end

function CheckeredCylinder(center, radius, axis; color1 = rgb(0.1f0), color2 = rgb(0.9f0),
                           reflection = 0.5f0)
    mat = Material(CheckeredSurface(color1, color2), reflection)
    return Cylinder(center, radius, normalize(axis), l2norm(axis), mat)
end

function CheckeredCylinder(center, radius, axis, length; color1 = rgb(0.1f0),
                          color2 = rgb(0.9f0), reflection = 0.5f0)
    mat = Material(CheckeredSurface(color1, color2), reflection)
    return Cylinder(center, radius, normalize(axis), length, mat)
end

# TODO: Currently Cylinder means Hollow Cyclinder. Generalize for Solid Cylinder
#       The easiest way to do this would be to treat Solid Cylinder as 3 different
#       objects - Hollow Cylinder + 2 Solid Discs
function intersect(cy::Cylinder, origin, direction)
    diff = origin - cy.center
    a_vec = direction - dot(cy.axis, direction) * cy.axis
    c_vec = diff - dot(diff, cy.axis) * cy.axis 
    a = 2 .* l2norm(a_vec) # No point in doing 2 .* a everywhere so doing it here itself
    b = 2 .* dot(a_vec, c_vec)
    c = l2norm(c_vec) .- (cy.radius ^ 2)
    disc = (b .^ 2) .- 2 .* a .* c
    
    sq = sqrt.(max.(disc, 0.0f0))
    h₀ = (-b .- sq) ./ a
    h₁ = (-b .+ sq) ./ a
    zt1 = dot(origin + direction * h₀, cy.axis)
    center_comp = dot(cy.center, cy.axis)
    zmax = center_comp + cy.length / 2
    zmin = center_comp - cy.length / 2
    zt2 = dot(origin + direction * h₁, cy.axis)
    
    function get_intersections(d, z1, z2, zt1, zt2)
        t = bigmul(d + z1 + z2 + zt1 + zt2)
        if d > 0
            if z1 <= 0 && z2 > 0 && zmin <= zt2 <= zmax
                t = z2
            elseif z1 > 0
                if zmin <= zt1 <= zmax
                    t = z1
                elseif z2 > 0 && zmin <= zt2 <= zmax
                    t = z2
                end
            end
        end
        return t
    end
    result = broadcast(get_intersections, disc, h₀, h₁, zt1, zt2)
    return result
end

function get_normal(c::Cylinder, pt)
    pt_c = pt - c.center
    return normalize(pt_c - dot(pt_c, c.axis) * c.axis)
end

# ------------ #
# - Triangle - #
# ------------ #

# TODO: Use barycentric coordinates and Moller-Trumbore Algorithm
struct Triangle{V} <: Object
    v1::V
    v2::V
    v3::V
# NOTE: We only support double sided. Here is the defination of single and double sided
# http://www.scratchapixel.com/lessons/3d-basic-rendering/ray-tracing-rendering-a-triangle/single-vs-double-sided-triangle-backface-culling
    normal::V
    material::Material
end 

function Triangle(v1, v2, v3; color = rgb(0.5f0), reflection = 0.5f0)
    mat = Material(PlainColor(color), reflection)
    normal = normalize(cross(v2 - v1, v3 - v1)) 
    return Triangle(v1, v2, v3, normal, mat)
end

function intersect(t::Triangle, origin, direction)
    h = - (dot(t.normal, origin) .+ dot(t.normal, t.v1)) ./ dot(t.normal, direction)
    pt = origin + direction * h
    edge1 = t.v2 - t.v1
    edge2 = t.v3 - t.v2
    edge3 = t.v1 - t.v3
    c₁ = pt - t.v1
    c₂ = pt - t.v2
    c₃ = pt - t.v3
    val1 = dot(t.normal, cross(edge1, c₁))
    val2 = dot(t.normal, cross(edge2, c₂))
    val3 = dot(t.normal, cross(edge3, c₃))
    get_intersections(a, b, c, d) =
        (a > 0 && b > 0 && c > 0 && d > 0) ? a : bigmul(a + b + c + d)
    result = broadcast(get_intersections, h, val1, val2, val3)
    return result
end

function get_normal(t::Triangle, pt)
    normal = Vec3(fill(t.normal.x, size(pt.x)),
                  fill(t.normal.y, size(pt.y)),
                  fill(t.normal.z, size(pt.z)))
    return normal
end

# ----------------------------- #
# - General Object Properties - #
# ----------------------------- #

# NOTE: We should be good to go for any arbitrary object if we implement
#       `get_normal` and `intersect` functions for that object.
#       Additionally it must have the `mirror` field.
function light(s::S, origin, direction, dist, light_pos, eye_pos,
               scene, obj_num, bounce) where {S<:Object}
    pt = origin + direction * dist
    normal = get_normal(s, pt)
    dir_light = normalize(light_pos - pt)
    dir_origin = normalize(eye_pos - pt)
    nudged = pt + normal * 0.0001f0 # Nudged to miss itself
    
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
        rayD = normalize(direction - normal * 2.0f0 * dot(direction, normal))
        color += raytrace(nudged, rayD, scene, light_pos, eye_pos, bounce + 1) * s.reflection
    end

    # Blinn-Phong shading (specular)
    phong = dot(normal, normalize(dir_light + dir_origin))
    color += rgb(1.0f0) * ((clamp.(phong, 0.0f0, 1.0f0) .^ 50) .* seelight)

    return color
end

