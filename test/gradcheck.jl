using Zygote

# Taken from Zygote.jl
function ngradient(f, xs::AbstractArray...)
    grads = zero.(xs)
    for (x, Δ) in zip(xs, grads), i in 1:length(x)
        δ = sqrt(eps())
        tmp = x[i]
        x[i] = tmp - δ/2
        y1 = f(xs...)
        x[i] = tmp + δ/2
        y2 = f(xs...)
        x[i] = tmp
        Δ[i] = (y2-y1)/δ
    end
    return grads
end

get_params(x::T) where {T<:AbstractArray} = x

get_params(x::T) where {T<:Real} = [x]

get_params(x::T) where {T} = foldl((a, b) -> [a; b],
                                   [map(i -> get_params(getfield(x, i)), fieldnames(T))...])

function set_params(s::Triangle, x::AbstractArray)
    s.v1 = Vec3(x[1], x[2], x[3])
    s.v2 = Vec3(x[4], x[5], x[6])
    s.v3 = Vec3(x[7], x[8], x[9])
    return s
end

function set_params(s::Sphere, x::AbstractArray)
    s.center = Vec3(x[1], x[2], x[3])
    s.radius = x[4]
    return s
end

function scene_gradients(sc, x, color)
    scene = deepcopy(sc)
    set_params(scene, x)
    loss_fn([scene], color)
end

function loss_fn(θ, color)
    rendered_color = raytrace(origin, direction, θ, light, eye_pos, 0)
    loss = sum(abs2.(rendered_color.x .- color.x) .+
               abs2.(rendered_color.y .- color.y) .+
               abs2.(rendered_color.z .- color.z))
    return loss
end

# Define the Scene Parameters

screen_size = (w = 400, h = 300)

light = PointLight(Vec3(1.0), 1000.0, Vec3(0.15, 0.5, -110.5))

eye_pos = Vec3(0.0, 0.0, -5.0)

origin, direction = get_primary_rays(Float64, screen_size.w, screen_size.h, 60, eye_pos);

@testset "Triangle" begin

    scene = [
        Triangle(Vec3(-1.7, 1.0, 0.0), Vec3(1.0, 1.0, 0.0), Vec3(1.0, -1.0, 0.0),
                 color = rgb(1.0, 1.0, 1.0), reflection = 0.5)
    ]

    scene_new = [
        Triangle(Vec3(-1.9, 1.3, 0.1), Vec3(1.2, 1.1, 0.3), Vec3(0.8, -1.2, -0.15),
                 color = rgb(1.0, 1.0, 1.0), reflection = 0.5)
    ]
    
    color = raytrace(origin, direction, scene, light, eye_pos, 0)

    zygote_grads = get_params(gradient(x -> loss_fn(x, color), scene_new)[1][1])

    numerical_grads = ngradient(x -> scene_gradients(scene_new[1], x, color), get_params(scene_new[1]))[1]

    # Ignore the Material Gradients
    @test isapprox(numerical_grads[1:end-4], zygote_grads[1:end-4], rtol = 1.0e-5)

end
    
@testset "Sphere" begin

    scene = [
        SimpleSphere(Vec3(-1.7, 1.0, 0.0), 0.6, color = rgb(1.0, 1.0, 1.0), reflection = 0.5)
    ]

    scene_new = [
        SimpleSphere(Vec3(-1.9, 1.3, 0.1), 0.9, color = rgb(1.0, 1.0, 1.0), reflection = 0.5)
    ]
    
    color = raytrace(origin, direction, scene, light, eye_pos, 0)

    zygote_grads = get_params(gradient(x -> loss_fn(x, color), scene_new)[1][1])

    numerical_grads = ngradient(x -> scene_gradients(scene_new[1], x, color), get_params(scene_new[1]))[1]

    # Ignore the Material Gradients
    @test isapprox(numerical_grads[1:end-4], zygote_grads[1:end-4], rtol = 1.0e-5)

end
