using RayTracer, Zygote, Flux, Images, Statistics

function create_and_save(color, val)
    img = get_image(color, screen_size.w, screen_size.h)
    save("images/triangle_$(val).jpg", img)
end

screen_size = (w = 200, h = 200)

light = PointLight(Vec3(1.0), 20000.0, Vec3(5.0, 5.0, -10.0))

light_perturbed = PointLight(Vec3(1.0), 20000.0, Vec3(1.0, 2.0, -7.0))

eye_pos = Vec3(0.0, 0.0, -5.0)

scene = [
    Triangle(Vec3(-1.7, 1.0, 0.0), Vec3(1.0, 1.0, 0.0), Vec3(-0.5, -1.0, 0.0),
             color = rgb(0.0, 1.0, 0.0), reflection = 0.5)    
    ]

origin, direction = get_primary_rays(Float64, screen_size.w, screen_size.h, 45, eye_pos);

color = raytrace(origin, direction, scene, light, eye_pos, 0)

create_and_save(color, "original")

color_guess = raytrace(origin, direction, scene, light_perturbed, eye_pos, 0)

create_and_save(color_guess, "initial_guess")

function process_image(im::Vec3{T}, width, height) where {T}
    im_arr = reshape(hcat(im.x, im.y, im.z), (width, height, 3))
    
    return reshape(im_arr, (width, height, 3, 1))
end

function loss_fn(θ, img)
    rendered_color = raytrace(origin, direction, scene, θ, eye_pos, 0)
    rendered_img = process_image(rendered_color, screen_size.w, screen_size.h)
    loss = mean(abs2.(rendered_img .- img))
    @show loss
    return loss
end

image = process_image(color, screen_size.w, screen_size.h);

opt = ADAM(0.05)

for i in 1:9000
    gs = gradient(x -> loss_fn(x, image), light_perturbed)[1]
    update!(opt, light_perturbed.position, gs.position)
    if i % 5 == 0
        @info "$i iterations completed"
        create_and_save(raytrace(origin, direction, scene, light_perturbed, eye_pos, 0), i)
        display(light_perturbed)
    end
end

@info "Light Position Optimized"