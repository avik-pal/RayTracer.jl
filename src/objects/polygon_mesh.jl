export load_obj, TriangleMesh

# ------------ #
# - Load OBJ - #
# ------------ #

function triangulate_faces(vertices::Vector, faces::Vector, material_map::Dict)
    scene = Vector{Triangle}()
    for face in faces
        for i in 2:(length(face[1]) - 1)
            push!(scene, Triangle(deepcopy(vertices[face[1][1]]),
                                  deepcopy(vertices[face[1][i]]),
                                  deepcopy(vertices[face[1][i + 1]]),
                                  material_map[face[2]]))
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
        @warn e
        return scene
    end
end

function parse_mtllib!(file, material_map, outtype)
    color_diffuse = Vec3(outtype(1.0f0))
    color_ambient = Vec3(outtype(1.0f0))
    color_specular = Vec3(outtype(1.0f0))
    specular_exponent = outtype(50.0f0)
    reflection = outtype(0.5f0)
    last_mat = "RayTracer Default"
    for line in eachline(file)
        wrds = split(line)
        isempty(wrds) && continue
        if wrds[1] == "newmtl"
            material_map[last_mat] = Material(color_diffuse = color_diffuse,
                                              color_ambient = color_ambient,
                                              color_specular = color_specular,
                                              specular_exponent = specular_exponent,
                                              reflection = reflection)
            last_mat = wrds[2]
            # In case any of these values are not defined for the material
            # we shall use the default values
            color_diffuse = Vec3(outtype(1.0f0))
            color_ambient = Vec3(outtype(1.0f0))
            color_specular = Vec3(outtype(1.0f0))
            specular_exponent = outtype(50.0f0)
            reflection = outtype(0.5f0)
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
        end
    end
    material_map[last_mat] = Material(color_diffuse = color_diffuse,
                                      color_ambient = color_ambient,
                                      color_specular = color_specular,
                                      specular_exponent = specular_exponent,
                                      reflection = reflection)
    return nothing
end

function load_obj(file; mtllib = nothing, outtype = Float32)
    vertices = Vector{Vec3{Vector{outtype}}}()
    texture_coordinates = Vector{Tuple}()
    normals = Vector{Vec3{Vector{outtype}}}()
    faces = Vector{Tuple{Vector{Int}, String}}()
    material_map = Dict{String, Material}()
    last_mat = "RayTracer Default"
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
            # and safely throw away texture and normal information
            push!(faces, (parse.(Int, first.(split.(wrds[2:end], '/', limit = 2))), last_mat))
        elseif wrds[1] == "usemtl" # Key for parsing mtllib file
            last_mat = wrds[2]
            material_map[last_mat] = Material()
        end
    end
    !isnothing(mtllib) && parse_mtllib!(mtllib, material_map, outtype)
    return triangulate_faces(vertices, faces, material_map)
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

struct TriangleMesh{V, S, R} <: Object
    triangulated_mesh::Vector{Triangle{V, S, R}}
    material::Material{S, R}
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

