using Zygote
using RayTracer: get_params, set_params!

function loss_fn(θ, color)
    rendered_color = raytrace(origin, direction, θ, light, eye_pos, 0)
    loss = sum(abs2.(rendered_color.x .- color.x) .+
               abs2.(rendered_color.y .- color.y) .+
               abs2.(rendered_color.z .- color.z))
    return loss
end

# Define the Scene Parameters

screen_size = (w = 400, h = 300)

light = PointLight(Vec3(1.0f0), 1000.0f0, Vec3(0.15f0, 0.5f0, -110.5f0))

eye_pos = Vec3(0.0f0, 0.0f0, -5.0f0)

cam = Camera(eye_pos, Vec3(0.0f0), Vec3(0.0f0, 1.0f0, 0.0f0), 45.0f0, 1.0f0, screen_size...)

origin, direction = get_primary_rays(cam);

@testset "Triangle" begin
    scene = [
        Triangle(Vec3(-1.7f0, 1.0f0, 0.0f0), Vec3(1.0f0, 1.0f0, 0.0f0), Vec3(1.0f0, -1.0f0, 0.0f0),
                 Material())
    ]

    scene_new = [
        Triangle(Vec3(-1.9f0, 1.3f0, 0.1f0), Vec3(1.2f0, 1.1f0, 0.3f0), Vec3(0.8f0, -1.2f0, -0.15f0),
                 Material())
    ]
    
    color = raytrace(origin, direction, scene, light, eye_pos, 0)

    zygote_grads = get_params(gradient(x -> loss_fn(x, color), scene_new)[1][1])

    numerical_grads = get_params(numderiv(x -> loss_fn([x], color), scene_new[1]))

    # Ignore the Material Gradients
    @test isapprox(numerical_grads[1:end-4], zygote_grads[1:end-4], rtol = 1.0e-1)
end
    
@testset "Sphere" begin
    scene = [
        Sphere(Vec3(-1.7f0, 1.0f0, 0.0f0), [0.6f0], Material())
    ]

    scene_new = [
        Sphere(Vec3(-1.9f0, 1.3f0, 0.1f0), [0.9f0], Material())
    ]
    
    color = raytrace(origin, direction, scene, light, eye_pos, 0)

    zygote_grads = get_params(gradient(x -> loss_fn(x, color), scene_new)[1][1])

    numerical_grads = get_params(numderiv(x -> loss_fn([x], color), scene_new[1]))

    # Ignore the Material Gradients
    @test isapprox(numerical_grads[1:end-5], zygote_grads[1:end-5], rtol = 1.0e-1)
end
