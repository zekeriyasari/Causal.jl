# This file includes the plugin for the calculation variance of data

using Statistics

struct Variance <: AbstractPlugin
    dims::Int
end
Variance(;dims=1) = Variance(dims)

process(plg::Variance, x) = var(x, dims=plg.dims)

