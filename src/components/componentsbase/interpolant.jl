# This file includes interpolant for interplation of sampled inputs. 

import Base: size, getindex, setproperty!, show


"""
    Interpolant(tinit, tfinal, coefinit, coeffinal)

Constructs a linnear interpolant that interpolates between the poinsts `(tinit, coefinit)` and `(tfinal, coeffinal)`.
"""
mutable struct Interpolant{F}
    tinit::Float64 
    tfinal::Float64 
    coefinit::Vector{Float64}
    coeffinal::Vector{Float64}
    funcs::F 
    function Interpolant(tinit, tfinal, coefinit, coeffinal)
        funcs = map(fs -> interpolate(tinit, tfinal, fs...), zip(coefinit, coeffinal))
        new{typeof(funcs)}(tinit, tfinal, coefinit, coeffinal, funcs)
    end
end

show(io::IO, u::Interpolant)= print(io, 
    "Interpolant(tinit:$(u.tinit), tfinal:$(u.tfinal), coefinit:$(u.coefinit), coeffinal:$(u.coeffinal))")

# This `setproperty!` method is used to update internal interpolation functions just when the coefficients are updated.
function setproperty!(u::Interpolant, name::Symbol, val)
    setfield!(u, name, val)
    setfield!(u, :funcs, map(fs -> interpolate(u.tinit, u.tfinal, fs...), zip(u.coefinit, u.coeffinal)))
end

"""
    size(u::Interpolant)

Returns the size of interpolant of `u`.
"""
size(u::Interpolant) = size(u.coefinit)

"""
    getindex(u::Interpolant, idx::Int) 

Returns the interpolation function of `u` at index `idx`.

# Example 
```jldoctest 
julia> u = Interpolant(0., 1., [1., 2.], [3., 4.])
Interpolant(tinit:0.0, tfinal:1.0, coefinit:[1.0, 2.0], coeffinal:[3.0, 4.0])

julia> u[1](0.5)
2.0

julia> u[2](0.5)
3.0
```
"""
getindex(u::Interpolant, idx::Int) = u.funcs[idx]

# Return a single dimensional linnear interpolation function.s
interpolate(t0::Real, t1::Real, u0::Real, u1::Real) = 
    t -> t0 <= t <= t1 ? u0 + (t - t0) / (t1 - t0) * (u1 - u0) : error("Extrapolation is not allowed.")

