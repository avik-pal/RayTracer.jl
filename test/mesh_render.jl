screen_size = (w = 512, h = 512)

cam = Camera(
    Vec3(0.5f0, 0.2f0, -0.5f0),
    Vec3(0.0f0, 0.1f0,  0.0f0),
    Vec3(0.0f0, 1.0f0,  0.0f0),
    45.0f0,
    0.5f0,
    screen_size...
)

light = PointLight(
    Vec3(1.0f0), 2.0f8,
    Vec3(10.0f0, 10.0f0, 5.0f0)
)

origin, direction = get_primary_rays(cam)

@testset "Image Texture" begin
    scene = load_obj("./meshes/sign_yield.obj")

    @test_nowarn raytrace(origin, direction, scene, light, origin, 0)
end

@testset "Plain Color Texture" begin
    scene = load_obj("./meshes/tree.obj")

    @test_nowarn raytrace(origin, direction, scene, light, origin, 0)

    @inferred raytrace(origin, direction, scene, light, origin, 0)
end
