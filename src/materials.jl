export Material

# --------- #
# Materials #
# --------- #
struct Material{T<:AbstractArray, R<:AbstractVector, U<:Union{Vec3, Nothing},
                V<:Union{Vec3, Nothing}, W<:Union{Vec3, Nothing},
                S<:Union{Vector{Tuple}, Nothing}}
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

get_color(m::Material{T, R, Nothing, V, W, S},
          pt::Vec3, sym::Val{:ambient}, obj) where {T, R, V, W, S} =
    m.color_ambient

get_color(m::Material{T, R, U, Nothing, W, S},
          pt::Vec3, sym::Val{:diffuse}, obj) where {T, R, U, W, S} =
    m.color_diffuse

get_color(m::Material{T, R, U, V, Nothing, S},
          pt::Vec3, sym::Val{:specular}, obj) where {T, R, U, V, S} =
    m.color_specular

specular_exponent(m::Material) = m.specular_exponent[]

reflection(m::Material) = m.reflection[]
