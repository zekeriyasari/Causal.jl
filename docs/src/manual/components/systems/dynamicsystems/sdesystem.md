# SDESystem

## Construction of SDESystems
A `SDESystem` is represented by the state function 
```math 
    dx = f(x, u, t) dt + h(x, u, t)dW 
```
where ``t`` is the time, ``x \in R^n`` is the value of state, ``u \in R^p`` is the value of the input. ``W`` is the Wiener process of the system. The output function is defined by 
```math 
    y = g(x, u, t)
```
where ``y`` is the value of output at time ``t``. 

As an example consider a system with the following stochastic differential equation 
```math 
    \begin{array}{l}
        dx = -x dt - x dW
    \end{array}
```
and the following output equation 
```math 
y = x
```
The state function `statefunc` and the output function `outputfunc` is defined as follows.
```@repl sde_system_ex 
using Jusdl # hide 
f(dx, x, u, t) = (dx[1] = -x[1])
h(dx, x, u, t) = (dx[1] = -x[1])
```
The state function `statefunc` is the tuple of drift and diffusion functions
```@repl sde_system_ex 
statefunc = (f, h)
```
The output function `outputfunc` is defined as,
```@repl sde_system_ex 
g(x, u, t) = x
```
Note that the in drift function `f` and diffusion function `g`, the vector `dx` is *mutated* while in the output function `g` no mutation is done, but the output value is generated instead.

From the definition of drift function `f` and the diffusion function `g`, it is seen that the system does not have any input, that is, the input of the system is `nothing`. Since all the state variables are taken as outputs, the system needs an output bus of length 1. Thus, 
```@repl sde_system_ex 
input = nothing 
output = Outport(1)
```
At this point, we are ready to construct the system `ds`.
```@repl sde_system_ex 
ds = SDESystem(statefunc, g, [1.], 0., input, output)
```

## Basic Operation of SDESystems 
The basic operation of a `SDESystem` is the same as those of other dynamical systems. When triggered from its `trigger` link, a `SDESystem` reads its time `t` from its `trigger` link, reads its input value from its `input`, solves its state equation, which is a stochastic differential equation, computes its output and writes its computed output to its `output` bus. 

In this section, we continue with the system `ds` constructed in the previous section. To make `ds` drivable, we need to `launch` it.
```@repl sde_system_ex 
iport, trg, hnd = Inport(1), Outpin(), Inpin{Bool}()
connect!(ds.output, iport) 
connect!(trg, ds.trigger) 
connect!(ds.handshake, hnd)
task = launch(ds)
task2 = @async while true 
    all(take!(iport) .=== NaN) && break 
    end
```
When launched, `ds` can be driven. For this, either of the syntax `put!(ds.trigger, t)` or `drive(ds, t)` can be used. 
```@repl sde_system_ex 
put!(trg, 1.)
```
After this command, `ds` reads its time `t` from its `trigger` link, solves its state function and computes its output. The calculated output value is written to the buffer of `output`. To signal that, the step is takes with success, `ds` writes `true` to its `handshake` link. To further drive `ds`, this `handshake` link must be read. For this either of the syntax, `take!(ds.handshake)` or `approve!(ds)` can be used
```@repl sde_system_ex
hnd.link
take!(hnd)
```
At this point, we can further drive `ds`. 
```@repl sde_system_ex
for t in 2. : 10.
    put!(trg, t)
    take!(hnd)
end
```
Note that during the evolution, the output of `ds` is written into the buffers of `output` bus.
```@repl sde_system_ex 
iport[1].link.buffer
```

!!! warning 
    The values of the output is written into buffers if the `output` of the systems is not `nothing`.

When we launched `ds`, we constructed a `task` whose state is `running` which implies that the `ds` can be drivable. As long as this `task` is running, `ds` can be drivable. 

!!! warning 
    The state of the `task` is different from `running` in case an exception is thrown. 

To terminate the `task` securely, we need to terminate `ds` securely. To do that, can use `terminate!(ds)`.
```@repl sde_system_ex
put!(trg, NaN)
put!(ds.output, [NaN])
```
Note that the `task` is terminated without a hassle. 
```@repl sde_system_ex
task
task2
```

## Full API
```@docs
@def_sde_system 
SDESystem 
NoisyLorenzSystem 
ForcedNoisyLorenzSystem 
```
