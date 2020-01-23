# DiscreteSystem

## Construction of DiscreteSystem 
`DiscreteSystem`s evolve by the following discrete time difference equation.
```math 
    x_{k + 1} = f(x_k, u_k, k) \\
    y_k = g(x_k, u_k, k)
```
where ``x_k`` is the state, ``y_k`` is the value of `output` and ``u_k`` is the value of `input` at discrete time `t`. ``f`` is the state function and ``g`` is the output function of the system. See the main constructor.

## Basic Construction of DiscreteSystem
When a `DiscreteSystem` is triggered from its `trigger` link, it reads current time from its `trigger` link, reads its `input`, solves its difference equation, computes its output and writes its output value to its `output` bus. Let us continue with an example.

We first define state function `sfunc` and output function `ofunc` of the system,
```@repl discrete_system_ex 
using Jusdl # hide 
sfunc(dx, x, u, t) = (dx .= -0.5x)
ofunc(x, u, t) = x
```
From `sfunc`, it is seen that the system does not have any input, and from `ofunc` the system has one output. Thus, the `input` and `output` of the system is 
```@repl discrete_system_ex 
input = nothing 
output = Bus(1)
```
We also need to specify the initial condition and time of the system
```@repl discrete_system_ex 
x0  = [1.]
t = 0.
```
We are now ready to construct the system `ds`.
```@repl discrete_system_ex 
ds = DiscreteSystem(input, output, sfunc, ofunc, x0, t)
```
To drive `ds`, we need to `launch` it.
```@repl discrete_system_ex 
task = launch(ds)
```
At this point, `ds` is ready to be driven. To drive `ds`, we can either use `drive(ds, t)` or `put!(ds.trigger, t)`. 
```@repl discrete_system_ex 
drive(ds, 1.)
```
When the above code is executed, `ds` evolves until its time is `ds.t` is 1., During this evolution, `ds` reads time `t` from its `trigger` link, reads its `input` (in this example, `ds` has no input, so it does nothing when reading its input), solves its difference equation, computes its output and writes its output value to its `output`. To signal that the evolution is succeeded, `ds` writes `true` its `handshake` link which needs to be taken to further drive `ds`.
```@repl discrete_time_ex
ds.handshake  # `handshake` link is readable
take!(ds.handshake)
```
We continue to drive `ds`,
```@repl discrete_time_ex 
for i in 2. : 10. 
    drive(ds, i)
    take!(ds.handshake)
end
```
Note that all the output values of `ds` is written to its `output` bus.
```@repl discrete_system_ex
ds.output[1].buffer.data
```
When we launched `ds`, we constructed a `task` which is still running.
```@repl discrete_system_ex 
task
```
As long nothing goes wrong, i.e. no exception is thrown, during the evolution of `ds`, it is possible to drive `ds`. To safely terminate the `task`, we need to terminate the `ds`. 
```@repl discrete_system_ex
terminate(ds)
```
We can confirm that the `task` is not running and its state is `done`.
```@repl discrete_system_ex 
task
```
Since the `task` is not running any more, `ds` cannot be drivable any more. However to drive `ds` again, we need launch `ds` again.

## Full API
```@docs 
DiscreteSystem
```

