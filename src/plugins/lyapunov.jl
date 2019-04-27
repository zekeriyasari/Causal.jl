# This file includes the plugin for calculation of Lyapunov exponents.

using NearestNeighbors
using LinearAlgebra
using Statistics
using LsqFit
import Base.log

struct Lyapunov <: AbstractPlugin
    m::Int
    J::Int
    ni::Int
    ts::Float64
end
Lyapunov(;m=15, J=5, ni=300, ts=0.01) = Lyapunov(m, J, ni, ts)

process(plg::Lyapunov, x) = lyapunov(x, plg.m, plg.J, plg.ni, plg.ts)[2]

function reconstruct(x, m, J)
    N = length(x)
    M = N - (m - 1) * J
    X = zeros(m, M)
    for i = 1 : M
        data =  x[i : J : i + (m - 1)* J]
        X[:, i] = data
    end
    X
end

function knneighbours(X)
    tree = KDTree(X)
    [knn(tree, X[:, j], 2)[1][1] for j = 1 : size(X, 2)]
end

distance(Xj, Xjhat) = norm(Xj - Xjhat)

Base.log(a::Vector) = log.(a)

function lyapunov(x, m, J, ni, ts)
    X = reconstruct(x, m, J)
    M = size(X, 2)
    js = collect(1:M)
    jbars = knneighbours(X)
    m1 = js .+ ni .<= M
    m2 = jbars .+ ni .<= M
    m = m1 .& m2
    mjs = js[m]
    mjbars = jbars[m]
    y = mean(log.([distance.(eachcol(X[:, j : j + ni]), eachcol(X[:, jbar : jbar + ni])) 
        for (j, jbar) in zip(mjs, mjbars)])) / ts
    @. model(x, p) = p[1]*x
    ydata = y[round(Int, length(y) * 0.25) : end]   # Discard first transient region and go to the linear region.
    lambda = coef(curve_fit(model, collect(1:length(ydata)), ydata, rand(1)))[1]
    return y, lambda
end
