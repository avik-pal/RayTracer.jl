# Objects

abstract type Object end

## Sphere

abstract type Sphere <: Object end

struct SimpleSphere{C, R, D, M} <: Sphere
    center::C
    radius::R
    diffuse::D
    mirror::M
end

struct CheckeredSphere{C, R, D, M} <: Sphere
    center::C
    radius::R
    diffuse::D
    diffuse2::D
    mirror::M
end

function intersect(s::S, origin, direction) where {S<:Sphere}
    b = 2 * dot(direction, origin - s.center)  # direction is a vec3 with array
    c = abs(s.center) .+ abs(origin) .- 2 * dot(s.center, origin) .- (s.radius ^ 2)
    disc = (b .^ 2) .- (4.0f0 .* c)
    sq = sqrt.(max.(disc, 0.0f0))
    h₀ = 0.5f0 * (-b .- sq)
    h₁ = 0.5f0 * (-b .+ sq)
    pos₁ = (h₀ .> 0.0f0) .& (h₀ .< h₁)
    h₁[pos₁] .= h₀[pos₁]
    result = h₁
    result[(disc .<= zero(eltype(disc))) .| (h₁ .<= zero(eltype(h₁)))] .=
        typemax(eltype(h₁)) 
    return result
end

diffusecolor(s::S, pt) where {S<:Sphere} = s.diffuse

function diffusecolor(cs::CheckeredSphere, pt) 
    checker = (Int.(floor.(abs.(pt.x .* 2.0f0))) .% 2) .==
              (Int.(floor.(abs.(pt.z .* 2.0f0))) .% 2)
    return cs.diffuse * checker + cs.diffuse2 * (1.0f0 .- checker)
end

function light(s::S, origin, direction, dist, light_pos, eye_pos,
               scene, obj_num, bounce) where {S<:Sphere}
    pt = origin + direction * dist
    normal = (pt - s.center) / s.radius
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
        color += raytrace(nudged, rayD, scene, light_pos, eye_pos, bounce + 1) * s.mirror
    end

    # Blinn-Phong shading (specular)
    phong = dot(normal, norm(dir_light + dir_origin))
    color += rgb(1.0f0) * ((clamp.(phong, 0.0f0, 1.0f0) .^ 50) .* seelight)

    return color
end
