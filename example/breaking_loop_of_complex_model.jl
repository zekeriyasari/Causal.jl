# This file includes the simulation of a model consisting an algrebraic loop with multiple inneighbor branches joinin an algrebraic loop.

using Causal 
using Plots

# Construct the model 
@defmodel model begin 
    @nodes begin 
        gen1 = SinewaveGenerator(frequency=2.)
        gain1 = Gain()
        adder1 = Adder(signs=(+,+))
        gen2 = SinewaveGenerator(frequency=3.)
        adder2 = Adder(signs=(+,+,-))
        gain2 = Gain()
        writer = Writer() 
        gain3 = Gain()
    end 
    @branches begin 
        gen1[1]     =>      gain1[1] 
        gain1[1]    =>      adder1[1]
        adder1[1]   =>      adder2[1]
        gen2[1]     =>      adder1[2]
        gen2[1]     =>      adder2[2]
        adder2[1]   =>      gain2[1]
        gain2[1]    =>      writer[1]
        gain2[1]    =>      gain3[1]
        gain3[1]    =>      adder2[3]
    end
end

simulate!(model)
t, x = read(getnode(model, :writer).component)
plot(t, x)
