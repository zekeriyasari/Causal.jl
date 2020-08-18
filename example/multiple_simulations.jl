# This file is illustrates multiple simulations of a model 

using Jusdl

# Constrcut the model 
@defmodel model begin 
    @nodes begin 
        gen = SinewaveGenerator() 
        writer = Writer()
    end 
    @branches begin 
        gen => writer 
    end 
end 


# Multiple simulations. 
for i in 1 : 5 
    simulate!(model)
end