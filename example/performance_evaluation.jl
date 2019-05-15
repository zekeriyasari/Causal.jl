# This file illustrates the simulation of Chua system.

using JuSDL

# Construct the components
gamma(x, a=-1.143, b=-0.714) = b*x + 1 / 2 * (a - b) * (abs(x + 1) - abs(x - 1)) 
function f(dx, x, u, t, alpha=15.6, beta=28, gamma=gamma)
    dx[1] = alpha * (x[2] - x[1] - gamma(x[1]))
    dx[2] = x[1] - x[2] + x[3]
    dx[3] = -beta * x[2]
end
function h(dx, x, u, t, eta=0.1)
    dx[1] = -eta
    dx[2] = eta
    dx[3] = 0
end
g(x, u, t) = [x[1], x[2], x[3]]
x0 = rand(3)*1e-3
t = 0.
# sdeds = SDESystem((f, h), g, x0, t)
sdeds = ODESystem(f, g, x0, t)
term = Terminator(Bus(length(sdeds.output)))
clk = Clock(0., 0.01, 100.)

# Connect the components
connect(sdeds.output, term.input)

# Construct the model 
model = Model(sdeds, term, clk=clk)

# Simulate the model 
sim = simulate(model);

# # Read back the simulation data.
# content = read(writer)

# # PLot the simulation data.
# plt1 = plot(xlabel=L"$t$", ylabel=L"$x$", size=(500, 200), legend=:right)
# for (i, t) in enumerate(keys(content))
#     plot!(t, content[t][:, 1], label=string(i), lw=1.5)
# end
# plt2 = plot(xlabel=L"$x$", ylabel=L"$y$", size=(500, 200))
# for (i, t) in enumerate(keys(content))
#     plot!(content[t][:, 1], content[t][:, 2], label=string(i), lw=1.5)
# end