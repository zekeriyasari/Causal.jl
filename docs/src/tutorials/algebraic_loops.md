# Breaking Algebraic Loops

It this tutorial, we will simulate model consisting a closed loop feedback system. The model has an algebraic loop. 

### Algebraic Loops
In a clocked simulation environment such as Jusdl, algebraic loops are problematic. This is because, at any instant of time, the components in the model are evolved. During this evolution, components read their inputs. If data is not available in their input busses, the components wait until data is available in their input busses. If the model has an algebraic loop, all the components in the algebraic loop wait for other components to produce data and drive them. However, since the components in the algebraic loop are feed-through loops, i.e. the outputs of the components depend directly on its inputs, a wait loop occurs. This wait-loop makes the simulation of the model get stuck. A system whose model includes algebraic loops can be simulated, though. One way is to remodel the system so that the model has no algebraic loops anymore. This can be done by explicitly solving algebraic equations of algebraic loops. Or, a memory component can be added anywhere in the algebraic loop. The drawback of using a memory component is that the initial condition of the memory should be compatible with the model. 

### Simulation When Memory is Initialized Correctly
The original model consists of a generator and an adder. So, we start with these components 
```@example breaking_algebraic_loops_ex
using Jusdl # hide

# Construct an empty model 
t0, dt, tf = 0, 1 / 64, 1.
model = Model(clock=Clock(t0, dt, tf))

# Add nodes to model
addnode(model, FunctionGenerator(identity), label=:gen)
addnode(model, Adder((+,-)), label=:adder)
addnode(model, Gain(), label=:gain)
addnode(model, Writer(), label=:writerout)
addnode(model, Writer(), label=:writerin)
```

The next step is to connect the components. Note that we placed the memory on the feedback path from the output of adder to its second link of its input bus. 
```@example breaking_algebraic_loops_ex
addbranch(model, :gen => :adder, 1 => 1)
addbranch(model, :adder => :gain, 1 => 1)
addbranch(model, :gain => :adder, 1 => 2)
addbranch(model, :gen => :writerin, 1 => 1)
addbranch(model, :gain => :writerout, 1 => 1)
```
Now we are ready to construct and simulate the model.
```@example breaking_algebraic_loops_ex
sim = simulate(model)
```
After the simulation, let us check whether the tasks are terminated securely.
```@example breaking_algebraic_loops_ex
model.taskmanager.pairs
```
Next, we read the data from the writers and plot them,
```@example breaking_algebraic_loops_ex
using Plots; pyplot()
t, y = read(getnode(model, :writerout).component)
t, u = read(getnode(model, :writerin).component)
plot(t, u, label=:u, marker=(:circle, 1)) 
plot!(t, y, label=:y, marker=(:circle, 1)) 
savefig("breaking_algebraic_loops_plot1.svg"); nothing # hide
```
![](breaking_algebraic_loops_plot1.svg)
