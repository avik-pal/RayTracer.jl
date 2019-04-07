using RayTracer, Images

screen_size = (w = 400, h = 300)

light = PointLight(Vec3(1.0f0), 20.0f0, Vec3(5.0f0, 5.0f0, -10.0f0))

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

color = raytrace(origin, direction, scene, light, eye_pos, 0)

proper_shape(a) = clamp.(reshape(a, screen_size.w, screen_size.h), 0.0f0, 1.0f0)

col1 = proper_shape(color.x)
col2 = proper_shape(color.y)
col3 = proper_shape(color.z)

im_arr = permutedims(cat(col1, col2, col3, dims = 3), (3, 2, 1))

img = colorview(RGB, im_arr)

save("cylinder_scene.jpg", img)

