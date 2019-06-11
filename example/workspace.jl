# This file is just a dummy demo.

# The packages 
using JuSDL 
using Plots 

# The components 
gen = SinewaveGenerator(frequency=1/64)
scp = Scope(Bus())

# The connnections 
connect(gen.output, scp.input)

# The model 
model = Model(gen, scp, clk=Clock(0., 0.01, 1000.))

# The simulation 
sim = simulate(model)
