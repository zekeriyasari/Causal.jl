# This file includes the plugin for calculation of Lyapunov exponents.


using ChaosTools

"""
    $TYPEDEF 

Constructs a `Lyapunov` plugin. The [`process(plg::Lyapunov, x)`](@ref) function computes the maximum numerical Lyapunov
exponents. `m` is the reconstruction dimension, `J` is the amount of delay in reconstruction, `ni` is the number of steps
during transient steps and `ts` is the sampling time between samples of the input data `x`. See also:
(https://juliadynamics.github.io/DynamicalSystems.jl/latest/chaos/nlts/)

# FieldS 

    $TYPEDFIELDS
"""
struct Lyapunov <: AbstractPlugin
    "Dimension"
    m::Int
    "Delay amount"
    J::Int
    "Transient nmber"
    ni::Int
    "Samping sampling"
    ts::Float64
end
Lyapunov(;m::Int=15, J::Int=5, ni::Int=300, ts::Float64=0.01) = Lyapunov(m, J, ni, ts)

show(io::IO, plg::Lyapunov) = print(io, 
    "Lyapunov(embeddingdim:$(plg.m), numlags:$(plg.J), numiteration:$(plg.ni), samplingtime:$(plg.ts)")

"""
    $SIGNATURES

Computes the maximum Lyapunov exponent of the input data `x`. 

# Example
```julia 
julia> using Random 

julia> rng = MersenneTwister(1234);

julia> x = rand(rng, 1000);

julia> plg = Plugins.Lyapunov()
Lyapunov(embeddingdim:15, numlags:5, numiteration:300, samplingtime:0.01

julia> process(plg, x)
-0.42032928176193973
```
"""
function process(plg::Lyapunov, x)
    ndims(x) == 1 || (x = x[:])
    ntype = FixedMassNeighborhood(5)
    ks = 1 : 4 : plg.ni
    R = reconstruct(x, plg.m, plg.J)
    E = numericallyapunov(R, ks, ntype=ntype)
    val = linear_region(plg.ts .* ks, E)[2] 
    return val
end

# using NearestNeighbors using LinearAlgebra using Statistics using LsqFit import Base.log process(plg::Lyapunov, x) =
# lyapunov(x, plg.m, plg.J, plg.ni, plg.ts)[2]

# function reconstruct(x, m, J) N = length(x) M = N - (m - 1) * J X = zeros(m, M) for i = 1 : M data =  x[i : J : i + (m -
#     1)* J] X[:, i] = data end X end

# function knneighbours(X) tree = KDTree(X) [knn(tree, X[:, j], 2)[1][1] for j = 1 : size(X, 2)] end

# distance(Xj, Xjhat) = norm(Xj - Xjhat)

# Base.log(a::Vector) = log.(a)

# function lyapunov(x, m, J, ni, ts) X = reconstruct(x, m, J) M = size(X, 2) js = collect(1:M) jbars = knneighbours(X) m1 =
#     js .+ ni .<= M m2 = jbars .+ ni .<= M m = m1 .& m2 mjs = js[m] mjbars = jbars[m] y = mean(log.([distance.(eachcol(X[:,
#     j : j + ni]), eachcol(X[:, jbar : jbar + ni])) for (j, jbar) in zip(mjs, mjbars)])) / ts @. model(x, p) = p[1]*x ydata
#     = y[round(Int, length(y) * 0.25) : end]   # Discard first transient region and go to the linear region. lambda =
#     coef(curve_fit(model, collect(1:length(ydata)), ydata, rand(1)))[1] return y, lambda end
