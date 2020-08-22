# This file simulates an opamp integrator circuit.

using Causal
using Plots 

freq = 5e3
T = 1 / freq
r = 10e3
c = 10e-9
τ = r * c

t0, dt, tf = 0, T/1000, 5T

@defmodel model begin 
    @nodes begin 
        gen = SquarewaveGenerator(high=0.5, low=-0.5, period=T)
        ds = ContinuousLinearSystem(A=fill(0., 1, 1), B=fill(1/τ, 1, 1), C=fill(-1., 1, 1), state=zeros(1))
        writerin = Writer()
        writerout = Writer()
    end
    @branches begin 
        gen     =>      ds 
        gen     =>      writerin 
        ds      =>      writerout
    end
end

sim = simulate!(model, t0, dt, tf)

t, u = read(getnode(model, :writerin).component)
t, y = read(getnode(model, :writerout).component)

p1 = plot(t, u)
    plot!(t, y)
display(p1)
