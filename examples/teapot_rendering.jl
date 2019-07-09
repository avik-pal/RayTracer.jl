using RayTracer, Images

screen_size = (w = 128, h = 128)

# Load the teapot object and ensure the type of the scene
# vector is properly infered
scene = load_obj("teapot.obj")

# Define a convenience function for rendering and saving the images
function generate_render_and_save(cam, light, filename)
    # Get the primary rays for the camera
    origin, direction = get_primary_rays(cam)

    # Render the scene
    color = raytrace(origin, direction, scene, light, origin, 2)

    img = get_image(color, screen_size...)

    save(filename, img)
end

# TOP VIEW Render
# Setup the light position
light = DistantLight(Vec3(1.0f0), 100.0f0, Vec3(0.0f0, 1.0f0, 0.0f0))

# Setup the camera and generate the primary rays
cam = Camera(Vec3(1.0f0, 10.0f0, -1.0f0), Vec3(0.0f0), Vec3(0.0f0, 1.0f0, 0.0f0),
             45.0f0, 1.0f0, screen_size...)

generate_render_and_save(cam, light, "teapot_top.jpg")

# SIDE VIEW Render
# Setup the light postion
light = DistantLight(Vec3(1.0f0), 100.0f0, Vec3(1.0f0, 1.0f0, -1.0f0))

# Camera setup
cam = Camera(Vec3(1.0f0, 2.0f0, -10.0f0), Vec3(0.0f0, 1.0f0, 0.0f0),
             Vec3(0.0f0, 1.0f0, 0.0f0), 45.0f0, 1.0f0, screen_size...)

generate_render_and_save(cam, light, "teapot_side.jpg")

# FRONT VIEW Render
# Setup the light position
light = DistantLight(Vec3(1.0f0), 100.0f0, Vec3(1.0f0, 1.0f0, 0.0f0))

# Camera setup
cam = Camera(Vec3(10.0f0, 2.0f0, 0.0f0), Vec3(0.0f0, 1.0f0, 0.0f0),
             Vec3(0.0f0, 1.0f0, 0.0f0), 45.0f0, 1.0f0, screen_size...)

generate_render_and_save(cam, light, "teapot_front.jpg")

