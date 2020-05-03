# Construction and Simulation of Subsystems
In this tutorial, we will construct and simulate subsystems. A subsystem consists of connected components. A subsystem can serve as a component of a model. That is, components of a model can be a subsystem consisting of sub-components. The input/output port of a subsystem can be specified from the input/output port of components of the subsystem. It is also possible that a subsystem may have no input/output. That is, the input or output of a subsystem is nothing. 

Like the construction of a model, a subsystem is constructed by constructing the sub-components of the subsystem and connecting the sub-components. 

!!! warning 
    Since a subsystem serves a standalone component in a model, the components of the subsystem must be connected to each other. Otherwise, the subsystem cannot take step which in turn causes the simulation to get stuck.

Consider the simple subsystem whose block diagram is given below. 
```@raw html
<center>
    <img src="../../assets/Subsystem/subsystem.svg" alt="model" width="60%"/>
</center>
```
We first construct the subsystem.
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
Since these components will serve as a subsystem, we must connect them. The input port of `adder` and output port of `gain` is specified as the input and output port of the subsystem `sub`. That is, we have a single-input-single-output subsystem. 

Then, we construct the model. We drive the subsystem with a generator and save its output in a writer as shown in the block diagram below. 
```@raw html
<center>
    <img src="../../assets/SubsystemConnected/subsystemconnected.svg" alt="model" width="45%"/>
</center>
``` 
Thus, we construct other remaining components.
```@example subsystem_tutorial
model = Model() 
addnode(model, sub, label=:sub)
addnode(model, SinewaveGenerator(frequency=5), label=:gen)
addnode(model, Writer(), label=:writer)
nothing # hide
```
Then, to construct the model, we connect the components of the model 
```@example subsystem_tutorial
addbranch(model, :gen => :sub, 1 => 1) 
addbranch(model, :sub => :writer, 1 => 1) 
nothing # hide
```
At this step, we are ready to simulate the model.
```@example subsystem_tutorial 
sim = simulate(model)
sim
```
We, then, read the simulation data from the writer and plot it. 
```@example subsystem_tutorial 
using Plots; pyplot()
t, x = read(getnode(model, :writer).component)
plot(t, x)
savefig("subsystem_tutorial_plot.svg"); nothing # hide
```
![](subsystem_tutorial_plot.svg)
