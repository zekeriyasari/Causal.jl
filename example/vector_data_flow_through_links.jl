# This file includes the simulation of a model in which vector data flows through the connections. 

using Causal 

# Define generator 
@def_source struct Mygen{RO, OP} <: AbstractSource
    readout::RO = t -> [sin(t), cos(t)]      # Returns vector data 
    output::OP = Outport{Vector{Float64}}()
end

# Define model 
@defmodel model begin 
    @nodes begin 
        gen = Mygen() 
        writer = Writer(input=Inport{Vector{Float64}}()) 
    end
    @branches begin 
        gen => writer 
    end
end 

# Simulate model 
simulate!(model, 0., 0.01, 1.)

# Read simulation model.
t, x = read(getnode(model, :writer).component)
display(t)
display(x)