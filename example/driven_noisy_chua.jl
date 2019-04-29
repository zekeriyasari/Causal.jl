# This file illustrates the simulation of Chua system.

using JuSDL
import JuSDL.Plugins.Lyapunov
using Plots

# Construct clock.
clk = Clock(0., 0.005, 100.)

# Construct ode system 
q(x, a=-1.143, b=-0.714) = b*x + 1 / 2 * (a - b) * (abs(x + 1) - abs(x - 1)) 
function f1(dx, x, u, t, alpha=15.6, beta=28, q=q)
    dx[1] = alpha * (x[2] - x[1] - q(x[1]))
    dx[2] = x[1] - x[2] + x[3]
    dx[3] = -beta * x[2]
end
g1(x, u, t) = [x[1], x[2], x[3]]
x0 = rand(3) * 1e-6
t = 0.
odeds = ODESystem(f1, g1, x0, t)

# Construct sde system 
function f2(dx, x, u, t, alpha=15.6, beta=28, q=q)
    dx[1] = alpha * (x[2] - x[1] - q(x[1])) + u[1]
    dx[2] = x[1] - x[2] + x[3]
    dx[3] = -beta * x[2]
end
function h2(dx, x, u, t, eta=0.05)
    dx[1] = -eta
    dx[2] = eta
    dx[3] = 0
end
g2(x, u, t) = [x[1], x[2], x[3]]
x0 = rand(3) * 1e-6
t = 0.
sdeds = SDESystem((f2, h2), g2, x0, t, Bus(3))

# Construct gain
gain = Gain([0.01, 0., 0.])

# Construct sinks.
odewriter = Writer(Bus(3), buflen=5000, plugin=nothing)
odeprinter = Printer(Bus(1), buflen=5000, plugin=Lyapunov(ts=clk.dt, m=5, J=11))
sdewriter = Writer(Bus(3), buflen=5000, plugin=nothing)

# Connect the components
connect(odeds.output, gain.input)
connect(gain.output, sdeds.input)
connect(odeds.output, odewriter.input)
connect(odeds.output[1], odeprinter.input)
connect(sdeds.output, sdewriter.input)

# Construct the model 
model = Model(odeds, sdeds, gain, odewriter, odeprinter, sdewriter, clk=clk)

# Simulate the model 
sim = simulate(model);

# # Read back the simulation data.
# odecontent = read(odewriter)
# sdecontent = read(sdewriter)

# # PLot the simulation data.
# plt1 = plot()
# for (i, k) in enumerate(keys(odecontent))
#     plot!(odecontent[k][:, 1], odecontent[k][:, 2], label=string(i))
# end
# plt1
# plt2 = plot()
# for (i, k) in enumerate(keys(sdecontent))
#     plot!(sdecontent[k][:, 1], sdecontent[k][:, 2], label=string(i))
# end
# plt2