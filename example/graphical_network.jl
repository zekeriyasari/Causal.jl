using Causal 
using Plots 

# Construct model 
ϵ =  10.
@defmodel model begin 
    @nodes begin 
        # Node 1
        adder1 = Adder(signs=(-, +), input=VectorInport(2))
        ds1 = ForcedLorenzSystem(input=VectorInport(), output=VectorOutport())
        mem1 = Memory(delay=0.01, initial=ds1.state)
        
        # Node 2
        adder2 = Adder(signs=(+, -), input=VectorInport(2))
        ds2 = ForcedLorenzSystem(input=VectorInport(), output=VectorOutport())
        mem2 = Memory(delay=0.01, initial=ds2.state)

        # Writer 
        writer = Writer(input=VectorInport(2)) 
    end 
    @branches begin 
        # Internal connections of Node 1
        adder1[1] => ds1[1]
        ds1[1] => mem1[1]

        # Internal connections of Node 2 
        adder2[1] => ds2[1]  
        ds2[1] => mem2[1]

        # Topological connections of the network
        mem1[1] => adder1[1]  
        mem2[1] => adder1[2]  
        mem1[1] => adder2[1]  
        mem2[1] => adder2[2]  

        # Connections for data recording.
        ds1[1] => writer[1] 
        ds2[1] => writer[2] 
    end 
end 

# Simulate model 
sim = simulate!(model, 0, 0.01, 100) 

# Plot simulation data 
t, x = read(getcomponent(model, :writer))
x1 = getindex.(x[1], 1)
x2 = getindex.(x[2], 1)
err = abs.(x1 - x2)
plt = plot(layout=(3,1))
plot!(t, x1, subplot=1) # ds1 waveform 
plot!(t, x2, subplot=2) # ds2 waveform 
plot!(t, err, subplot=3) # adder waveform 
