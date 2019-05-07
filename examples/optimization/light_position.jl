using RayTracer, Zygote, Statistics, Images, Flux

screen_size = (w = 400, h = 300)

light = PointLight(Vec3(1.0f0), 50000.0f0, Vec3(5.0f0, 5.0f0, -10.0f0))

light_perturbed = PointLight(Vec3(1.0f0), 45000.0f0, Vec3(3.0f0, 3.0f0, -7.0f0))

eye_pos = Vec3(0.0f0, 0.35f0, -1.0f0)

scene = [
    SimpleSphere(Vec3(0.75f0, 0.1f0, 1.0f0), 0.6f0, color = rgb(0.0f0, 0.0f0, 1.0f0)),
    ]

origin, direction = get_primary_rays(Float32, 400, 300, 90, eye_pos)

function create_and_save(color, val)
    img = get_image(color, screen_size.w, screen_size.h)

    save("images/image_$(val).jpg", img)
end

color = raytrace(origin, direction, scene, light, eye_pos, 0)

create_and_save(color, "original")

function diff(lgt)
    c = color - raytrace(origin, direction, scene, lgt, eye_pos, 0)
    mean(abs2.(c.x)) + mean(abs2.(c.y)) + mean(abs2.(c.z))
end

opt = ADAM(0.001f0)

l = deepcopy(light_perturbed)

for i in 0:100
    global l
    y, back = Zygote._forward(diff, l)
    println("Loss = $y")
    g = back(1.0f0)[2]
    update!(opt, l, g)
    if i % 10 == 0
        create_and_save(raytrace(origin, direction, scene, l, eye_pos, 0), i)
    end
    display(l)
end
