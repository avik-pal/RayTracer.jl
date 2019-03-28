# -------- #
# RayTrace #
# -------- #

function raytrace(origin::Vec3, direction::Vec3, scene::Vector,
                  light_pos::Vec3, eye_pos::Vec3, bounce::Int = 0)
    distances = [intersect(s, origin, direction) for s in scene]

    nearest = map(min, distances...)
    h = bigmul.(nearest) .!= nearest

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
