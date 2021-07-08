export raytrace

# ----------------- #
# Blinn Phong Model #
# ----------------- #

"""
    light(s::Object, origin, direction, dist, lgt::Light, eye_pos, scene, obj_num, bounce)

Implements the Blinn Phong rendering algorithm. This function is merely for
internal usage and should in no case be called by the user. This function is
quite general and supports user defined **Objects**. For support of custom
Objects have a look at the examples.

!!! warning
    Don't try to use this function by itself. But if you are a person who likes
    to ignore warnings look into the way [`raytrace`](@ref) calls this.
"""
function light(s::Object, origin, direction, dist, lgt::Light, eye_pos,
               scene, obj_num, bounce)
    pt = origin + direction * dist
    normal = get_normal(s, pt, direction)
    dir_light, intensity = get_shading_info(lgt, pt)
    dir_origin = normalize(eye_pos - pt)
    nudged = pt + normal * 0.0001f0 # Nudged to miss itself
    
    # Shadow
    light_distances = map(x -> intersect(x, nudged, dir_light), scene)
    seelight = fseelight(obj_num, light_distances)

    # Ambient
    color = get_color(s, pt, Val(:ambient))

    # Lambert Shading (diffuse)
    visibility = max.(dot(normal, dir_light), 0.0f0)
    color += ((get_color(s, pt, Val(:diffuse)) * intensity) * visibility) * seelight
    
    # Reflection
    if bounce < 2
        rayD = normalize(direction - normal * 2.0f0 * dot(direction, normal))
        color += raytrace(nudged, rayD, scene, lgt, eye_pos, bounce + 1) * reflection(s)
    end

    # Blinn-Phong shading (specular)
    phong = dot(normal, normalize(dir_light + dir_origin))
    color += (get_color(s, pt, Val(:specular)) *
              (clamp.(phong, 0.0f0, 1.0f0) .^ specular_exponent(s))) * seelight

    return color
end

"""
    raytrace(origin::Vec3, direction::Vec3, scene::Vector, lgt::Light,
             eye_pos::Vec3, bounce::Int)
    raytrace(origin::Vec3, direction::Vec3, scene, lgt::Vector{Light},
             eye_pos::Vec3, bounce::Int)
    raytrace(origin::Vec3, direction::Vec3, scene::BoundingVolumeHierarchy,
             lgt::Light, eye_pos::Vec3, bounce::Int)
    raytrace(;origin = nothing, direction = nothing, scene = nothing,
              light_source = nothing, global_illumination = false)

Computes the color contribution to every pixel by tracing every single ray.
Internally it calls the `light` function which implements Blinn Phong Rendering
and adds up the color contribution for each object.

The `eye_pos` is simply the `origin` when called by the user. However, the origin
keeps changing across the recursive calls to this function and hence it is
necessary to keep track of the `eye_pos` separately.

The `bounce` parameter allows the configuration of global illumination. To turn off
global illumination set the `bounce` parameter to `>= 2`. As expected rendering is
much faster if global illumination is off but at the same time is much less photorealistic.

!!! note
    The support for multiple lights is primitive as we loop over the lights.
    Even though it is done in a parallel fashion, it is not the best way to
    do so. Nevertheless it exists just for the sake of experimentation.

!!! note
    None of the parameters (except global_illumination) in the keyword argument version of
    [`raytrace`](@ref) is optional. It is just present for convenience.
"""
raytrace(;origin = nothing, direction = nothing, scene = nothing,
          light_source = nothing, global_illumination = false) =
    raytrace(origin, direction, scene, light_source, origin, global_illumination ? 0 : 2)

function raytrace(origin::Vec3, direction::Vec3, scene::Vector,
                  lgt::Light, eye_pos::Vec3, bounce::Int = 0)
    distances = map(x -> intersect(x, origin, direction), scene)

    dist_reshaped = reducehcat(distances)
    nearest = map(idx -> minimum(dist_reshaped[idx, :]), 1:size(dist_reshaped, 1))

    h = .!isinf.(nearest)

    color = Vec3(0.0f0)

    for (c, (s, d)) in enumerate(zip(scene, distances))
        hit = map((x, y, z) -> ifelse(y == z, x, zero(x)), h, d, nearest)
        if any(hit)
            dc = extract(hit, d)
            originc = extract(hit, origin)
            dirc = extract(hit, direction)
            cc = light(s, originc, dirc, dc, lgt, eye_pos, scene, c, bounce)
            color += place(cc, hit)
        end
    end

    return color
end

# FIXME: This is a temporary solution. Long term solution is to support
#        a light vector in the `light` function itself.
function raytrace(origin::Vec3, direction::Vec3, scene,
                  lgt::Vector{L}, eye_pos::Vec3, bounce::Int = 0) where {L<:Light}
    colors = pmap(x -> raytrace(origin, direction, scene, x, eye_pos, bounce), lgt)
    return sum(colors)
end

# ------------------------ #
# General Helper Functions #
# ------------------------ #

"""
    fseelight(n::Int, light_distances)

Checks if the ``n^{th}`` object in the scene list can see the light source.
"""
function fseelight(n, light_distances)
    ldist = reducehcat(light_distances)
    seelight = map(idx -> minimum(ldist[idx, :]) == ldist[idx,n], 1:size(ldist, 1))
    return seelight
end

# fseelight(n, light_distances) = map((x...) -> min(x...) == x[n], light_distances...)

"""
    reducehcat(x)

This is simply `reduce(hcat(x))`. The version of Zygote we are currently using
can't differentiate through this function. So we define a custom adjoint for this.
"""
reducehcat(x) = reduce(hcat, x)
