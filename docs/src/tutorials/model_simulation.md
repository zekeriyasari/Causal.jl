# Construction and Simulation of a Simple Model 

In this tutorial, we will simulate a very simple model consisting of a generator and a writer as shown in the block diagram shown below. 
```@raw html
<center>
    <img src="../../assets/GeneratorWriter/generatorwriter.svg" alt="model" width="35%"/>
</center>
```

## Model Simulation
We construct an empty model and then add nodes and branches to model. See [Modifying Models](@ref section_header) for more detailed information about model construction.
```@example simple_model_ex
using Jusdl 

# Describe the model 
@defmodel model begin 
    @nodes begin 
        gen = SinewaveGenerator() 
        writer = Writer() 
    end 
    @branches begin 
        gen => writer
    end
end
nothing # hide
```
In this simple `model`, we have a single output sinusoidal wave generator `gen` and a `writer`. In the script above, we constructed the components, connected them together and constructed the model.

We can specify simulation settings such as whether a simulation log file is be to constructed, model components are to be saved in a file, etc. 
```@example simple_model_ex 
simdir = "/tmp"  
logtofile = true
reportsim = true
nothing # hide
```
At this point, the model is ready for simulation. 
```@example simple_model_ex 
t0 = 0.     # Start time 
dt = 0.01   # Sampling interval
tf = 10.    # Final time
sim = simulate!(model, t0, dt, tf, simdir=simdir, logtofile=logtofile, reportsim=reportsim)
```

## Investigation of Simulation 
First, let us observe `Simulation` instance `sim`. We start with the directory in which all simulation files are saved.  
```@example simple_model_ex
foreach(println, readlines(`ls -al $(sim.path)`))
```
The simulation directory includes a log file `simlog.log` which helps the user monitor simulation steps. 
```@example simple_model_ex 
# Print the contents of log file 
open(joinpath(sim.path, "simlog.log"), "r") do file 
    for line in readlines(file)
        println(line)
    end
end
```
`report.jld2` file, which includes the information about the simulation and model components, can be read back after the simulation. 
```@repl simple_model_ex
using FileIO, JLD2 
filecontent = load(joinpath(sim.path, "report.jld2"))
clock = filecontent["model/clock"]
```

## Analysis of Simulation Data
After the simulation, the data saved in simulation data files, i.e. in the files of writers, can be read back any offline data analysis can be performed. 
```@example simple_model_ex
# Read the simulation data
t, x = read(getnode(model, :writer).component) 

# Plot the data
using Plots
plot(t, x, xlabel="t", ylabel="x", label="")
savefig("simple_model_plot.svg"); nothing # hide
```
![](simple_model_plot.svg)


## A Larger Model Simulation 
Consider a larger model whose block diagram is given below
```@raw html
<center>
    <img src="../../assets/ModelGraph/modelgraph.svg" alt="model" width="90%"/>
</center>
```
The script below illustrates the construction and simulation of this model 
```@example large_model 
using Jusdl 
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

# Simulation of the model 
simulate!(model, withbar=false)

# Reading and plotting the simulation data
t, x = read(getnode(model, :writer).component)
plot(t, x)
savefig("larger_model_plot.svg"); nothing # hide
```
![](larger_model_plot.svg)
