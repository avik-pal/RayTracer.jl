using RayTracer, Images, BenchmarkTools, ArgParse

function render(scene, screen_size, gillum)
    cam = Camera(
        Vec3(0.5f0, 0.2f0, -0.5f0),
        Vec3(0.0f0, 0.1f0,  0.0f0),
        Vec3(0.0f0, 1.0f0,  0.0f0),
        45.0f0,
        1.0f0,
        screen_size...
    )
    origin, direction = get_primary_rays(cam)
    light = PointLight(
        Vec3(1.0f0, 1.0f0, 1.0f0),
        2.0f8,
        Vec3(10.0f0, 10.0f0, 5.0f0)
    )
    image_packed = raytrace(
        origin,
        direction,
        scene,
        light,
        origin,
        gillum
    )
    return zeroonenorm(
               reshape(hcat(image_packed.x, image_packed.y, image_packed.z),
                      (3, screen_size...)))
end

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--mesh_path", "-m"
            help = "path to the mesh being rendered"
            arg_type = String
            required = true
        "--global_illumination", "-g"
            help = "Activate global illumination (>= 2 for no)"
            arg_type = Int
            default = 2
    end

    return parse_args(s)
end

function main()
    parsed_args = parse_commandline()
    println("Running Benchmarks for Mesh:\n
             1. Path to the Mesh - $(parsed_args["mesh_path"])\n
             2. Global Illumination - $(parsed_args["global_illumination"])")
    println("The benchmarking time involves the following:\n
             1. Instantiating the Camera\n
             2. Rendering\n
             3. Reshaping and Normalizing the Image")
    for screen_size in [(32, 32), (64, 64), (128, 128), (512, 512), (1024, 1024)]
        @info "Screen Size --> $screen_size"
        scene = load_obj(parsed_args["mesh_path"])
        print("Time without BVH --> ")
        @btime render($scene, $screen_size, $(parsed_args["global_illumination"]))
        bvh = BoundingVolumeHierarchy(scene)
        print("Time with BVH --> ")
        @btime render($bvh, $screen_size, $(parsed_args["global_illumination"]))
    end
    println("Benchmarking Completed")
end

main()
