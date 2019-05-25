using DifferentialEquations
using Plots 

# Simulation Folded map
function foldedmap(dx, x, u, t, a=-0.1, b=-1.7)
    dx[1] = x[2] + a * x[1]
    dx[2] = b + x[1]^2
end

tspanfoldedmap = (0., 10000.)
x0foldedmap = [-0.5, -0.5]
probfoldedmap = DiscreteProblem(foldedmap, x0foldedmap, tspanfoldedmap)
solfoldedmap = solve(probfoldedmap)

scatter(hcat(solfoldedmap.u...)[1, :], hcat(solfoldedmap.u...)[2, :],  markersize = 0.1, label="")


# Simulation of Henonmap
function henonmap(dx, x, u, t, alpha=1.07, beta=0.3)
    dx[1] = -beta * x[2] + u[1]
    dx[2] = x[3] + 1 - alpha * x[2]^2 + u[2]
    dx[3] = beta * x[2] + x[1] + u[3]
end
tspanhenonmap = (0., 10000.)
x0henonmap = [-0.5, -0.5, -0.3]
probhenonmap = DiscreteProblem(henonmap, x0henonmap, tspanhenonmap, zeros(3))
solhenonmap = solve(probhenonmap)

scatter(hcat(solhenonmap.u...)[1, :], hcat(solhenonmap.u...)[2, :], hcat(solhenonmap.u...)[3, :], markersize = 0.1, label="")