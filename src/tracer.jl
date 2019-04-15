# -------- #
# RayTrace #
# -------- #

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
