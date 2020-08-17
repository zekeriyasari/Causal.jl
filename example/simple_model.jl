using Jusdl 

# Deifne model 
@defmodel model begin
    @nodes begin 
        gen = SinewaveGenerator(amplitude=1., frequency=1/2π) 
        adder = Adder(signs=(+, -)) 
        ds = ContinuousLinearSystem(A=fill(-1., 1, 1), state=[1.])
        writer = Writer(input=Inport(2)) 
    end 
    @branches begin 
        gen[1] => adder[1] 
        adder[1] => ds[1]
        ds[1] => adder[2] 
        ds[1] => writer[1]
        gen[1] => writer[2]
    end
end

# Simulate the model 
tinit, tsample, tfinal = 0., 0.01, 10. 
sim = simulate!(model, tinit, tsample, tfinal)

# Read and plot data 
t, x = read(getnode(model, :writer).component)
t, x = read(getnode(model, :writer).component)
using Plots
plot(t, x[:, 1], label="r(t)", xlabel="t")
plot!(t, x[:, 2], label="y(t)", xlabel="t")
plot!(t, 6 / 5 * exp.(-2t) + 1 / 5 * (2 * sin.(t) - cos.(t)), label="Analytical Solution")
