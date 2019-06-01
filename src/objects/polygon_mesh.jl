export load_obj

# ----------------- #
# - Triangle Mesh - #
# ----------------- #

# The idea behind this special object is to implement acceleration structures over it
# We shall not be supporting inverse rendering the exact coordinates for now.
# This is not difficult. We have to store the vertices and the faces and at every
# intersect call recompute everything, so we prefer to avoid this extra computation
# for now.
# The `intersections` store point to index of triangle mapping for getting the normals
mutable struct TriangleMesh <: Object
    triangulated_mesh::Vector{Triangle}
    intersections::IdDict
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
