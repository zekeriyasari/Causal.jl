# This file illustrates the simulation of Chua system.

using JuSDL
import JuSDL.Plugins.Lyapunov
using Plots
using LaTeXStrings

# Construct clock.
clk = Clock(0., 0.01, 250.)

# Construct ode system 
gamma(x, a=-8/7, b=-5/7) = b*x + 1 / 2 * (a - b) * (abs(x + 1) - abs(x - 1)) 
function f1(dx, x, u, t, alpha=15.6, beta=28, gamma=gamma)
    dx[1] = alpha * (x[2] - x[1] - gamma(x[1]))
    dx[2] = x[1] - x[2] + x[3]
    dx[3] = -beta * x[2]
end
g1(x, u, t) = [x[1], x[2], x[3]]
x0 = rand(3) * 1e-3
t = 0.
odeds = ODESystem(f1, g1, x0, t)

# Construct sde system 
function f2(dx, x, u, t, alpha=15.6, beta=28, gamma=gamma)
    dx[1] = alpha * (x[2] - x[1] - gamma(x[1])) + u[1]
    dx[2] = x[1] - x[2] + x[3]
    dx[3] = -beta * x[2]
end
function h2(dx, x, u, t, eta=0.1)
    dx[1] = -eta
    dx[2] = eta
    dx[3] = 0
end
g2(x, u, t) = [x[1], x[2], x[3]]
x0 = rand(3) * 1e-3
t = 0.
sdeds = SDESystem((f2, h2), g2, x0, t, Bus(3))

# Construct gain
gain = Gain([0.01, 0., 0.])

# Construct sinks.
writer1 = Writer(Bus(3), buflen=5000, plugin=nothing)
writer2 = Writer(Bus(3), buflen=5000, plugin=nothing)
writer3 = Writer(Bus(1), buflen=5000, plugin=Lyapunov(ts=clk.dt, m=7, J=11, ni=200))

# Connect the components
connect(odeds.output, gain.input)
connect(gain.output, sdeds.input)
connect(odeds.output, writer1.input)
connect(odeds.output[1], writer3.input)
connect(sdeds.output, writer2.input)

# Construct the model 
model = Model(odeds, sdeds, gain, writer1, writer3, writer2, clk=clk)

# Simulate the model 
sim = simulate(model);

# Read back the simulation data.
writer1content = read(writer1)
writer2content = read(writer2)
writer3content = read(writer3)

# PLot the simulation data.
plt1 = plot(xlabel=L"$x$", ylabel=L"$y$", size=(500, 200))
for (i, t) in enumerate(keys(writer1content))
    plot!(writer1content[t][:, 1], writer1content[t][:, 2], label=string(i), lw=1.5)
end
plt1
plt2 = plot(xlabel=L"$x$", ylabel=L"$y$", size=(500, 200))
for (i, t) in enumerate(keys(writer2content))
    plot!(writer2content[t][:, 1], writer2content[t][:, 2], label=string(i), lw=1.5)
end
plt2
for (i, t) in enumerate(keys(writer3content))
    println(writer3content[t])
end