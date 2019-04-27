# This file illustrates a simple simulation.

# Load modules
using JuSDL.Connections
using JuSDL.Components
using JuSDL.Sinks
using JuSDL.Systems
using JuSDL.Models
using JuSDL.Plugins

# Construct the blocks
clk = Sources.Clock(0., 0.01, 5000.)
gen = Sources.SinewaveGenerator()
ss = Systems.StaticSystems.StaticSystem((u,t) -> [u[1], u[1], u[1]], Connections.Bus())
ds = Systems.DynamicSystems.LorenzSystem(sigma=16., beta=4, rho=45.92, outputfunc=(x,u,t)->x[1], 
    input=Connections.Bus(3))
sink1 = Sinks.Printer(Connections.Bus(), buflen=5000, plugin=Plugins.Lyapunov(ts=clk.dt, m=15, J=11))
sink2 = Sinks.Scope(Connections.Bus(), buflen=1000, plugin=nothing)

# Connect the blocks
Connections.connect(gen.output, ss.input)
Connections.connect(ss.output, ds.input)
Connections.connect(ds.output, sink1.input)
Connections.connect(gen.output, sink2.input)

# Construct the model 
model = Models.Model(gen, ss, ds, sink1, sink2, clk=clk)

# Simulate the model
sim = Models.simulate(model)
