export load_obj, TriangleMesh

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
            texture_ambient = Vec3([Float32.(permutedims(channelview(load(texture_file)),
                                                         (3, 2, 1)))[:,end:-1:1,i]
                                    for i in 1:3]...)
        elseif wrds[1] == "map_Kd"
            texture_file = "$(rsplit(file, '/', limit = 2)[1])/$(wrds[2])"
            texture_diffuse = Vec3([Float32.(permutedims(channelview(load(texture_file)),
                                                         (3, 2, 1)))[:,end:-1:1,i]
                                    for i in 1:3]...)
        elseif wrds[1] == "map_Ks"
            texture_file = "$(rsplit(file, '/', limit = 2)[1])/$(wrds[2])"
            texture_specular = Vec3([Float32.(permutedims(channelview(load(texture_file)),
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
    
    !isnothing(mtllib) && parse_mtllib!(mtllib, material_map, outtype)
    return triangulate_faces(vertices, texture_coordinates, faces, material_map)
end

function construct_outer_normals(t::Vector{Triangle})
    centroid = sum(map(x -> (x.v1 + x.v2 + x.v3) / 3, t)) / length(t)
    return map(x -> get_normal(x, Vec3(0.0f0), x.v1 - centroid), t)
end

# ----------------- #
# - Triangle Mesh - #
# ----------------- #

# The idea behind this special object is to implement acceleration structures over it
# We shall not be supporting inverse rendering the exact coordinates for now.
# This is not difficult. We have to store the vertices and the faces and at every
# intersect call recompute everything, so we prefer to avoid this extra computation
# for now.
# The `intersections` store point to index of triangle mapping for getting the normals
struct FixedTriangleMeshParams{V} <: FixedParams
    intersections::IdDict
    normals::Vector{Vec3{V}}
end

struct TriangleMesh{V, P, Q, R, S, T, U} <: Object
    triangulated_mesh::Vector{Triangle{V, P, Q, R, S, T, U}}
    material::Material{P, Q, R, S, T, U}
    ftmp::FixedTriangleMeshParams{V}
end

@diffops TriangleMesh
            
TriangleMesh(scene::Vector{Triangle}, mat::Material) =
    TriangleMesh(scene, mat, FixedTriangleMeshParams(IdDict(),
                                                     construct_outer_normals(scene)))

function intersect(t::TriangleMesh, origin, direction)
    distances = map(s -> intersect(s, origin, direction), t.triangulated_mesh)
    
    dist_reshaped = hcat(distances...)
    nearest = map(idx -> begin
                             val, index = findmin(dist_reshaped[idx, :], dims = 1)
                             t.ftmp.intersections[direction[idx]] = index
                             return val
                         end,
                  1:(size(dist_reshaped, 1)))

    return nearest
end

function get_normal(t::TriangleMesh, pt, dir)
    normal = zero(pt)
    for idx in 1:size(dir)[1]
        n = t.ftmp.normals[t.ftmp.intersections[dir[idx]]]
        normal.x[idx] = n.x[1]
        normal.y[idx] = n.y[1]
        normal.z[idx] = n.z[1]
    end
    return normal
end

