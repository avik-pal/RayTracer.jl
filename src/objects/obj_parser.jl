export load_obj

# ------------------------- #
# - Parse OBJ & MTL Files - #
# ------------------------- #

function triangulate_faces(vertices::Vector, texture_coordinates::Vector,
                           faces::Vector, material_map::Dict)
    scene = Vector{Triangle}()
    for face in faces
        for i in 2:(length(face[1]) - 1)
            if isnothing(face[2])
                uv_coordinates = nothing
            else
                uv_coordinates = [[texture_coordinates[face[2][1]]...],
                                  [texture_coordinates[face[2][i]]...],
                                  [texture_coordinates[face[2][i + 1]]...]]
            end
            mat = Material(;uv_coordinates = uv_coordinates,
                           material_map[face[3]]...)
            push!(scene, Triangle(deepcopy(vertices[face[1][1]]),
                                  deepcopy(vertices[face[1][i]]),
                                  deepcopy(vertices[face[1][i + 1]]),
                                  mat))
        end
    end
    try
        scene_stable = Vector{typeof(scene[1])}()
        for s in scene
            push!(scene_stable, s)
        end
        return scene_stable
    catch e
        # If all the triangles are not of the same type return the non-infered
        # version of the scene. In this case type inference for `raytrace` will
        # also fail
        @warn "Could not convert the triangles to the same type. Type inference for raytrace will fail"
        return scene
    end
end

function parse_mtllib!(file, material_map, outtype)
    color_diffuse = Vec3(outtype(1.0f0))
    color_ambient = Vec3(outtype(1.0f0))
    color_specular = Vec3(outtype(1.0f0))
    specular_exponent = outtype(50.0f0)
    reflection = outtype(0.5f0)
    texture_ambient = nothing
    texture_diffuse = nothing
    texture_specular = nothing
    last_mat = "RayTracer Default"
    if isnothing(file)
        material_map[last_mat] = (color_diffuse = color_diffuse,
                                  color_ambient = color_ambient,
                                  color_specular = color_specular,
                                  specular_exponent = specular_exponent,
                                  reflection = reflection,
                                  texture_ambient = texture_ambient,
                                  texture_diffuse = texture_diffuse,
                                  texture_specular = texture_specular)
        return nothing
    end
    for line in eachline(file)
        wrds = split(line)
        isempty(wrds) && continue
        if wrds[1] == "newmtl"
            material_map[last_mat] = (color_diffuse = color_diffuse,
                                      color_ambient = color_ambient,
                                      color_specular = color_specular,
                                      specular_exponent = specular_exponent,
                                      reflection = reflection,
                                      texture_ambient = texture_ambient,
                                      texture_diffuse = texture_diffuse,
                                      texture_specular = texture_specular)
            last_mat = wrds[2]
            # In case any of these values are not defined for the material
            # we shall use the default values
            color_diffuse = Vec3(outtype(1.0f0))
            color_ambient = Vec3(outtype(1.0f0))
            color_specular = Vec3(outtype(1.0f0))
            specular_exponent = outtype(50.0f0)
            reflection = outtype(0.5f0)
            texture_ambient = nothing
            texture_diffuse = nothing
            texture_specular = nothing
        elseif wrds[1] == "Ka"
            color_ambient = Vec3(parse.(outtype, wrds[2:4])...)
        elseif wrds[1] == "Kd"
            color_diffuse = Vec3(parse.(outtype, wrds[2:4])...)
        elseif wrds[1] == "Ks"
            color_specular = Vec3(parse.(outtype, wrds[2:4])...)
        elseif wrds[1] == "Ns"
            specular_exponent = parse(outtype, wrds[2])
        elseif wrds[1] == "d"
            reflection = parse(outtype, wrds[2])
        elseif wrds[1] == "Tr"
            reflection = 1 - parse(outtype, wrds[2])
        elseif wrds[1] == "map_Ka"
            texture_file = "$(rsplit(file, '/', limit = 2)[1])/$(wrds[2])"
            texture_ambient = Vec3([outtype.(permutedims(channelview(load(texture_file)),
                                                         (3, 2, 1)))[:,end:-1:1,i]
                                    for i in 1:3]...)
        elseif wrds[1] == "map_Kd"
            texture_file = "$(rsplit(file, '/', limit = 2)[1])/$(wrds[2])"
            texture_diffuse = Vec3([outtype.(permutedims(channelview(load(texture_file)),
                                                         (3, 2, 1)))[:,end:-1:1,i]
                                    for i in 1:3]...)
        elseif wrds[1] == "map_Ks"
            texture_file = "$(rsplit(file, '/', limit = 2)[1])/$(wrds[2])"
            texture_specular = Vec3([outtype.(permutedims(channelview(load(texture_file)),
                                                          (3, 2, 1)))[:,end:-1:1,i]
                                     for i in 1:3]...)
        end
    end
    material_map[last_mat] = (color_diffuse = color_diffuse,
                              color_ambient = color_ambient,
                              color_specular = color_specular,
                              specular_exponent = specular_exponent,
                              texture_ambient = texture_ambient,
                              texture_diffuse = texture_diffuse,
                              texture_specular = texture_specular)
    return nothing
end

function load_obj(file; outtype = Float32)
    vertices = Vector{Vec3{Vector{outtype}}}()
    texture_coordinates = Vector{Tuple}()
    normals = Vector{Vec3{Vector{outtype}}}()
    faces = Vector{Tuple{Vector{Int}, Union{Vector{Int}, Nothing}, String}}()
    material_map = Dict{String, Union{NamedTuple, Nothing}}()
    last_mat = "RayTracer Default"
    mtllib = nothing
    for line in eachline(file)
        wrds = split(line)
        isempty(wrds) && continue
        if wrds[1] == "v" # Vertices
            push!(vertices, Vec3(parse.(outtype, wrds[2:4])...))
        elseif wrds[1] == "vt" # Texture Coordinates
            push!(texture_coordinates, tuple(parse.(outtype, wrds[2:3])...))
        elseif wrds[1] == "vn" # Normal
            push!(normals, Vec3(parse.(outtype, wrds[2:4])...))
        elseif wrds[1] == "f" # Faces
            # Currently we shall only be concerned with the vertices of the face
            # and safely throw away vertex normal information
            fstwrd = split(wrds[2], '/')
            texture_c = isempty(fstwrd[2]) ? nothing : [parse(Int, fstwrd[2])]
            @assert length(fstwrd) == 3 "Incorrect number of /'s in the obj file"
            push!(faces, ([parse(Int, fstwrd[1])], texture_c, last_mat))
            for wrd in wrds[3:end]
                splitwrd = split(wrd, '/')
                @assert length(splitwrd) == 3 "Incorrect number of /'s in the obj file"
                push!(faces[end][1], parse(Int, splitwrd[1]))
                !isnothing(texture_c) && push!(faces[end][2], parse(Int, splitwrd[2]))
            end
        elseif wrds[1] == "usemtl" # Key for parsing mtllib file
            last_mat = wrds[2]
            material_map[last_mat] = nothing
        elseif wrds[1] == "mtllib" # Material file
            mtllib = "$(rsplit(file, '/', limit = 2)[1])/$(wrds[2])"
        end
    end
    
    if !isnothing(mtllib)
        parse_mtllib!(mtllib, material_map, outtype)
    else
        parse_mtllib!(nothing, material_map, outtype)
    end

    return triangulate_faces(vertices, texture_coordinates, faces, material_map)
end

