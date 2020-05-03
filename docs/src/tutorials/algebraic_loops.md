# Breaking Algebraic Loops

It this tutorial, we will simulate model consisting a closed loop feedback system. The model has an algebraic loop. 

## Algebraic Loops
An algebraic loop is a closed-loop consisting of one or more components whose outputs are directly dependent on their inputs. If algebraic loops exist in a model,  the simulation gets stuck because none of the components in the loop can generate output to break the loop. Such a problem can be broken by rearranging the model without algebraic loops, solving the feed-forward algebraic equation of the loop, or inserting a memory component with a certain initial condition anywhere in the loop. Jusdl provides all these loop-breaking solutions. During the inspection stage,  in case they are detected, all the loops are broken. Otherwise, a report is printed to notify the user to insert memory components to break the loops. 

## Breaking Algebraic Loops Automatically
Before initializing and running the simulation, Jusdl inspects the model first. See [Simulation Stages](@ref) for more information of simulation stages. In case the they exist in the model, all the algebraic loops are tried to be broken automatically without requiring a user intervention. Consider the following model 

```@raw html
<center>
    <img src="../../assets/AlgebraicLoop/algebraicloop.svg" alt="model" width="65%"/>
</center>
```
where 
```math
\begin{array}{l}
    r(t) = t \\[0.25cm]
    u(t) = r(t) - y(t) \\[0.25cm]
    y(t) = u(t) 
\end{array}
```
Note that there exist an algebraic loop consisting of `adder` and `gain`.  Solving this algebraic loop, we have 
```math 
    y(t) = u(t) = r(t) - y(t) \quad \Rightarrow \quad y(t) = \dfrac{r(t)}{2} = \dfrac{t}{2}
```
The following script constructs and simulates the model. 
```@example breaking_algebraic_loops_ex
using Jusdl

# Construct an empty model 
t0, dt, tf = 0, 1 / 64, 1.
model = Model(clock=Clock(t0, dt, tf))

# Add nodes to the model
addnode(model, RampGenerator(), label=:gen)
addnode(model, Adder((+,-)), label=:adder)
addnode(model, Gain(), label=:gain)
addnode(model, Writer(), label=:writerout)
addnode(model, Writer(), label=:writerin)

# Add branches to the model 
addbranch(model, :gen => :adder, 1 => 1)
addbranch(model, :adder => :gain, 1 => 1)
addbranch(model, :gain => :adder, 1 => 2)
addbranch(model, :gen => :writerin, 1 => 1)
addbranch(model, :gain => :writerout, 1 => 1)

# Simulate the model 
sim = simulate(model, withbar=false)

# Read the simulation data and plot 
using Plots; pyplot()
t, y = read(getnode(model, :writerout).component)
t, r = read(getnode(model, :writerin).component)
plot(t, r, label="r(t)", marker=(:circle, 1)) 
plot!(t, y, label="y(t)", marker=(:circle, 1)) 
savefig("breaking_algebraic_loops_plot1.svg"); nothing # hide
```
![](breaking_algebraic_loops_plot1.svg)

## Breaking Algebraic Loops With a Memory 
It is also possible to break algebraic loops by inserting a [`Memory`](@ref) component at some point the loop. For example, consider the model consider following the model which is the model in which a memory component is inserted in the feedback path. 
```@raw html
<center>
    <img src="../../assets/AlgebraicLoopWithMemory/algebraicloopwithmemory.svg" alt="model" width="80%"/>
</center>
```
Note that the input to `adder` is not ``y(t)``, but instead is ``\hat{y}(t)`` which is one sample delayed form of ``y(t)``.  That is, we have, ``\hat{y}(t) = y(t - dt)`` where ``dt`` is the step size of the simulation. If ``dt`` is small enough, ``\hat{y}(t) \approx y(t)``.

The script given below simulates this case. 
```@example breaking_algebraic_loops_with_memory 
using Jusdl 

# Construct the model 
ti, dt, tf = 0, 1 / 64, 1. 
model = Model(clock=Clock(ti, dt, tf))

# Adding nodes to model 
addnode(model, RampGenerator(), label=:gen) 
addnode(model, Adder((+, -)), label=:adder) 
addnode(model, Gain(), label=:gain) 
addnode(model, Memory(dt, t0=tf, dt=dt, initial=zeros(1)), label=:mem) 
addnode(model, Writer(Inport(2)), label=:writer)
addbranch(model, :gen => :adder, 1 => 1) 
addbranch(model, :adder => :gain, 1 => 1) 
addbranch(model, :gain => :mem, 1 => 1) 
addbranch(model, :mem => :adder, 1 => 2) 
addbranch(model, :gen => :writer, 1 => 1) 
addbranch(model, :gain => :writer, 1 => 2) 

# Simulate the model 
sim = simulate(model, withbar=false)

# Plot the simulation data
using Plots; pyplot() 
t, x = read(getnode(model, :writer).component)
plot(t, x[:, 1], label="r(t)", marker=(:circle, 1))
plot!(t, x[:, 2], label="y(t)", marker=(:circle, 1))
savefig("breaking_algebraic_loops_with_memory_plot1.svg"); nothing # hide
```
![](breaking_algebraic_loops_with_memory_plot1.svg)
The fluctuation in ``y(t)`` because of one-sample-time delay introduced by the `mem` component is apparent. The smaller the step size is, the smaller the amplitude of the fluctuation  introduced by the `mem` component. 

One other important issue with using the memory component is that the initial value of `mem` directly affects the accuracy of the simulation. By solving the loop equation, we know that 
```math 
    y(t) = \dfrac{r(t)}{2} = \dfrac{t}{2} \quad \Rightarrow \quad y(0) = 0
```
That is the memory should be initialized with an initial value of zero, which is the case in the script above. To observe that how incorrect initialization of a memory to break an algebraic loop, consider the following example in which memory is initialized randomly. 
```@example breaking_algebraic_loops_with_memory_incorrect_initialization 
using Jusdl 

# Construct the model 
ti, dt, tf = 0, 1 / 64, 1. 
model = Model(clock=Clock(ti, dt, tf))

# Adding nodes to model 
addnode(model, RampGenerator(), label=:gen) 
addnode(model, Adder((+, -)), label=:adder) 
addnode(model, Gain(), label=:gain) 
addnode(model, Memory(dt, t0=tf, dt=dt, initial=rand(1)), label=:mem) 
addnode(model, Writer(Inport(2)), label=:writer)
addbranch(model, :gen => :adder, 1 => 1) 
addbranch(model, :adder => :gain, 1 => 1) 
addbranch(model, :gain => :mem, 1 => 1) 
addbranch(model, :mem => :adder, 1 => 2) 
addbranch(model, :gen => :writer, 1 => 1) 
addbranch(model, :gain => :writer, 1 => 2) 

# Simulate the model 
sim = simulate(model)

# Plot the results 
using Plots; pyplot() 
t, x = read(getnode(model, :writer).component)
plot(t, x[:, 1], label="r(t)", marker=(:circle, 1))
plot!(t, x[:, 2], label="y(t)", marker=(:circle, 1))
savefig("breaking_algebraic_loops_with_memory_incorrect_plot1.svg"); nothing # hide
```
![](breaking_algebraic_loops_with_memory_incorrect_plot1.svg)
