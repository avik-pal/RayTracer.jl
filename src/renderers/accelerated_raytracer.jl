function raytrace(origin::Vec3, direction::Vec3, scene::BoundingVolumeHierarchy,
                  lgt::Light, eye_pos::Vec3, bounce::Int = 0)
    distances = intersect(scene, origin, direction)
    
    dist_reshaped = reducehcat([values(distances)...])
    nearest = map(idx -> minimum(dist_reshaped[idx, :]), 1:size(dist_reshaped, 1))

    h = .!isinf.(nearest)

    color = Vec3(0.0f0)

    for s in scene.scene_list
        local d
        # Zygote can't handle try/catch blocks
        try
            d = distances[s]
        catch e
            isa(e, KeyError) && continue
            throw(e)
        end
        hit = map((x, y, z) -> ifelse(y == z, x, zero(x)), h, d, nearest)
        if any(hit)
            dc = extract(hit, d)
            originc = extract(hit, origin)
            dirc = extract(hit, direction)
            cc = light(s, originc, dirc, dc, lgt, eye_pos, scene, bounce)
            color += place(cc, hit)
        end
    end

    return color
end

function light(s::Object, origin, direction, dist, lgt::Light, eye_pos,
               scene::BoundingVolumeHierarchy, bounce)
    pt = origin + direction * dist
    normal = get_normal(s, pt, direction)
    dir_light, intensity = get_shading_info(lgt, pt)
    dir_origin = normalize(eye_pos - pt)
    nudged = pt + normal * 0.0001f0 # Nudged to miss itself

    # Shadow
    light_distances = intersect(scene, nudged, dir_light)
    seelight = fseelight(s, light_distances)

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

function fseelight(t::Triangle, light_distances)
    ldist = reducehcat([values(light_distances)...])
    seelight = map(idx -> minimum(ldist[idx, :]) == light_distances[t][idx], 1:size(ldist, 1))
    return seelight
end
