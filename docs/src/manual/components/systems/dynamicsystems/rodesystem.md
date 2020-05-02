# RODESystem

## Construction of RODESystem 
A `RODESystem` is represented by the state function 
```math 
\begin{array}{l}
    dx = f(x, u, t, W)
\end{array}
```
and the output function 
```math 
    y = g(x, u, t)
```
where ``t`` is the time, ``x \in R^n`` is the state, ``u \in R^p`` and ``y \in R^m`` is output of the system. Therefore to construct a `RODESystem`, we need to define `statefunc` and `outputfunc` with the corresponding syntax,
```julia
function statefunc(dx, x, u, t)
    dx .= ... # Update dx 
end
```
and 
```julia 
function outputfunc(x, u, t)
    y = ... # Compute y
    return y
end
```
As an example, consider the system with the state function
```math 
    \begin{array}{l}
        dx_1 = 2 x_1 sin(W_1 - W_2) \\
        dx_2 = -2 x_2 cos(W_1 + W_2)
    \end{array}
```
and with the output function 
```math 
    y = x
```
That is, all the state variable are taken as output. The `statefunc` and the `outputfunc` is defined as,
```@repl rode_system_ex 
using Jusdl # hide
function statefunc(dx, x, u, t, W)
    dx[1] = 2x[1]*sin(W[1] - W[2])
    dx[2] = -2x[2]*cos(W[1] + W[2])
end
outputfunc(x, u, t) = x
```
To construct the `RODESystem`, we need to specify the initial condition and time.
```@repl rode_system_ex 
x0 = [1., 1.]
t = 0.
```
Note from `statefunc`, the system has not any input, i.e. input is nothing, and has an output with a dimension of 1.
```@repl rode_system_ex
input = nothing
output = Outport(2)
```
We are ready to construct the system
```@repl rode_system_ex 
ds = RODESystem(statefunc, outputfunc, x0, t, input, output, solverkwargs=(dt=0.01,))
```
Note that `ds` has a solver to solve its state function `statefunc` which is random differential equation. To solve its `statefunc`, the step size of the solver must be specified. See [`Random Differential Equtions`](https://docs.juliadiffeq.org/latest/tutorials/rode_example/) of [`DifferentialEquations `](https://docs.juliadiffeq.org/latest/) package.

## Basic Operation of RODESystem 
When a `RODESystem` is triggered from its `trigger` link, it read the current time from its `trigger` link, reads its input (if available, i.e. its input is not nothing), solves its state function, computes its output value and writes its output value its `output` bus (again, if available, i.e., its output bus is not nothing). To drive a `RODESystem`, it must be `launched`. Let us continue with `ds` constructed in the previous section.
```@repl rode_system_ex 
iport, trg, hnd = Inport(2), Outpin(), Inpin{Bool}()
connect(ds.output, iport) 
connect(trg, ds.trigger) 
connect(ds.handshake, hnd)
task = launch(ds)
task2 = @async while true 
    all(take!(iport) .=== NaN) && break 
    end
```
When launched, `ds` is ready to be driven. We can drive `ds` by `drive(ds, t)` or `put!(ds.trigger, t)` where `t` is the time until which we will drive `ds`. 
```@repl rode_system_ex 
put!(trg, 1.)
```
When triggered, `ds` read the time `t` from its `trigger` link, solved its differential equation, computed its value and writes its output value to its `output` bus. To signal that, the evolution is succeeded, `ds` writes `true` to its `handshake` link which must be taken to further drive `ds`. (`approve(ds)`) can also be used. 
```@repl rode_system_ex
take!(hnd)
```
We can continue to drive `ds`.
```@repl rode_system_ex
for t in 2. : 10.
    put!(trg, t)
    take!(hnd)
end
```
After each evolution, `ds` writes its current output value to its `output` bus. 
```@repl rode_system_ex 
[outbuf(pin.link.buffer) for pin in iport]
```
When launched, a `task` was constructed which still running. As long as no exception is thrown during the evolution of `ds`, the state of `task` is running which implies `ds` can be driven. 
```@repl rode_system_ex
task
task2
```
To terminate the `task` safely, `ds` should be terminated safely. 
```@repl rode_system_ex
put!(trg, NaN)
put!(ds.output, [NaN, NaN])
```
Note that the state of `task` is `done` which implies the `task` has been terminated safely.
```@repl rode_system_ex
task
task2
```
