# This file includes the plugin for calculation of fast fourier transform of data
using FFTW

"""
    Fft(dims::Int)

Constructs an `Fft` plugin. The  [`process(plg::Fft, x)`](@ref) function performes an `fft` operatinon along `dims` of `x`. See also: [`fft`](https://juliamath.github.io/AbstractFFTs.jl/stable/api/#AbstractFFTs.fft)
"""
struct Fft <: AbstractPlugin 
    dims::Int
end 
Fft(;dims::Int=1) = Fft(dims)

show(io::IO, plg::Fft) = print(io, "Fft(dims:$(plg.dims))")

"""
    process(plg::Fft, x)

Performes an `fft` transformation for the input data `x`.

# Example
```jldoctest 
julia> x = collect(reshape(1:16, 4,4))
4×4 Array{Int64,2}:
 1  5   9  13
 2  6  10  14
 3  7  11  15
 4  8  12  16

julia> plg = Plugins.Fft(dims=1)
Fft(dims:1)

julia> process(plg, x)
4×4 Array{Complex{Float64},2}:
 10.0+0.0im  26.0+0.0im  42.0+0.0im  58.0+0.0im
 -2.0+2.0im  -2.0+2.0im  -2.0+2.0im  -2.0+2.0im
 -2.0+0.0im  -2.0+0.0im  -2.0+0.0im  -2.0+0.0im
 -2.0-2.0im  -2.0-2.0im  -2.0-2.0im  -2.0-2.0im
```
"""
process(plg::Fft, x) = fft(x, plg.dims)
