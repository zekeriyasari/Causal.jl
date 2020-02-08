# Breaking Algebraic Loops

It this tutorial, we will simulate model consisting a closed loop feedback system. The model has an algebraic loop. 

### Algebraic Loops
In clocked simulation environment such as `Jusdl`, algebraic loops are problematic. This is because, at any instant of time, the component in the model are evolved. During this evolution, components read their inputs. If data is not available in their input busses, the components wait until data is available in their input busses. If the model has an algebraic loop, all the components in the algebraic loop waits for other component to produce data and drive them. However, since the components in the algebraic loop are feed-through loops, i.e. the outputs of the components depends directly on its inputs, a wait loop occurs. This wait loop makes simulation of the model get stuck. A system whose model includes algebraic loops can be simulated, though. One way is to remodel the system so that the model has no algebraic loops any more. This can be done by explicitly solving algebraic equations of algebraic loops. Or, a [`Memory`](ref) component can be added any where in the algebraic loop. The drawbacks of using a memory is that the initial condition of the memory should be compatible the model. 

### Simulation When Memory is Initialized Correctly
The original model consists of a generator and an adder. So, we start with these components 
```@example breaking_algebraic_loops_ex
using Jusdl # hide
gen = FunctionGenerator(identity)
adder = Adder(Bus(2), (+, -))
```
To break the algebraic loop, we construct a memory.
```@example breaking_algebraic_loops_ex
mem = Memory(Bus(1), 1, initial=0.)
```
For data recording, we construct writers.
```@example breaking_algebraic_loops_ex
writerout = Writer(Bus(length(adder.output)))
writerin = Writer(Bus(length(gen.output)))
```

The next step is to connect the components. Note that we placed the memory on the feedback path from the output of adder to its second link of its input bus. 
```@example breaking_algebraic_loops_ex
connect(gen.output, adder.input[1])
connect(mem.output, adder.input[2])
connect(adder.output, mem.input)
connect(mem.output, writerout.input)
connect(gen.output, writerin.input)
```
Now we are ready to construct and simulate the model.
```@example breaking_algebraic_loops_ex
t0, dt, tf = 0, 1 / 64, 1.
model = Model(gen, adder, mem, writerout, writerin)
sim = simulate(model, t0, dt, tf)
```
After the simulation, let us check whether the tasks are terminated securely.
```@example breaking_algebraic_loops_ex
model.taskmanager.pairs
```
Next, we read the data from the writers and plot them,
```@example breaking_algebraic_loops_ex
using Plots
plot(t, u, label=:u, marker=(:circle, 1)) 
plot!(t, y, label=:y, marker=(:circle, 1)) 
```

### Simulation When Memory is Initialized Incorrectly
We know that when the relation is 
```math
y(t) = \dfrac{u(t)}{2}
```
where ``u(t)`` is the input and ``y(t)`` is the output. Thus for ``u(t) = t``, ``y(0) = u(0) / 2  = 0``. This implies, the initial condition of the memory is ``0``. If the initial condition of the memory is different, then oscillations in the output of the memory occurs which lead inaccurate results. See the full script below. 

```@example 
using Jusdl 
using Plots 

# Simualation settings 
t0, dt, tf = 0, 1 / 64, 1.

# Construct model blocks 
gen = FunctionGenerator(identity)
adder = Adder(Bus(2), (+, -))
mem = Memory(Bus(1), 1, initial=0.5)    # Initial condition is very important for accurate solutions. 
writerout = Writer(Bus(length(adder.output)))
writerin = Writer(Bus(length(gen.output)))

# Connect model blocks 
connect(gen.output, adder.input[1])
connect(mem.output, adder.input[2])
connect(adder.output, mem.input)
connect(mem.output, writerout.input)
connect(gen.output, writerin.input)

# Construct the model 
model = Model(gen, adder, mem, writerout, writerin)

# Simulate the model 
sim = simulate(model, t0, dt, tf)

# Diplay model taskmanager
display(model.taskmanager.pairs)

# Read the simulation data 
t, y = read(writerout, flatten=true)
t, u = read(writerin, flatten=true)

# Plot the results
plot(t, u, label=:u, marker=(:circle, 1)) 
plot!(t, y, label=:y, marker=(:circle, 1)) 
```
