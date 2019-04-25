using RayTracer, Zygote, Statistics, Images

screen_size = (w = 400, h = 300)

light = PointLight(Vec3(1.0f0), 50.0f0, Vec3(5.0f0, 5.0f0, -10.0f0))

light2 = PointLight(Vec3(1.0f0), 10.0f0, Vec3(rand(Float32, 3)...))

eye_pos = Vec3(0.0f0, 0.35f0, -1.0f0)

scene = [
    SimpleSphere(Vec3(0.75f0, 0.1f0, 1.0f0), 0.6f0, color = rgb(0.0f0, 0.0f0, 1.0f0)),
    ]

origin, direction = get_primary_rays(Float32, 400, 300, 90, eye_pos)

proper_shape(a) = clamp.(reshape(a, screen_size.w, screen_size.h), 0.0f0, 1.0f0)

function create_and_save(color, val)
    col1 = proper_shape(color.x)
    col2 = proper_shape(color.y)
    col3 = proper_shape(color.z)

    im_arr = permutedims(cat(col1, col2, col3, dims = 3), (3, 2, 1))

    img = colorview(RGB, im_arr)

    save("images/image_$(val).jpg", img)
end

color = raytrace(origin, direction, scene, light, eye_pos, 0)

create_and_save(color, "original")

function diff(col)
    c = color - col
    mean(abs2.(c.x)) + mean(abs2.(c.y)) + mean(abs2.(c.z))
end

ldiff(lgt) = diff(raytrace(origin, direction, scene, lgt, eye_pos, 0))

l = light2

for i in 0:1000
    global l
    y, back = Zygote._forward(ldiff, l)
    println("Loss = $y")
    g = back(1.0f0)[2]
    l = l - 1.0f0 * g
    if i % 30 == 0
        create_and_save(raytrace(origin, direction, scene, l, eye_pos, 0), i)
    end
    display(l)
end
