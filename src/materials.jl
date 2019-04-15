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

# Addition does not make much sense here but is needed for gradient accumulation
p1::PlainColor + p2::PlainColor = PlainColor(p1.color + p2.color)

diffusecolor(c::PlainColor, pt::Vec3) = c.color

# -------------------- #
# - CheckeredSurface - #
# -------------------- #

struct CheckeredSurface <: SurfaceColor
    color1::Vec3
    color2::Vec3
    CheckeredSphere(c1::Vec3{T1}, c2::Vec3{T2}) where {T1, T2} = new(clamp(c1, eltype(T1)(0), eltype(T1)(1)),
                                                                     clamp(c2, eltype(T2)(0), eltype(T2)(1)))
    CheckeredSurface() = new(Vec3(0.0f0), Vec3(0.0f0))
end

c1::CheckeredSurface + c2::CheckeredSurface = CheckeredSurface(c1.color1 + c2.color1,
                                                               c1.color2 + c2.color2)

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

m1::Material + m2::Material = Material(m1.color + m2.color, m1.reflection + m2.reflection)

diffusecolor(m::Material, pt::Vec3) = diffusecolor(m.color, pt)

