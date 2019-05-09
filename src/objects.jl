# ------- #
# Objects #
# ------- #

# NOTE: All objects **MUST** have the material field
abstract type Object end

diffusecolor(obj::O, pt::Vec3) where {O<:Object} =
    diffusecolor(obj.material, pt)

# ----------- #
# - Imports - #
# ----------- #

include("objects/sphere.jl")
include("objects/cylinder.jl")
include("objects/triangle.jl")
include("objects/disc.jl")

# ----------------------------- #
# - General Object Properties - #
# ----------------------------- #

# NOTE: We should be good to go for any arbitrary object if we implement
#       `get_normal` and `intersect` functions for that object.
#       Additionally it must have the `mirror` field.
function light(s::S, origin, direction, dist, lgt::L, eye_pos,
               scene, obj_num, bounce) where {S<:Object, L<:Light}
    pt = origin + direction * dist
    normal = get_normal(s, pt)
    dir_light, intensity = get_shading_info(lgt, pt)
    dir_origin = normalize(eye_pos - pt)
    nudged = pt + normal * 0.0001f0 # Nudged to miss itself
    
    # Shadow
    light_distances = broadcast(x -> intersect(x, nudged, dir_light), scene)
    seelight = fseelight(obj_num, light_distances)
    
    # Ambient
    color = rgb(0.05f0)

    # Lambert Shading (diffuse)
    visibility = max.(dot(normal, dir_light), 0.0f0)
    color += ((diffusecolor(s, pt) * intensity) * visibility) * seelight
    
    # Reflection
    if bounce < 2
        rayD = normalize(direction - normal * 2.0f0 * dot(direction, normal))
        color += raytrace(nudged, rayD, scene, lgt, eye_pos, bounce + 1) *
                 s.material.reflection
    end

    # Blinn-Phong shading (specular)
    phong = dot(normal, normalize(dir_light + dir_origin))
    color += (rgb(1.0f0) * (clamp.(phong, 0.0f0, 1.0f0) .^ 50)) * seelight

    return color
end

function raytrace(origin::Vec3, direction::Vec3, scene::Vector,
                  lgt::L, eye_pos::Vec3, bounce::Int = 0) where {L<:Light}
    distances = broadcast(x -> intersect(x, origin, direction), scene)

    nearest = map(min, distances...)
    h = bigmul.(nearest) .!= nearest

    color = rgb(0.0f0)

    for (i, (s, d)) in enumerate(zip(scene, distances))
        hit = h .& (d .== nearest)
        if sum(hit) != 0
            dc = extract(hit, d)
            originc = extract(hit, origin)
            dirc = extract(hit, direction)
            cc = light(s, originc, dirc, dc, lgt, eye_pos, scene, i, bounce)
            color += place(cc, hit)
        end
    end

    return color
end

# FIXME: This is a temporary solution. Long term solution is to support
#        a light vector in the `light` function itself.
function raytrace(origin::Vec3, direction::Vec3, scene::Vector,
                  lgt::Vector{L}, eye_pos::Vec3, bounce::Int = 0) where {L<:Light}
    colors = pmap(x -> raytrace(origin, direction, scene, x, eye_pos, 0), lgt)
    return sum(colors)
end

fseelight(n, light_distances) = map((x...) -> min(x...) == x[n], light_distances...)
