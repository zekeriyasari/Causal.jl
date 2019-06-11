# This file illustrates a simple simulation.

using JuSDL 

# Construct the components
clk = Clock(0., 0.01, 5000.)
gen = SinewaveGenerator()
ss = StaticSystem((u,t) -> [u[1], u[1], u[1]], Bus())
ds = LorenzSystem(sigma=16., beta=4, rho=45.92, outputfunc=(x,u,t)->x[1], 
    input=Bus(3))
sink1 = Printer(Bus(), buflen=5000, plugin=Plugins.Lyapunov(ts=clk.dt, m=15, J=11))
sink2 = Scope(Bus(), buflen=1000, plugin=nothing)

# Connect the components
connect(gen.output, ss.input)
connect(ss.output, ds.input)
connect(ds.output, sink1.input)
connect(gen.output, sink2.input)

# Construct the model 
model = Model(gen, ss, ds, sink1, sink2, clk=clk)

# Simulate the model
sim = simulate(model)
