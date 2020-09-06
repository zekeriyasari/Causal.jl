# This file illustrates the plugin for calculation of mean of data
using Statistics 

"""
    Mean(dims::Int)

Constructs a `Mean` plugin. The [`process(plg::Mean, x)`](@ref) function takes the mean of the input data `x` along dimension `dims`.
"""
struct Mean <: AbstractPlugin
    dims::Int
end
Mean(;dims::Int=1) = Mean(dims)

show(io::IO, plg::Mean) = print(io, "Mean(dims:$(plg.dims))")

"""
    process(plg::Mean, x)

Returns the means of `x` along the dimension `plg.dims`.

# Example
```julia
julia> x = collect(reshape(1:16, 4,4))
4×4 Array{Int64,2}:
 1  5   9  13
 2  6  10  14
 3  7  11  15
 4  8  12  16

julia> plg = Plugins.Mean(dims=1)
Mean(dims:1)

julia> process(plg, x)
1×4 Array{Float64,2}:
 2.5  6.5  10.5  14.5
```
"""
process(plg::Mean, x) = mean(x, dims=plg.dims)

