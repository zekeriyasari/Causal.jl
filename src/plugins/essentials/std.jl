# This file includes the plugin for standard deviation of data

using Statistics 

struct Std <: AbstractPlugin
    dims::Int
end
Std(;dims=1) = Std(dims)

show(io::IO, plg::Std) = print(io, "Mean(dims:$(plg.dims))")

process(plg::Std, x) = std(x, dims=plg.dims)
