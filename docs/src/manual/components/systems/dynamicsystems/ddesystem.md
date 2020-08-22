# DDESystem

# Construction of DDESystem
A `DDESystem` is represented by the following state equation
```math 
    \dot{x} = f(x, h, u, t) \quad t \geq t_0
```
where ``t`` is the time, ``x`` is the value of the `state`, ``u`` is the value of the `input`. ``h`` is the history function for which 
```math 
    x(t) = h(t) \quad t \leq t_0
```
and by the output equation
```math 
    y = g(x, u, t) 
```
where ``y`` is the value of the `output`. 

As an example, consider a system with the state equation 
```math 
    \begin{array}{l}
    \dot{x} = -x(t - \tau) \quad t \geq 0 \\
    x(t) = 1. -\tau \leq t \leq 0 \\
    \end{array}
```
First, we define the history function `histfunc`,
```@repl dde_system_ex
using Causal # hide
const out = zeros(1)
histfunc(out, u, t) = (out .= 1.);
```
Note that `histfunc` mutates a vector `out`. This mutation is for [`performance reasons`](https://docs.juliadiffeq.org/latest/tutorials/dde_example/#Speeding-Up-Interpolations-with-Idxs-1). Next the state function can be defined
```@repl dde_system_ex
function statefunc(dx, x, h, u, t)
    h(out, u, t - tau) # Update out vector
    dx[1] = out[1] + x[1]
end
```
and let us take all the state variables as outputs. Thus, the output function is 
```@repl dde_system_ex 
outputfunc(x, u, t) = x
```
Next, we need to define the `history` for the system. History is defined by specifying a history function, and the type of the lags. There may be two different lag: constant lags which are independent of the state variable ``x`` and the dependent lags which are mainly the functions of the state variable ``x``. Note that for this example, the have constant lags. Thus, 
```@repl dde_system_ex 
tau = 1
conslags = [tau]
```
At this point, we are ready to construct the system. 
```@repl dde_system_ex 
ds = DDESystem(righthandside=statefunc, history=histfunc, readout=outputfunc, state=[1.],  input=nothing, output=Outport(), constlags=conslags, depslags=nothing)
```

## Basic Operation of DDESystem 
The basis operaiton of `DDESystem` is the same as those of other dynamical systems. When triggered from its `trigger` link, the `DDESystem` reads its time from its `trigger` link, reads input, solves its differential equation, computes its output and writes the computed output to its `output` bus. To drive `DDESystem`, we must first launch it,
```@repl dde_system_ex
iport, trg, hnd = Inport(), Outpin(), Inpin{Bool}()
connect!(ds.output, iport) 
connect!(trg, ds.trigger) 
connect!(ds.handshake, hnd)
task = launch(ds)
task2 = @async while true 
    all(take!(iport) .=== NaN) && break 
    end
```
When launched, `ds` is drivable. To drive `ds`, we can use the syntax `drive(ds, t)` or `put!(ds.trigger, t)` where `t` is the time until which `ds` is to be driven.
```@repl dde_system_ex 
put!(trg, 1.)
```
When driven, `ds` reads the time `t` from its `trigger` link, (since its input is `nothing`, `ds` does nothing during its input reading stage), solves its differential equation, computes output and writes the value of its output to its `output` bus. To signify, the step was taken with success, `ds` writes `true` to its `handshake` which must be read to further drive `ds`. For this, we can use the syntax `approve!(ds)` or `take!(ds.handshake)`.
```@repl dde_system_ex
take!(hnd)
``` 
We can continue to drive `ds`. 
```@repl dde_system_ex 
for t in 2. : 10.
    put!(trg, t)
    take!(hnd)
end
```
When launched, we constructed a `task` whose state is `running` which implies that `ds` can be driven. 
```@repl dde_system_ex
task
task2
```
As long as the state of the `task` is `running`, `ds` can be driven. To terminate `task` safely, we need to terminate the `ds`. 
```@repl dde_system_ex
put!(trg, NaN)
```
Note that the state of `task` is `done` which implies that `ds` is not drivable any more. 

Note that the output values of `ds` is written to its `output` bus. 
```@repl dde_system_ex
iport[1].link.buffer
```

## Full API
```@docs
@def_dde_system 
DDESystem 
DelayFeedbackSystem 
```
