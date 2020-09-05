# This file includes interpolant for interplation of sampled inputs. 

export Interpolant

"""
    $(TYPEDEF) 

Interpolant that interpolates the data in `timebuf` and `databuf`

# Fields 

    $(TYPEDFIELDS)
"""
mutable struct Interpolant{T1, T2, T3}
    timebuf::T1 
    databuf::T2
    itp::T3
    function Interpolant(timebuf, databuf) 
        T1, T2 = eltype(timebuf), eltype(databuf) 
        t = range(zero(T1), one(T1), length=3)
        itp = if T2 <: Real 
            u = zeros(T2, 3)
            CubicSplineInterpolation(t, u, extrapolation_bc=Line())
        else
            u = fill(zeros(eltype(T2), 3), length(databuf))
            map(row -> CubicSplineInterpolation(t, row, extrapolation_bc=Line()), eachcol(hcat(u...)))
        end
        new{typeof(timebuf), typeof(databuf), typeof(itp)}(timebuf, databuf, itp)
    end 
end 


# Syntax for u(t) 
(interp::Interpolant)(t) = interp.itp(t)

# Syntax for u[idx](t)
getindex(interp::Interpolant, idx::Vararg{Int, N}) where N = interp.itp[idx...]

perturb(u) = [u[1], u[1] .+ eps()]

torange(t) = range(t[1], t[end], length=length(t))

"""
    $(SIGNATURES)

Updates `interpolant` using the data in `timebuf` and `databuf` of `interpolant`.
"""
function update!(interp::Interpolant) 
    t = content(interp.timebuf)
    u = content(interp.databuf)
    length(t) == 1 && (t = perturb(t); u = perturb(u))
    interp.itp = getinterp(t, u)
    interp
end
getinterp(t, u::AbstractVector{<:Real}) = CubicSplineInterpolation(torange(t), u, extrapolation_bc=Line()) 
getinterp(t, u::AbstractVector{<:AbstractVector}) =  map(eachrow(hcat(u...))) do row 
        CubicSplineInterpolation(torange(t), row, extrapolation_bc=Line())
    end
