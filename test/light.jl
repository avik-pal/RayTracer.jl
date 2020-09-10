using RayTracer, Flux

# Directional Lighting tests
dl = DirectionalLight(rand(3, 1), rand(3, 1), rand(3, 1), rand(3, 1))
normals = randn(3, 5, 10)
points = randn(3, 5, 10)
camera_positions = randn(3, 10)
specular_exponents = rand(10)


@inferred compute_diffuse_lighting(dl; normals = normals, points = points)

@inferred compute_specular_lighting(dl; normals = normals, points = points,
                                    camera_positions = camera_positions,
                                    specular_exponents = specular_exponents)

dl = dl |> gpu
normals = normals |> gpu
points = points |> gpu
camera_positions = camera_positions |> gpu
specular_exponents = specular_exponents |> gpu


@inferred compute_diffuse_lighting(dl; normals = normals, points = points)

@inferred compute_specular_lighting(dl; normals = normals, points = points,
                                    camera_positions = camera_positions,
                                    specular_exponents = specular_exponents)


# Point Lighting tests
pl = PointLight(rand(3, 1), rand(3, 1), rand(3, 1), rand(3, 1))
normals = randn(3, 5, 10)
points = randn(3, 5, 10)
camera_positions = randn(3, 10)
specular_exponents = rand(10)


@inferred compute_diffuse_lighting(pl; normals = normals, points = points)

@inferred compute_specular_lighting(pl; normals = normals, points = points,
                                    camera_positions = camera_positions,
                                    specular_exponents = specular_exponents)

pl = pl |> gpu
normals = normals |> gpu
points = points |> gpu
camera_positions = camera_positions |> gpu
specular_exponents = specular_exponents |> gpu


@inferred compute_diffuse_lighting(pl; normals = normals, points = points)

@inferred compute_specular_lighting(pl; normals = normals, points = points,
                                    camera_positions = camera_positions,
                                    specular_exponents = specular_exponents)