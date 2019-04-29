# This file illustrates the simulation of Chua system.

using JuSDL
import JuSDL.Plugins.Fft
using Plots

# Construct the components
q(x, a=-1.143, b=-0.714) = b*x + 1 / 2 * (a - b) * (abs(x + 1) - abs(x - 1)) 
function f(dx, x, u, t, alpha=15.6, beta=28, q=q)
    dx[1] = alpha * (x[2] - x[1] - q(x[1]))
    dx[2] = x[1] - x[2] + x[3]
    dx[3] = -beta * x[2]
end
function h(dx, x, u, t, eta=0.05)
    dx[1] = -eta
    dx[2] = eta
    dx[3] = 0
end
g(x, u, t) = [x[1], x[2], x[3]]
x0 = [1e-6, 1e-6, 1e-6]
t = 0.
sdeds = SDESystem((f, h), g, x0, t)
writer = Writer(Bus(3), buflen=5000, plugin=nothing)
clk = Clock(0., 0.005, 100.)

# Connect the components
connect(sdeds.output, writer.input)

# Construct the model 
model = Model(sdeds, writer, clk=clk)

# Simulate the model 
sim = simulate(model)

# Read back the simulation data.
content = read(writer)

# PLot the simulation data.
plt1 = plot()
for (i, k) in enumerate(keys(content))
    plot!(k, content[k][:, 1], label=string(i))
end
plt2 = plot()
for (i, k) in enumerate(keys(content))
    plot!(content[k][:, 1], content[k][:, 2], label=string(i))
end