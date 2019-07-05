export BoundingVolumeHierarchy

abstract type AccelerationStructure end

struct BVHNode{T}
    x_min::T
    x_max::T
    y_min::T
    y_max::T
    z_min::T
    z_max::T
    index_start::Int
    index_end::Int
    left_child::Union{Nothing, BVHNode}
    right_child::Union{Nothing, BVHNode}
end

struct BoundingVolumeHierarchy{T, S} <: AccelerationStructure
    scene_list::Vector{T}
    root_node::BVHNode{S}
end

const BVH = BoundingVolumeHierarchy

function BoundingVolumeHierarchy(scene::Vector)
    x_min, x_max = extrema(hcat([[s.v1.x[], s.v2.x[], s.v3.x[]] for s in scene]...))
    y_min, y_max = extrema(hcat([[s.v1.y[], s.v2.y[], s.v3.y[]] for s in scene]...))
    z_min, z_max = extrema(hcat([[s.v1.z[], s.v2.z[], s.v3.z[]] for s in scene]...))

    longest_direction = getindex([:x, :y, :z], 
                                 argmax([x_max - x_min, y_max - y_min, z_max - z_min]))

    centroids = map(t -> (t.v1 + t.v2 + t.v3) / 3, scene)

    centroid_dict = IdDict{eltype(scene), Vec3}()
    for (s, c) in zip(scene, centroids)
        centroid_dict[s] = c
    end

    scene = sort(scene, by = x -> getproperty(centroid_dict[x], longest_direction)[])

    search_space = map(x -> getproperty(x, longest_direction)[], centroids)
    split_value = mean(search_space)
    split_index = searchsortedfirst(search_space, split_value)

    left_child = BVHNode(scene[1:split_index - 1], 1, centroid_dict)

    right_child = BVHNode(scene[split_index:end], split_index, centroid_dict)

    bvhnode = BVHNode(x_min, x_max, y_min, y_max, z_min, z_max, 1, length(scene),
                      left_child, right_child)

    return BoundingVolumeHierarchy(scene, bvhnode)
end

function BVHNode(scene, index, centroid_dict)
    length(scene) == 0 && return nothing

    x_min, x_max = extrema(hcat([[s.v1.x[], s.v2.x[], s.v3.x[]] for s in scene]...))
    y_min, y_max = extrema(hcat([[s.v1.y[], s.v2.y[], s.v3.y[]] for s in scene]...))
    z_min, z_max = extrema(hcat([[s.v1.z[], s.v2.z[], s.v3.z[]] for s in scene]...))
    
    longest_direction = getindex([:x, :y, :z], 
                                 argmax([x_max - x_min, y_max - y_min, z_max - z_min]))

    scene = sort(scene, by = x -> getproperty(centroid_dict[x], longest_direction)[])
    
    centroids = [centroid_dict[s] for s in scene]

    search_space = map(x -> getproperty(x, longest_direction)[], centroids)
    split_value = mean(search_space)
    split_index = searchsortedfirst(search_space, split_value)

    if split_index - 1 == length(scene) || split_index == 1
        return BVHNode(x_min, x_max, y_min, y_max, z_min, z_max, index, index + length(scene) - 1,
                       nothing, nothing)
    end 

    left_child = BVHNode(scene[1:split_index - 1], index, centroid_dict)

    right_child = BVHNode(scene[split_index:end], index + split_index - 1, centroid_dict)
    
    bvhnode = BVHNode(x_min, x_max, y_min, y_max, z_min, z_max, index, index + length(scene) - 1,
                      left_child, right_child)

    return bvhnode
end

bvh_depth(bvh::BoundingVolumeHierarchy) = bvh_depth(bvh.root_node)

bvh_depth(bvh::BVHNode) = 1 + max(bvh_depth(bvh.left_child), bvh_depth(bvh.right_child))

bvh_depth(::Nothing) = 0

isleafnode(bvh::BVHNode) = isnothing(bvh.left_child) && isnothing(bvh.right_child)

function intersection_check(bvh::BVHNode, origin, direction)
    function check_intersection_ray(dir_x, dir_y, dir_z,
                                    ori_x, ori_y, ori_z)
        if dir_x < 0
            tmin = (bvh.x_max - ori_x) / dir_x
            tmax = (bvh.x_min - ori_x) / dir_x
         else
            tmin = (bvh.x_min - ori_x) / dir_x
            tmax = (bvh.x_max - ori_x) / dir_x
        end
        if dir_y < 0
            tymin = (bvh.y_max - ori_y) / dir_y
            tymax = (bvh.y_min - ori_y) / dir_y
        else
            tymin = (bvh.y_min - ori_y) / dir_y
            tymax = (bvh.y_max - ori_y) / dir_y
        end
        (tmin > tymax || tymin > tmax) && return false
        tmin = max(tmin, tymin)
        tmax = min(tmax, tymax)
        if dir_z < 0
            tzmin = (bvh.z_max - ori_z) / dir_z
            tzmax = (bvh.z_min - ori_z) / dir_z
        else
            tzmin = (bvh.z_min - ori_z) / dir_z
            tzmax = (bvh.z_max - ori_z) / dir_z
        end
        # Equivalent to
        # (tmin > tzmax || tzmin > tmax) && return false
        # return true
        return (tmin < tzmax && tzmin < tmax)
    end

    return broadcast(check_intersection_ray, direction.x, direction.y,
                     direction.z, origin.x, origin.y, origin.z)
end

intersect(bvh::BoundingVolumeHierarchy, origin, direction) =
    intersect(bvh.root_node, bvh, origin, direction)

function intersect(bvh::BVHNode, bvh_structure::BoundingVolumeHierarchy,
                   origin, direction)
    hit = intersection_check(bvh, origin, direction)
    dir_rays = extract(hit, direction)
    ori_rays = extract(hit, origin)
    if isleafnode(bvh)
        t_values = IdDict{Triangle, Vector}(
                       map(x -> (x, intersect(x, ori_rays, dir_rays)),
                           bvh_structure.scene_list[bvh.index_start:bvh.index_end]))
    else
        t_values = intersect(bvh.left_child, bvh_structure, ori_rays, dir_rays)
        # We do not need to check the ones which have already intersected but let's
        # keep the code simple for now
        if !isnothing(bvh.right_child)
            merge!(t_values, intersect(bvh.right_child, bvh_structure, ori_rays, dir_rays))
        end
    end
    for k in keys(t_values)
        t_values[k] = place(t_values[k], hit, Inf)
    end
    return t_values
end
