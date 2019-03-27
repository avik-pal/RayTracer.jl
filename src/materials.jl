# Colors

abstract type SurfaceColor end

struct PlainColor <: SurfaceColor
    color::Vec3
end

diffusecolor(c::PlainColor, pt::Vec3) = c.color

struct CheckeredSurface <: SurfaceColor
    color1::Vec3
    color2::Vec3
end

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

diffusecolor(m::Material, pt::Vec3) =
    diffusecolor(m.color, pt)

