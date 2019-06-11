# ------ #
# Colors #
# ------ #

abstract type SurfaceColor end

# -------------- #
# - PlainColor - #
# -------------- #

mutable struct PlainColor{T} <: SurfaceColor
    color::Vec3{T}
    PlainColor(c::Vec3{T}) where {T} = new{T}(clamp(c, eltype(T)(0), eltype(T)(1)))
    PlainColor() = new{Vector{Float32}}(Vec3(0.0f0))
end

show(io::IO, pc::PlainColor) = print(io, "Plain Color - (", pc.color, ")")

@diffops PlainColor

diffusecolor(c::PlainColor, pt::Vec3) = c.color

# -------------------- #
# - CheckeredSurface - #
# -------------------- #

# FIXME: CheckeredSurface is not differentiable currently
mutable struct CheckeredSurface{T} <: SurfaceColor
    color1::Vec3{T}
    color2::Vec3{T}
    CheckeredSurface(c1::Vec3{T}, c2::Vec3{T}) where {T} =
        new{T}(clamp(c1, eltype(T)(0), eltype(T)(1)),
               clamp(c2, eltype(T)(0), eltype(T)(1)))
    CheckeredSurface() = new{Vector{Float32}}(Vec3(0.0f0), Vec3(0.0f0))
end                                                                

show(io::IO, cs::CheckeredSurface) = print(io, "Checkered Surface - (",
                                           cs.color1, ") + (", cs.color2, ")")

@diffops CheckeredSurface

# NOTE: We treat PlainColor as zero gradient for CheckeredSurface. We should define this
#       in a more general fashion for future.
cs::CheckeredSurface + ps::PlainColor = cs
cs::CheckeredSurface - ps::PlainColor = cs
ps::PlainColor + cs::CheckeredSurface = cs
ps::PlainColor - cs::CheckeredSurface = cs

function diffusecolor(c::CheckeredSurface, pt::Vec3)
    checker = (Int.(floor.(abs.(pt.x .* 2.0f0))) .% 2) .==
              (Int.(floor.(abs.(pt.z .* 2.0f0))) .% 2)
    return c.color1 * checker + c.color2 * (1.0f0 .- checker)
end

# --------- #
# Materials #
# --------- #

# NOTE: For calculating the gradient of reflection it has to be an array
mutable struct Material{S<:SurfaceColor, R<:Real}
    color::S
    reflection::R
end

show(io::IO, mat::Material) =
    print(io, "Material: ", mat.color, ", Reflection - ", mat.reflection)

@diffops Material

diffusecolor(m::Material, pt::Vec3) = diffusecolor(m.color, pt)

