using RayTracer, Images

screen_size = (w = 400, h = 300)

light_pos = Vec3(5.0f0, 5.0f0, -10.0f0)

eye_pos = Vec3(0.0f0, 0.35f0, -1.0f0)

scene = [
    SimpleSphere(Vec3(0.75f0, 0.1f0, 1.0f0), 0.6f0, color = rgb(0.0f0, 0.0f0, 1.0f0)),
    SimpleSphere(Vec3(-0.75f0, 0.1f0, 2.25f0), 0.6f0, color = rgb(0.5f0, 0.223f0, 0.5f0)),
    SimpleSphere(Vec3(-2.75f0, 0.1f0, 3.5f0), 0.6f0, color = rgb(1.0f0, 0.572f0, 0.184f0)),
    CheckeredSphere(Vec3(0.0f0, -99999.5f0, 0.0f0), 99999.0f0,
                    color1 = rgb(0.0f0, 1.0f0, 0.0f0),
                    color2 = rgb(0.0f0, 0.0f0, 1.0f0), reflection = 0.25f0)
    ]

aspect_ratio = Float32.(screen_size.w / screen_size.h)

screen_coord = (x₀ = -1.0f0, y₀ = 1.0f0 / aspect_ratio + 0.25f0, x₁ = 1.0f0,
                y₁ = -1.0f0 / aspect_ratio + 0.25f0)

x = repeat(range(screen_coord.x₀, stop = screen_coord.x₁, length = screen_size.w),
           outer = screen_size.h)

y = repeat(range(screen_coord.y₀, stop = screen_coord.y₁, length = screen_size.h),
           inner = screen_size.w)

Q = Vec3(x, y, zeros(eltype(x), size(x)...))

color = raytrace(eye_pos, norm(Q - eye_pos), scene, light_pos, eye_pos, 0)

proper_shape(a) = clamp.(reshape(a, screen_size.w, screen_size.h), 0.0f0, 1.0f0)

col1 = proper_shape(color.x)
col2 = proper_shape(color.y)
col3 = proper_shape(color.z)

im_arr = permutedims(cat(col1, col2, col3, dims = 3), (3, 2, 1))

img = colorview(RGB, im_arr)

save("simple_spheres_scene.jpg", img)

light_pos = Vec3(5.0f0, 55.0f0, -10.0f0)

color = raytrace(eye_pos, norm(Q - eye_pos), scene, light_pos, eye_pos, 0)

col1 = proper_shape(color.x)
col2 = proper_shape(color.y)
col3 = proper_shape(color.z)

im_arr = permutedims(cat(col1, col2, col3, dims = 3), (3, 2, 1))

img = colorview(RGB, im_arr)

save("simple_spheres_scene_altlight.jpg", img)

