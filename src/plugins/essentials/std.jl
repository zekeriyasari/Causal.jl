# This file includes the plugin for standard deviation of data

using Statistics 

"""
    Std(dims::Int)

Constructs a `Std` plugin. The [`process(plg::Std, x)`](@ref) function takes the standard deviation of the input data `x` along dimension `dims`.
"""
struct Std <: AbstractPlugin
    dims::Int
end
Std(;dims::Int=1) = Std(dims)

show(io::IO, plg::Std) = print(io, "Mean(dims:$(plg.dims))")

"""
    process(plg::Std, x)

Returns the standard deviation of `x` along the dimension `plg.dims`.

# Example 
```julia 
julia> x = collect(reshape(1:16, 4,4))
4×4 Array{Int64,2}:
 1  5   9  13
 2  6  10  14
 3  7  11  15
 4  8  12  16

julia> plg = Plugins.Std(dims=1)
Mean(dims:1)

julia> process(plg, x)
1×4 Array{Float64,2}:
 1.29099  1.29099  1.29099  1.29099
```
"""
process(plg::Std, x) = std(x, dims=plg.dims)
