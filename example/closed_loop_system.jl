# This file simulates a closed system 

using Causal 

# Construct the model 
@defmodel model begin 
    @nodes begin 
        gen = FunctionGenerator(readout=sin)
        adder = Adder(signs=(+,-))
        ds = ContinuousLinearSystem()
        writer = Writer(input=Inport(2))
    end
    @branches begin 
        gen[1]      =>  adder[1]
        adder[1]    =>  ds[1]
        ds[1]       =>  adder[2]
        gen[1]      =>  writer[1]
        ds[1]       =>  writer[2]
    end
end

# Simualate the model 
sim = simulate!(model, 0., 0.01, 10.)

# Read and plot data 
t, x = read(getnode(model, :writer).component)
using Plots
plot(t, x[:, 1], label="r(t)", xlabel="t", lw=3)
plot!(t, x[:, 2], label="y(t)", xlabel="t", lw=3)
plot!(t, 6 / 5 * exp.(-2t) + 1 / 5 * (2 * sin.(t) - cos.(t)), label="Analytical Solution", lw=3)
# fileanme = "readme_example.svg"
# path = joinpath(@__DIR__, "../docs/src/assets/ReadMePlot/")
# savefig(joinpath(path, fileanme))
