# This file illustrates the simulation of Chua system.

using JuSDL

# Define the Chua system 
function f(dx, x, u, t, sigma=10, beta=8/3, rho=28)
    dx[1] = sigma * (x[2] - x[1])
    dx[2] = x[1] * (rho - x[3]) - x[2]
    dx[3] = x[1] * x[2] - beta * x[3]
end
g(x, u, t) = x
x0 = [1e-6, 0, 0]
t = 0.
chua = DynamicSystems.DynamicSystem(f, g, x0, t)
