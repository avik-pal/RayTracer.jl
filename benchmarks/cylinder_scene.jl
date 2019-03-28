using RayTracer, BenchmarkTools

screen_size = (w = 400, h = 300)

light_pos = Vec3(5.0f0, 5.0f0, -10.0f0)

eye_pos = Vec3(0.0f0, 1.0f0, -1.0f0)

scene = [
    SimpleCylinder(Vec3(1.0f0, 0.5f0, 5.0f0), 1.0f0, Vec3(0.0f0, 2.0f0, 0.0f0),
                   color = Vec3(1.0f0, 0.0f0, 0.0f0)),
    CheckeredCylinder(Vec3(-1.0f0, 0.0f0, 2.0f0), 0.6f0, Vec3(0.0f0, 1.0f0, 0.0f0),
                      color1 = rgb(1.0f0, 1.0f0, 0.0f0),
                      color2 = rgb(1.0f0, 0.0f0, 0.0f0)),
    CheckeredSphere(Vec3(0.0f0, -99999.5f0, 0.0f0), 99999.0f0,
                    color1 = rgb(0.1f0, 0.3f0, 0.4f0), color2 = rgb(0.5f0), reflection = 0.25f0)
    ]

origin, direction = get_primary_rays(Float32, screen_size.w, screen_size.h, 90, eye_pos)

@show @benchmark raytrace($origin, $direction, $scene, $light_pos, $eye_pos, 0)

