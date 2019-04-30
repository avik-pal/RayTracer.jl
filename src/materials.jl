# ------ #
# Colors #
# ------ #

abstract type SurfaceColor end

# -------------- #
# - PlainColor - #
# -------------- #

struct PlainColor <: SurfaceColor
    color::Vec3
    PlainColor(c::Vec3{T}) where {T} = new(clamp(c, eltype(T)(0), eltype(T)(1)))
    PlainColor() = new(Vec3(0.0f0))
end

@diffops PlainColor

diffusecolor(c::PlainColor, pt::Vec3) = c.color

# -------------------- #
# - CheckeredSurface - #
# -------------------- #

struct CheckeredSurface <: SurfaceColor
    color1::Vec3
    color2::Vec3
    CheckeredSurface(c1::Vec3{T1}, c2::Vec3{T2}) where {T1, T2} = new(clamp(c1, eltype(T1)(0), eltype(T1)(1)),
                                                                      clamp(c2, eltype(T2)(0), eltype(T2)(1)))
    CheckeredSurface() = new(Vec3(0.0f0), Vec3(0.0f0))
end

@diffops CheckeredSurface

function diffusecolor(c::CheckeredSurface, pt::Vec3)
    checker = (Int.(floor.(abs.(pt.x .* 2.0f0))) .% 2) .==
              (Int.(floor.(abs.(pt.z .* 2.0f0))) .% 2)
    return c.color1 * checker + c.color2 * (1.0f0 .- checker)
end

# --------- #
# Materials #
# --------- #

# NOTE: For calculating the gradient of reflection it has to be an array
struct Material{S<:SurfaceColor, R<:Real}
    color::S
    reflection::R
end

@diffops Material

diffusecolor(m::Material, pt::Vec3) = diffusecolor(m.color, pt)

