# Construction and Simulation of Subsystems
In this tutorial, we will construct and simulate subsystems. A subsystem consists of connected components. A subsystem can serve as a component of a model. That is, components of a model can be a subsystem consisting of sub-components. The input/output bus of a subsystem can be specified from the input/output bus of components of the subsystem. It is also possible that a subsystem may have no input/output. That is, the input or output of a subsystem is nothing. 

### Construction of  Subsystem
Like the construction of a model, a subsystem is constructed by constructing the sub-components of the subsystem and connecting the sub-components. 

!!! warning 
    Since a subsystem serves a standalone component in a model, **the components of the subsystem must be connected to each other**. Otherwise, the subsystem cannot take step which in turn causes the simulation to get stuck.

In this example, we will construct a simple subsystem.
```@example subsystem_tutorial
using Jusdl

# Construct a subsystem 
adder = Adder((+,-))
gain = Gain()
gen = ConstantGenerator()
connect(gen.output, adder.input[2])
connect(adder.output, gain.input)
sub = SubSystem([gen, adder, gain], adder.input[1], gain.output)
``` 
Since these components will serve as a subsystem, we must connect them. The input port of `adder` and output port of `gain` is specified as the input and output bus of the subsystem `sub`. That is, we have a single-input-single-output subsystem. 

To construct the model, we drive this subsystem with a generator and save its output in a writer. Thus, we construct other remaining components.
```@example subsystem_tutorial
model = Model() 
addnode(model, sub, label=:sub)
addnode(model, SinewaveGenerator(frequency=5), label=:gen)
addnode(model, Writer(), label=:writer)
```
Then, to construct the model, we connect the components of the model 
```@example subsystem_tutorial
addbranch(model, :gen => :sub, 1 => 1) 
addbranch(model, :sub => :writer, 1 => 1) 
```
At this point, we are ready to construct the model. At this step, we are ready to simulate the model 
```@example subsystem_tutorial 
sim = simulate(model)
```
We, then, read the simulation data from the writer and plot it. 
```@example subsystem_tutorial 
using Plots; pyplot()
t, x = read(getnode(model, :writer).component)
plot(t, x)
savefig("subsystem_tutorial_plot.svg"); nothing # hide
```
![](subsystem_tutorial_plot.svg)
