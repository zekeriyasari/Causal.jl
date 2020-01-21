# DAESystem 

## Basic Operation of DAESystem 
The basic operation of `DAESystem` is the same as [Basic Operation of ODESystem](@ref). The basic opeation of `DAESystem` is given with an example. Consider the following differential algebraic equation.
```math 
    \begin{array}{l}
    dx_1 = -0.04 x_1 + 10^4 x_2 x_3 \\[0.25]
    dx_2 = 0.04 x_1 - 10^4 x_2 x_3  - 3 \times 10^7 x_2^2 \\[0.25]
    1 = x_1 + x_2 + x_3
    \end{array}
```
with the initial conditions ``x_1(0) = 1``, ``x_2(0) = 0``, ``x_3(0) = 0``, ``dx_1(0) = -0.04``, ``dx_2(0) = 0.04``, ``x_3(0) = 0``. In this equation, the variables ``x_1`` and ``x_2`` is the differential variables and the variable ``x_3`` is the algebraic variable.

Since `DAESystem`s are represented by a state function `statefunc` which are *Differential Algebraic Equation* and an output function `outputfunc`, we need to define those functions.
We start with the `statefunc` corresponding to the differential algebraic equation given above. 
```@repl dae_ex 
using Jusdl # hide 
function statefunc(out, dx, x, u, t)
    out[1] = - 0.04x[1]              + 1e4*x[2]*x[3] - dx[1]
    out[2] = + 0.04x[1] - 3e7*x[2]^2 - 1e4*x[2]*x[3] - dx[2]
    out[3] = x[1] + x[2] + x[3] - 1.0
end
```
Note the signature of  `statefunc`. The `statefunc` *modifies* a vector `out` using `dx`, `x`, `u`, and `t`. For this example, we take all the states as outputs, i.e., we have an output function `outputfunc` given as
```@repl dae_ex 
outputfunc(x, u, t) = x
```
Note that `outputfunc`, vector `x` is *generated* but not mutated. We also need to specify the differential variables. 
```@repl dae_ex 
diffvars = [true, true, false]
```
Note that the first two variables are differential variables and the last variable is algebraic variable. From above equation, the system does not any inputs. But, we need a bus as output with three links. 
```@repl dae_ex 
input = nothing 
output = Bus(3)
```
Let us define the initial condition and initial value of the state derivative.
```@repl dae_ex 
state = [1., 0., 0]
stateder = [-0.04, 0.04, 0.]
```
At this point, we are ready to construct the `DAESystem`.
```@repl dae_ex
ds = DAESystem(input, output, statefunc, outputfunc, state, stateder, 0, diffvars)
```
To drive the `ds`, we need to launch `ds`.
```@repl dae_ex 
task = launch(ds)
```
Now, `ds` can be triggered, i.e., driven from its `trigger` link since when launched its `trigger` link is writable.
```@repl dae_ex 
ds.trigger
```
Let us drive `ds`. For this, either `drive(ds, t)` or `put!(ds.trigger, t)` can be used. 
```@repl dae_ex 
drive(ds, 1.)
```
When driven, `ds` first reads current time from its `trigger` link, reads its `input`, solves its differential equation defined via its `statefunc` and computes its output using its output function defined via `outputfunc`. However, for this example, `ds` has no input, thus it does not need to read its `input`. This implies that the output can directly be computed with the current time `t` and current state `x`. When its output is computed, the computed output is written to its output bus. To signal that, the step is performed without any problem, `ds` writes `true` to its `handshake` link. And, to further drive `ds`, its `handshake` link must be read. 
```@repl dae_ex 
take!(ds.handshake)
```
Note the current time and state of `ds` has been updated and output is written to its output buffer. 
```@repl dae_ex 
ds.t 
ds.state 
ds.stateder 
ds.output[1].buffer.state
```
Note that the state of the output buffer is not empty which implies an output value is written to its output buffer. We constructed a task which is still running,
```@repl dae_ex 
task
```
This means that `ds` is still drivable. To terminate this safely, we need to terminate `ds` safely. 
```@repl dae_ex 
terminate(ds)
```
At this point, it is not possible to drive `ds` any more since the state of `task` is `done`.
```@repl dae_ex 
task
```

## Full API
```@docs 
DAESystem
```