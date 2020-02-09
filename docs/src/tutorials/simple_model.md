# Construction and Simulation of a Simple Model 

It this tutorial, we will simulate a very simple model consisting of a sinusoidal generator and a writer.  

### Model Construction
A model consists of connected components. We can either construct the components first and then connect them together to construct the model, or, we construct an empty model with no components, construct the components, connect those components and add those connected components to the model.

#### Construction of Model - Construct the Components First
We construct the components first and then connect them together
```@example simple_model_ex
using Jusdl 

# Construction of the components 
gen = SinewaveGenerator()
writer = Writer(Bus())

# Connection of components 
connect(gen.output, writer.input)

# Construction of the model 
model = Model(gen, writer)
```
In this simple `model`, we have a single output sinusoidal wave generator `gen` and a `writer`. In the script above, we constructed the components, connected them together and constructed the model. 

#### Construction of Model - Construct the Model First
In this way, we construct and empty model and then construct components, connect them and add them to the model 

```@example
using Jusdl 

# Construct the model with no components
model = Model()


# Construct the components 
gen = SinewaveGenerator()
writer = Writer(Bus())

# Connect the components 
connect(gen.output, writer.input)

# Add components to model 
addcomponent(model, gen)
addcomponent(model, writer)
```

### Model Simulation 
To simulate a model, simulation time settings are mandatory,
```@example simple_model_ex

# Define simulation time settings 
t0 = 0.     # Start time 
dt = 0.01   # Sampling interval
tf = 10.    # Final time
```
Next, we can specify other simulation settings such as whether a simulation log file are to constructed, model blocks are to saved in a file, etc. 
```@example simple_model_ex 
simdir = "/tmp"     # Path in which simulation files are saved.
logtofile = true    # If true, a simulation log file is constructed 
reportsim = true    # If true, model blocks are saved.
```
At this point, we are ready to simulate the model,
```@example simple_model_ex 
sim = simulate(model, t0, dt, tf, simdir=simdir, logtofile=logtofile, reportsim=reportsim)
```

### Investigation of Simulation 
First, let us observe `Simulation` instance `sim`. We start with the directory in which all simulation files are saved.  
```@example simple_model_ex
@show sim.path
```
Now change directory to `sim.path` and print the content of the log fle.
```@example simple_model_ex 
# Change directory to simulation path. 
cd(sim.path)

# Print the contents of log file 
open("log.txt", "r") do file 
    for line in readlines(file)
        println(line)
    end
end
```

### Analysis of Simulation Data Files 
After the simulation, the data saved in simulation data files, i.e. in the files of writers, can be read back any offline data analysis can be performed. 
```@example simple_model_ex
# Read the simulation data
t, x = read(writer, flatten=true) 

# Plot the data
using Plots 
theme(:default)
plot(t, x, xlabel="t", ylabel="x", label="")
savefig("simple_model_plot.svg"); nothing # hide
```
![](simple_model_plot.svg)






