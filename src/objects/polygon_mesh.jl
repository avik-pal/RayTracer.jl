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

function construct_outer_normals(t::Vector{Triangle})
    centroid = sum(map(x -> (x.v1 + x.v2 + x.v3) / 3, t)) / length(t)
    return map(x -> get_normal(x, Vec3(0.0f0), x.v1 - centroid), t)
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

