using Jusdl 
using Plots

# Deifne model 
@defmodel model begin
    @nodes begin 
        gen = ConstantGenerator(amplitude=1.) 
        adder = Adder(signs=(+, -)) 
        ds = ContinuousLinearSystem(state=rand(1))
        writer = Writer() 
    end 
    @branches begin 
        gen[1] => adder[1] 
        adder => ds
        ds[1] => adder[2] 
        ds => writer
    end
end

# Simulate the model 
sim = simulate!(model, 0., 0.01, 10.)

# Plots results
t, x = read(getnode(model, :writer).component)
p = plot(t, x)
display(p)
