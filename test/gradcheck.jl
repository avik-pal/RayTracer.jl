using Zygote

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

    numerical_grads = get_params(numderiv(x -> loss_fn([x], color), scene_new[1]))

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

    numerical_grads = get_params(numderiv(x -> loss_fn([x], color), scene_new[1]))

    # Ignore the Material Gradients
    @test isapprox(numerical_grads[1:end-4], zygote_grads[1:end-4], rtol = 1.0e-5)

end
