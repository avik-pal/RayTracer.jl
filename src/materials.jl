export Material

# --------- #
# Materials #
# --------- #
struct Material{T<:AbstractArray, R<:AbstractVector}
    color_ambient::Vec3{T}
    color_diffuse::Vec3{T}
    color_specular::Vec3{T}
    specular_exponent::R
    reflection::R
end

Material(;color_ambient = Vec3(1.0f0), color_diffuse = Vec3(1.0f0),
         color_specular = Vec3(1.0f0), specular_exponent::Real = 50.0f0,
         reflection::Real = 0.5f0) =
    Material(color_ambient, color_diffuse, color_specular, [specular_exponent],
             [reflection])

@diffops Material

Base.zero(m::Material) = Material(zero(m.color_ambient), zero(m.color_diffuse),
                                  zero(m.color_specular), zero(m.specular_exponent),
                                  zero(m.reflection))

get_color(m::Material, pt::Vec3, sym::Val{:ambient}, obj) = m.color_ambient

get_color(m::Material, pt::Vec3, sym::Val{:diffuse}, obj) = m.color_diffuse

get_color(m::Material, pt::Vec3, sym::Val{:specular}, obj) = m.color_specular

specular_exponent(m::Material) = m.specular_exponent[]

reflection(m::Material) = m.reflection[]
