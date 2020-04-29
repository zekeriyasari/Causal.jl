<!--- # Construction and Simulation of Subsystems
In this tutorial, we will construct and simulate subsystems. A subsystem consists of connected components. A subsystem can serve as a component of a model. That is, components of a model can be a subsystem consisting of sub-components. The input/output bus of a subsystem can be specified from the input/output bus of components of the subsystem. It is also possible that a subsystem may have no input/output. That is, the input or output of a subsystem is nothing. 

### Construction of  Subsystem
Like the construction of a model, a subsystem is constructed by constructing the sub-components of the subsystem and connecting the sub-components. 

!!! warning 
    Since a subsystem serves a standalone component in a model, **the components of the subsystem must be connected to each other**. Otherwise, the subsystem cannot take step which in turn causes the simulation to get stuck.

In this example, we will construct a subsystem consisting of two gain components and a memory component. 
```@example subsystem_tutorial
using Jusdl
gain1 = Gain(Bus(), gain=2.)
gain2 = Gain(Bus(), gain=4)
mem = Memory(Bus(), 50, initial=rand(1))
``` 
Since these components will serve as a subsystem, we must connect them. In this example, these components are connected in series. 
```@example subsystem_tutorial 
connect(gain1.output, mem.input)
connect(mem.output, gain2.input)
```
Now, we are ready to construct the subsystem. 
```@example subsystem_tutorial
sub = SubSystem([gain1, gain2, mem], gain1.input, gain2.output)
```
Note that the input bus of `gain1` and output bus of `gain2` is specified as the input and output bus of the subsystem `sub`. That is, we have a single-input-single-output subsystem. 

To construct the model, we drive this subsystem with a generator and save its output in a writer. Thus, we construct other remaining components.
```@example subsystem_tutorial
gen = FunctionGenerator(sin)
writer = Writer(Bus())
```
Then, to construct the model, we connect the components of the model 
```@example subsystem_tutorial 
connect(gen.output, sub.input)
connect(sub.output, writer.input)
```
At this point, we are ready to construct the model 
```@example subsystem_tutorial 
model = Model(gen, sub, writer)
```
The next step is to simulate the model 
```@example subsystem_tutorial 
sim = simulate(model, 0, 0.01, 10)
```
We, then, read the simulation data from the writer and plot it. 
```@example subsystem_tutorial 
using Plots
t, x = read(writer, flatten=true)
plot(t, x)
savefig("subsystem_tutorial_plot.svg"); nothing # hide
```
![](subsystem_tutorial_plot.svg) --->