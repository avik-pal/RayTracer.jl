export BoundingVolumeHierarchy

"""
    AccelerationStructure

Base Type for all Acceleration Structures. These can be used to speed up
rendering by a significant amount. The main design behind an acceleration
structure should be such that it can be used as a simple replacement for
a vector of [`Object`](@ref)s.
"""                  
abstract type AccelerationStructure end

"""
    BVHNode

A node in the graph created from the scene list using [`BoundingVolumeHierarchy`](@ref).

### Fields:

* `x_min`       - Minimum x-value for the bounding box
* `x_max`       - Maximum x-value for the bounding box
* `y_min`       - Minimum y-value for the bounding box 
* `y_max`       - Maximum y-value for the bounding box 
* `z_min`       - Minimum z-value for the bounding box 
* `z_max`       - Maximum z-value for the bounding box 
* `index_start` - Starting triangle in the scene list
* `index_end`   - Last triangle in the scene list
* `left_child`  - Can be `nothing` or another [`BVHNode`](@ref)
* `right_child` - Can be `nothing` or another [`BVHNode`](@ref)
"""
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

"""
    BoundingVolumeHierarchy

An [`AccelerationStructure`](@ref) which constructs bounding boxes around
groups of triangles to speed up intersection checking. A detailed description
of ths technique is present [here](https://www.scratchapixel.com/lessons/advanced-rendering/introduction-acceleration-structure/bounding-volume-hierarchy-BVH-part1).

### Fields:

* `scene_list` - The scene list passed into the BVH constructor but in
                 sorted order
* `root_node`  - Root [`BVHNode`](@ref)

### Constructors:

* `BoundingVolumeHierarchy(scene::Vector)`

"""
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
    split_value = median(search_space)
    split_index = searchsortedfirst(search_space, split_value)
    
    if split_index - 1 == length(scene) || split_index == 1
        bvhnode = BVHNode(x_min, x_max, y_min, y_max, z_min, z_max, 1, length(scene),
                          nothing, nothing)
    else
        left_child, sc = BVHNode(scene[1:split_index - 1], 1, centroid_dict)
        scene[1:split_index - 1] .= sc
        right_child, sc = BVHNode(scene[split_index:end], split_index, centroid_dict)
        scene[split_index:end] .= sc
        bvhnode = BVHNode(x_min, x_max, y_min, y_max, z_min, z_max, 1, length(scene),
                          left_child, right_child)
    end
    return BoundingVolumeHierarchy(scene, bvhnode)
end

function BVHNode(scene, index, centroid_dict)
    length(scene) == 0 && return (nothing, scene)

    x_min, x_max = extrema(hcat([[s.v1.x[], s.v2.x[], s.v3.x[]] for s in scene]...))
    y_min, y_max = extrema(hcat([[s.v1.y[], s.v2.y[], s.v3.y[]] for s in scene]...))
    z_min, z_max = extrema(hcat([[s.v1.z[], s.v2.z[], s.v3.z[]] for s in scene]...))
    
    if length(scene) <= 100
        return BVHNode(x_min, x_max, y_min, y_max, z_min, z_max, index, index + length(scene) -1,
                       nothing, nothing), scene
    end
    
    longest_direction = getindex([:x, :y, :z], 
                                 argmax([x_max - x_min, y_max - y_min, z_max - z_min]))

    scene = sort(scene, by = x -> getproperty(centroid_dict[x], longest_direction)[])
    
    centroids = [centroid_dict[s] for s in scene]

    search_space = map(x -> getproperty(x, longest_direction)[], centroids)
    split_value = median(search_space)
    split_index = searchsortedfirst(search_space, split_value)

    if split_index - 1 == length(scene) || split_index == 1
        return BVHNode(x_min, x_max, y_min, y_max, z_min, z_max, index, index + length(scene) - 1,
                       nothing, nothing), scene
    end 

    left_child, sc = BVHNode(scene[1:split_index - 1], index, centroid_dict)
    scene[1:split_index - 1] .= sc

    right_child, sc = BVHNode(scene[split_index:end], index + split_index - 1, centroid_dict)
    scene[split_index:end] .= sc

    bvhnode = BVHNode(x_min, x_max, y_min, y_max, z_min, z_max, index, index + length(scene) - 1,
                      left_child, right_child)

    return bvhnode, scene
end

bvh_depth(bvh::BoundingVolumeHierarchy) = bvh_depth(bvh.root_node)

bvh_depth(bvh::BVHNode) = 1 + max(bvh_depth(bvh.left_child), bvh_depth(bvh.right_child))

bvh_depth(::Nothing) = 0

isleafnode(bvh::BVHNode) = isnothing(bvh.left_child) && isnothing(bvh.right_child)

function intersection_check(bvh::BVHNode, origin, direction)
    function check_intersection_ray(dir_x, dir_y, dir_z,
                                    ori_x, ori_y, ori_z)
        a, b = dir_x < 0 ? (bvh.x_max, bvh.x_min) : (bvh.x_min, bvh.x_max)
        tmin = (a - ori_x) / dir_x
        tmax = (b - ori_x) / dir_x
        a, b = dir_y < 0 ? (bvh.y_max, bvh.y_min) : (bvh.y_min, bvh.y_max)
        tymin = (a - ori_y) / dir_y
        tymax = (b - ori_y) / dir_y
        (tmin > tymax || tymin > tmax) && return false
        tmin = max(tmin, tymin)
        tmax = min(tmax, tymax)
        a, b = dir_z < 0 ? (bvh.z_max, bvh.z_min) : (bvh.z_min, bvh.z_max)
        tzmin = (a - ori_z) / dir_z
        tzmax = (b - ori_z) / dir_z
        (tmin > tzmax || tzmin > tmax) && return false
        return true
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
        # if !isnothing(bvh.right_child)
        merge!(t_values, intersect(bvh.right_child, bvh_structure, ori_rays, dir_rays))
        # end
    end
    for k in keys(t_values)
        t_values[k] = place(t_values[k], hit, Inf)
    end
    return t_values
end
