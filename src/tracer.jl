# RayTrace

function raytrace(origin, direction, scene, light_pos, eye_pos, bounce = 0)
    distances = [intersect(s, origin, direction) for s in scene]

    nearest = map(min, distances...)
    h = typemax.(nearest) .!= nearest

    color = rgb(0.0f0)

    for (i, (s, d)) in enumerate(zip(scene, distances))
        hit = h .& (d .== nearest)
        if any(hit)
            dc = extract(hit, d)
            originc = extract(hit, origin)
            dirc = extract(hit, direction)
            cc = light(s, originc, dirc, dc, light_pos, eye_pos,
                       scene, i, bounce)
            color += place(cc, hit)
        end
    end

    return color
end
