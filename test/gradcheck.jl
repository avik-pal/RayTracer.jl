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

light = PointLight(
    Vec3(1.0),
    1000.0,
    Vec3(0.15, 0.5, -110.5)
)

eye_pos = Vec3(0.0, 0.0, -5.0)

cam = Camera(eye_pos, Vec3(0.0), Vec3(0.0, 1.0, 0.0), 45.0, 1.0, screen_size...)

origin, direction = get_primary_rays(cam);

@testset "Triangle" begin
    scene = [
        Triangle(Vec3(-1.7, 1.0, 0.0), Vec3(1.0, 1.0, 0.0), Vec3(1.0, -1.0, 0.0),
                 Material(color_ambient = Vec3(1.0),
                          color_diffuse = Vec3(1.0),
                          color_specular = Vec3(1.0),
                          specular_exponent = 50.0,
                          reflection = 1.0))
    ]

    scene_new = [
        Triangle(Vec3(-1.9, 1.3, 0.1), Vec3(1.2, 1.1, 0.3), Vec3(0.8, -1.2, -0.15),
                 Material(color_ambient = Vec3(1.0),
                          color_diffuse = Vec3(1.0),
                          color_specular = Vec3(1.0),
                          specular_exponent = 50.0,
                          reflection = 1.0))
    ]
    
    color = raytrace(origin, direction, scene, light, eye_pos, 0)

    zygote_grads = get_params(gradient(x -> loss_fn(x, color), scene_new)[1][1])

    numerical_grads = get_params(numderiv(x -> loss_fn([x], color), scene_new[1]))

    @test isapprox(numerical_grads, zygote_grads, rtol = 1.0e-3)
end
    
@testset "Sphere" begin
    scene = [
        Sphere(Vec3(-1.7, 1.0, 0.0), [0.6], Material())
    ]

    scene_new = [
        Sphere(Vec3(-1.9, 1.3, 0.1), [0.9], Material())
    ]
    
    color = raytrace(origin, direction, scene, light, eye_pos, 0)

    zygote_grads = get_params(gradient(x -> loss_fn(x, color), scene_new)[1][1])

    numerical_grads = get_params(numderiv(x -> loss_fn([x], color), scene_new[1]))

    @test isapprox(numerical_grads, zygote_grads, rtol = 1.0e-3)
end
