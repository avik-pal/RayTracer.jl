export load_obj, TriangleMesh

# ------------ #
# - Load OBJ - #
# ------------ #

function triangulate_faces(vertices::Vector, faces::Vector)
    scene = Vector{Triangle}()
    for face in faces
        for i in 2:(length(face) - 1)
            push!(scene, Triangle(deepcopy(vertices[face[1]]),
                                  deepcopy(vertices[face[i]]),
                                  deepcopy(vertices[face[i + 1]])))
        end
    end
    return scene
end

function load_obj(file, outtype = Float32)
    vertices = Vector{Vec3{Vector{outtype}}}()
    texture_coordinates = Vector{Tuple}()
    normals = Vector{Vec3{Vector{outtype}}}()
    faces = Vector{Vector{Int}}()
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
            push!(faces, parse.(Int, first.(split.(wrds[2:end], '/', limit = 2))))
        end
    end
    return triangulate_faces(vertices, faces)
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
mutable struct FixedTriangleMeshParams{V} <: FixedParams
    intersections::IdDict
    normals::Vector{Vec3{V}}
end

mutable struct TriangleMesh{V, S, R} <: Object
    triangulated_mesh::Vector{Triangle{V, S, R}}
    material::Material{S, R}
    ftmp::FixedTriangleMeshParams{V}
end

@diffops TriangleMesh
            
TriangleMesh(scene::Vector{Triangle}, color = Vec3(0.5f0), reflection = 0.5f0) =
    TriangleMesh(scene, Material(PlainColor(color), reflection),
                 FixedTriangleMeshParams(IdDict(), construct_outer_normals(scene)))

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

