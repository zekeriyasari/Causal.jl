# This file illustrates the plugin for calculation of mean of data
using Statistics 

struct Mean <: AbstractPlugin
    dims::Int
end
Mean(;dims=1) = Mean(dims)

process(plg::Mean, x) = mean(x, dims=plg.dims)

