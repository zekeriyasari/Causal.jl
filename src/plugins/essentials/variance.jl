# This file includes the plugin for the calculation variance of data

using Statistics

"""
    $TYPEDEF

Constructs a `Variance` plugin. The [`process(plg::Variance, x)`](@ref) function takes the variance of the input data `x`
along dimension `dims`.

# Fields 

    $TYPEDFIELDS
"""
struct Variance <: AbstractPlugin
    "Dimension"
    dims::Int
end
Variance(;dims::Int=1) = Variance(dims)

show(io::IO, plg::Variance) = print(io, "Mean(dims:$(plg.dims))")

"""
    $SIGNATURES

Returns the standard deviation of `x` along the dimension `plg.dims`.

# Example 
```julia 
julia> x = collect(reshape(1:16, 4,4))
4×4 Array{Int64,2}:
 1  5   9  13
 2  6  10  14
 3  7  11  15
 4  8  12  16

julia> plg = Plugins.Variance(dims=1)
Mean(dims:1)

julia> process(plg, x)
1×4 Array{Float64,2}:
 1.66667  1.66667  1.66667  1.66667
```
"""
process(plg::Variance, x) = var(x, dims=plg.dims)

