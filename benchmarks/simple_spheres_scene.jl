using BenchmarkTools, RayTracer

screen_size = (w = 400, h = 300)

light_pos = Vec3(5.0f0, 5.0f0, -10.0f0)

eye_pos = Vec3(0.0f0, 0.35f0, -1.0f0)

scene = [
    SimpleSphere(Vec3(0.75f0, 0.1f0, 1.0f0), 0.6f0, rgb(0.0f0, 0.0f0, 1.0f0), 0.5f0),
    SimpleSphere(Vec3(-0.75f0, 0.1f0, 2.25f0), 0.6f0, rgb(0.5f0, 0.223f0, 0.5f0), 0.5f0),
    SimpleSphere(Vec3(-2.75f0, 0.1f0, 3.5f0), 0.6f0, rgb(1.0f0, 0.572f0, 0.184f0), 0.5f0),
    CheckeredSphere(Vec3(0.0f0, -99999.5f0, 0.0f0), 99999.0f0, rgb(0.75f0, 0.75f0, 0.75f0), 0.25f0)
    ]

aspect_ratio = Float32.(screen_size.w / screen_size.h)

screen_coord = (x₀ = -1.0f0, y₀ = 1.0f0 / aspect_ratio + 0.25f0, x₁ = 1.0f0,
                y₁ = -1.0f0 / aspect_ratio + 0.25f0)

x = repeat(range(screen_coord.x₀, stop = screen_coord.x₁, length = screen_size.w),
           outer = screen_size.h)

y = repeat(range(screen_coord.y₀, stop = screen_coord.y₁, length = screen_size.h),
           inner = screen_size.w)

Q = Vec3(x, y, zeros(eltype(x), size(x)...))

@benchmark raytrace($eye_pos, $norm($Q - $eye_pos), $scene, $light_pos, $eye_pos, 0)

