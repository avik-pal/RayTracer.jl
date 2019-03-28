# ------ #
# Colors #
# ------ #

abstract type SurfaceColor end

# ---------- #
# PlainColor #
# ---------- #

struct PlainColor <: SurfaceColor
    color::Vec3
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
end

c1::CheckeredSurface + c2::CheckeredSurface = CheckeredSurface(c1.color1 + c2.color1,
                                                               c1.color2 + c2.color2)

function diffusecolor(c::CheckeredSurface, pt::Vec3)
    checker = (Int.(floor.(abs.(pt.x .* 2.0f0))) .% 2) .==
              (Int.(floor.(abs.(pt.z .* 2.0f0))) .% 2)
    return c.color1 * checker + c.color2 * (1.0f0 .- checker)
end

# Materials

struct Material{S<:SurfaceColor, R<:AbstractFloat}
    color::S
    reflection::R
end                          

m1::Material + m2::Material = Material(m1.color + m2.color, m1.reflection + m2.reflection)

diffusecolor(m::Material, pt::Vec3) = diffusecolor(m.color, pt)

