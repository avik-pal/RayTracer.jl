import Base: +, *, -, /, %, intersect

# -------- #
# Vector 3 #
# -------- #

# Making the fields arrays allow us to collect gradients for them
struct Vec3{T<:AbstractArray}
    x::T
    y::T
    z::T
    function Vec3(x::T, y::T, z::T) where {T<:AbstractArray}
        @assert size(x) == size(y) == size(z)
        new{T}(x, y, z)
    end
    function Vec3(x::T1, y::T2, z::T3) where {T1<:AbstractArray, T2<:AbstractArray, T3<:AbstractArray}
        # Yes, I know it is a terrible hack but Zygote.FillArray was pissing me off.
        T = eltype(x) <: Real ? eltype(x) : eltype(y) <: Real ? eltype(y) : eltype(z)
        @warn "Converting the type to $(T) by default" maxlog=1
        @assert size(x) == size(y) == size(z)
        new{AbstractArray{T, ndims(x)}}(T.(x), T.(y), T.(z))
    end
end    

Vec3(a::T) where {T<:Real} = Vec3([a], [a], [a])

Vec3(a::T) where {T<:AbstractArray} = Vec3(copy(a), copy(a), copy(a))

Vec3(a::T, b::T, c::T) where {T<:Real} = Vec3([a], [b], [c])

for op in (:+, :*, :-)
    @eval begin
        @inline function $(op)(a::Vec3, b::Vec3)
            return Vec3(broadcast($(op), a.x, b.x),
                        broadcast($(op), a.y, b.y),
                        broadcast($(op), a.z, b.z)) 
        end
    end
end

for op in (:+, :*, :-, :/, :%)
    @eval begin
        @inline function $(op)(a::Vec3, b)
            return Vec3(broadcast($(op), a.x, b),
                        broadcast($(op), a.y, b),
                        broadcast($(op), a.z, b))
        end
        
        @inline function $(op)(b, a::Vec3)
            return Vec3(broadcast($(op), a.x, b),
                        broadcast($(op), a.y, b),
                        broadcast($(op), a.z, b))
        end
    end
end

@inline -(a::Vec3) = Vec3(-a.x, -a.y, -a.z)

@inline dot(a::Vec3, b::Vec3) = a.x .* b.x .+ a.y .* b.y .+ a.z .* b.z

@inline l2norm(a::Vec3) = dot(a, a)

@inline normalize(a::Vec3) = a / sqrt.(l2norm(a))

@inline cross(a::Vec3, b::Vec3) =
    Vec3(a.y .* b.z .- a.z .* b.y, a.z .* b.x .- a.x .* b.z,
         a.x .* b.y .- a.y .* b.x)

function place(a::Vec3, cond)
    r = Vec3(zeros(eltype(a.x), size(cond)...),
             zeros(eltype(a.y), size(cond)...),
             zeros(eltype(a.z), size(cond)...))
    r.x[cond] .= a.x
    r.y[cond] .= a.y
    r.z[cond] .= a.z
    return r
end

Base.clamp(v::Vec3, lo, hi) = Vec3(clamp.(v.x, lo, hi), clamp.(v.y, lo, hi), clamp.(v.z, lo, hi))

for f in (:zero, :similar, :one)
    @eval begin
        Base.$(f)(v::Vec3) = Vec3($(f)(v.x), $(f)(v.y), $(f)(v.z))
    end
end


# ----- #
# Color #
# ----- #

rgb = Vec3

# ----- #
# Utils #
# ----- #

extract(cond, x::T) where {T<:Number} = x

extract(cond, x::T) where {T<:AbstractArray} = x[cond]

extract(cond, a::Vec3) = length(a.x) == 1 ? Vec3(a.x, a.y, a.z) : Vec3(a.x[cond], a.y[cond], a.z[cond])

bigmul(x::T) where {T} = typemax(x)

# ----------------- #
# - Helper Macros - #
# ----------------- #

macro diffops(a)
    quote
        # Addition for gradient accumulation
        function $(esc(:+))(x::$(esc(a)), y::$(esc(a)))
            return $(esc(a))([getfield(x, i) + getfield(y, i) for i in fieldnames($(esc(a)))]...)
        end
        # Subtraction for gradient updates
        function $(esc(:-))(x::$(esc(a)), y::$(esc(a)))
            return $(esc(a))([getfield(x, i) - getfield(y, i) for i in fieldnames($(esc(a)))]...)
        end
        # Multiply for learning rate and misc ops
        function $(esc(:*))(x::T, y::$(esc(a))) where {T<:Real}
            return $(esc(a))([x * getfield(y, i) for i in fieldnames($(esc(a)))]...)
        end
        function $(esc(:*))(x::$(esc(a)), y::T) where {T<:Real}
            return $(esc(a))([getfield(x, i) * y for i in fieldnames($(esc(a)))]...)
        end
        function $(esc(:*))(x::$(esc(a)), y::$(esc(a)))
            return $(esc(a))([getfield(x, i) * getfield(y, i) for i in fieldnames($(esc(a)))]...)
        end
    end
end
