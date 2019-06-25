export Material

# --------- #
# Materials #
# --------- #
"""
    Material

This Type stores information about the material of an [`Object`](@ref).
We compute the color of a point by dispatching on the type of the material.
That is why we store `nothing` when a particular field is absent.

!!! note
    `texture_*` and `uv_coordinates` fields are applicable only if the
    object used is a [`Triangle`](@ref). If any of the texture fields are
    present, `uv_coordinates` must be present.

### Fields:

* `color_ambient`     - The Ambient Color of the Material.
* `color_diffuse`     - The Diffuse Color of the Material.
* `color_specular`    - The Specular Color of the Material.
* `specular_exponent` - Specular Exponent of the Material.
* `reflection`        - The reflection coefficient of the material.
* `texture_ambient`   - Stores the ambient texture image (if present) in Vec3 format.
* `texture_diffuse`   - Stores the diffuse texture image (if present) in Vec3 format.
* `texture_specular`  - Stores the specular texture image (if present) in VEc3 format.
* `uv_coordinates`    - The uv coordinates are stored as a vector (of length 3) of tuples.

### Available Constructors

```
Material(;color_ambient = Vec3(1.0f0), color_diffuse = Vec3(1.0f0),
          color_specular = Vec3(1.0f0), specular_exponent::Real = 50.0f0,
          reflection::Real = 0.5f0, texture_ambient = nothing, 
          texture_diffuse = nothing, texture_specular = nothing,
          uv_coordinates = nothing)
```
"""
struct Material{T<:AbstractArray, R<:AbstractVector, U<:Union{Vec3, Nothing},
                V<:Union{Vec3, Nothing}, W<:Union{Vec3, Nothing},
                S<:Union{Vector, Nothing}}
    # Color Information
    color_ambient::Vec3{T}
    color_diffuse::Vec3{T}
    color_specular::Vec3{T}
    # Surface Properties
    specular_exponent::R
    reflection::R
    # Texture Information
    texture_ambient::U
    texture_diffuse::V
    texture_specular::W
    # UV coordinates (relevant only for triangles)
    uv_coordinates::S
end

Material(;color_ambient = Vec3(1.0f0), color_diffuse = Vec3(1.0f0),
          color_specular = Vec3(1.0f0), specular_exponent::Real = 50.0f0,
          reflection::Real = 0.5f0, texture_ambient = nothing, 
          texture_diffuse = nothing, texture_specular = nothing,
          uv_coordinates = nothing) =
    Material(color_ambient, color_diffuse, color_specular, [specular_exponent],
             [reflection], texture_ambient, texture_diffuse, texture_specular,
             uv_coordinates)

@diffops Material

function Base.zero(m::Material)
    texture_ambient = isnothing(m.texture_ambient) ? nothing : zero(m.texture_ambient)
    texture_diffuse = isnothing(m.texture_diffuse) ? nothing : zero(m.texture_diffuse)
    texture_specular = isnothing(m.texture_specular) ? nothing : zero(m.texture_specular)
    uv_coordinates = isnothing(m.uv_coordinates) ? nothing : zero.(m.uv_coordinates)
    return Material(zero(m.color_ambient), zero(m.color_diffuse), zero(m.color_specular),
                    zero(m.specular_exponent), zero(m.reflection), texture_ambient,
                    texture_diffuse, texture_specular, uv_coordinates)
end

"""
    get_color(m::Material, pt::Vec3, ::Val{T}, obj::Object)

Returns the color at the point `pt`. We use `T` and the type of the Material `m`
for efficiently dispatching to the right function. The right function is determined
by the presence/absence of the texture field. The possible values of `T` are
`:ambient`, `:diffuse`, and `:specular`.
"""
get_color(m::Material{T, R, Nothing, V, W, S}, pt::Vec3,
          ::Val{:ambient}, obj) where {T<:AbstractArray, R<:AbstractVector,
                                       V<:Union{Vec3, Nothing}, W<:Union{Vec3, Nothing},
                                       S<:Union{Vector, Nothing}} =
    m.color_ambient

get_color(m::Material{T, R, U, Nothing, W, S}, pt::Vec3,
          ::Val{:diffuse}, obj) where {T<:AbstractArray, R<:AbstractVector,
                                       U<:Union{Vec3, Nothing}, W<:Union{Vec3, Nothing},
                                       S<:Union{Vector, Nothing}} =
    m.color_diffuse

get_color(m::Material{T, R, U, V, Nothing, S}, pt::Vec3,
          ::Val{:specular}, obj) where {T<:AbstractArray, R<:AbstractVector,
                                        U<:Union{Vec3, Nothing}, V<:Union{Vec3, Nothing},
                                        S<:Union{Vector, Nothing}} =
    m.color_specular

# This function is only available for triangles. Maybe I should put a
# type constraint
# The three functions are present only for type inference. Ideally Julia
# should figure it out not sure why it is not the case.
function get_color(m::Material, pt::Vec3, ::Val{:ambient}, obj)
    v1v2 = obj.v2 - obj.v1
    v1v3 = obj.v3 - obj.v1
    normal = cross(v1v2, v1v3)
    denom = l2norm(normal)
    
    edge2 = obj.v3 - obj.v2
    vp2 = pt - obj.v2
    u_bary = dot(normal, cross(edge2, vp2)) ./ denom

    edge3 = obj.v1 - obj.v3
    vp3 = pt - obj.v3
    v_bary = dot(normal, cross(edge3, vp3)) ./ denom

    w_bary = 1 .- u_bary .- v_bary

    u = u_bary .* m.uv_coordinates[1][1] .+
        v_bary .* m.uv_coordinates[2][1] .+
        w_bary .* m.uv_coordinates[3][1]
    v = u_bary .* m.uv_coordinates[1][2] .+
        v_bary .* m.uv_coordinates[2][2] .+
        w_bary .* m.uv_coordinates[3][2]

    # which_texture, which_color = infer_index(f)
    image = Zygote.literal_getproperty(m, Val(:texture_ambient))
    width, height = size(image)
    x_val = mod1.((Int.(ceil.(u .* width)) .- 1), width)
    y_val = mod1.((Int.(ceil.(v .* height)) .- 1), height)
    # Zygote doesn't like me using a splat operation here :'(
    img = image[x_val .+ (y_val .- 1) .* stride(image.x, 2)]
    return Zygote.literal_getproperty(m, Val(:color_ambient)) * Vec3(img.x, img.y, img.z)
end

function get_color(m::Material, pt::Vec3, ::Val{:diffuse}, obj)
    v1v2 = obj.v2 - obj.v1
    v1v3 = obj.v3 - obj.v1
    normal = cross(v1v2, v1v3)
    denom = l2norm(normal)
    
    edge2 = obj.v3 - obj.v2
    vp2 = pt - obj.v2
    u_bary = dot(normal, cross(edge2, vp2)) ./ denom

    edge3 = obj.v1 - obj.v3
    vp3 = pt - obj.v3
    v_bary = dot(normal, cross(edge3, vp3)) ./ denom

    w_bary = 1 .- u_bary .- v_bary

    u = u_bary .* m.uv_coordinates[1][1] .+
        v_bary .* m.uv_coordinates[2][1] .+
        w_bary .* m.uv_coordinates[3][1]
    v = u_bary .* m.uv_coordinates[1][2] .+
        v_bary .* m.uv_coordinates[2][2] .+
        w_bary .* m.uv_coordinates[3][2]

    # which_texture, which_color = infer_index(f)
    image = Zygote.literal_getproperty(m, Val(:texture_diffuse))
    width, height = size(image)
    x_val = mod1.((Int.(ceil.(u .* width)) .- 1), width)
    y_val = mod1.((Int.(ceil.(v .* height)) .- 1), height)
    # Zygote doesn't like me using a splat operation here :'(
    img = image[x_val .+ (y_val .- 1) .* stride(image.x, 2)]
    return Zygote.literal_getproperty(m, Val(:color_diffuse)) * Vec3(img.x, img.y, img.z)
end

function get_color(m::Material, pt::Vec3, ::Val{:specular}, obj)
    v1v2 = obj.v2 - obj.v1
    v1v3 = obj.v3 - obj.v1
    normal = cross(v1v2, v1v3)
    denom = l2norm(normal)
    
    edge2 = obj.v3 - obj.v2
    vp2 = pt - obj.v2
    u_bary = dot(normal, cross(edge2, vp2)) ./ denom

    edge3 = obj.v1 - obj.v3
    vp3 = pt - obj.v3
    v_bary = dot(normal, cross(edge3, vp3)) ./ denom

    w_bary = 1 .- u_bary .- v_bary

    u = u_bary .* m.uv_coordinates[1][1] .+
        v_bary .* m.uv_coordinates[2][1] .+
        w_bary .* m.uv_coordinates[3][1]
    v = u_bary .* m.uv_coordinates[1][2] .+
        v_bary .* m.uv_coordinates[2][2] .+
        w_bary .* m.uv_coordinates[3][2]

    # which_texture, which_color = infer_index(f)
    image = Zygote.literal_getproperty(m, Val(:texture_specular))
    width, height = size(image)
    x_val = mod1.((Int.(ceil.(u .* width)) .- 1), width)
    y_val = mod1.((Int.(ceil.(v .* height)) .- 1), height)
    # Zygote doesn't like me using a splat operation here :'(
    img = image[x_val .+ (y_val .- 1) .* stride(image.x, 2)]
    return Zygote.literal_getproperty(m, Val(:color_specular)) * Vec3(img.x, img.y, img.z)
end

"""
    specular_exponent(m::Material)

Returns the `specular_exponent` of the Material `m`.
"""
specular_exponent(m::Material) = m.specular_exponent[]

"""
    reflection(m::Material)

Returns the `reflection coefficient` of the Material `m`.
"""
reflection(m::Material) = m.reflection[]
