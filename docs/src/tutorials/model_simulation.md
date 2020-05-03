# Construction and Simulation of a Simple Model 

In this tutorial, we will simulate a very simple model consisting of a generator and a writer.  

## Model Simulation
We construct an empty model and then add nodes and branches to model. See [Construction of Models](@ref section_header) for more detailed information about model construction.
```@example simple_model_ex
using Jusdl 

# Construction of an empty model 
t0 = 0.     # Start time 
dt = 0.01   # Sampling interval
tf = 10.    # Final time
model = Model(clock=Clock(t0, dt, tf)) 

# Adding nodes to model
addnode(model, SinewaveGenerator(), label=:gen)
addnode(model, Writer(), label=:writer)

# Adding branches to model
addbranch(model, :gen => :writer)
nothing # hide
```
In this simple `model`, we have a single output sinusoidal wave generator `gen` and a `writer`. In the script above, we constructed the components, connected them together and constructed the model.

In addition to simulation time settings(which have set through model clock during the model construction above), we can specify simulation settings such as whether a simulation log file is be to constructed, model components are to be saved in a file, etc. 
```@example simple_model_ex 
simdir = "/tmp"  
logtofile = true
reportsim = true
nothing # hide
```
At this point, the model is ready for simulation. 
```@example simple_model_ex 
sim = simulate(model, simdir=simdir, logtofile=logtofile, reportsim=reportsim)
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
using Plots; pyplot() 
plot(t, x, xlabel="t", ylabel="x", label="")
savefig("simple_model_plot.svg"); nothing # hide
```
![](simple_model_plot.svg)
