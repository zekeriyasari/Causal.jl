using Plots 
using GLM
using Random
using LinearAlgebra

function linearpredict(data, m)
    n = length(data)
    y = collect(data[m + 1 : n])
    phi = zeros(n - m, m)
    d = n - m - 1
    for (j, idx) in enumerate(m : -1 : 1)
        phi[:, j] = data[idx : idx + d]
    end
    theta = inv(phi' * phi) * phi' * y
    theta, phi, y
end

t = collect(0.: 0.1: 1.)
f(t) = t
x = f.(t)

m = 5
theta, phi, y = linearpredict(x, m)
fit(LinearModel, phi, y)

xest = dot(theta, x[end - m + 1 : 1: end])

tt = t[end] + 0.1
xt = f(tt)


p = scatter(t, x, label="")
scatter!([tt], [xt], label="", color=:blue)
scatter!([tt], [xest], label="", color=:green)
display(p)