# This file illustrates the plugin for calculation of mean of data
using Statistics 

struct Mean <: AbstractPlugin
    dims::Int
end
Mean(;dims::Int=1) = Mean(dims)

show(io::IO, plg::Mean) = print(io, "Mean(dims:$(plg.dims))")

process(plg::Mean, x) = mean(x, dims=plg.dims)

