# This file includes DAESystems

import ....Components.ComponentsBase: @generic_system_fields, @generic_dynamic_system_fields, AbstractDAESystem

const DAEAlg = IDA()


@doc raw"""
    DAESystem(input, output, statefunc, outputfunc, state, stateder, t, modelargs=(), solverargs=(); 
        alg=DAEAlg, modelkwargs=NamedTuple(), solverkwargs=NamedTuple())

Construsts a `DAESystem` with `input` and `output`. `statefunc` is the state function and `outputfunc` is the output function. `state` is the initial state, `stateder` is the initial state derivative  and `t` is the time. `modelargs` and `modelkwargs` are passed into `ODEProblem` and `solverargs` and `solverkwargs` are passed into `solve` method of `DifferentialEquations`. `alg` is the algorithm to solve the differential equation of the system.

`DAESystem` is represented by the following equations. 
```math 
    \begin{array}{l}
        0 = f(out, dx, x, u, t) \\
        y = f(x, u, t)
    \end{array}
```
where ``t`` is the time `t`, ``x`` is `state`,  ``dx`` is the value of the derivative of the state `stateder`, ``u`` is the value of `input` and ``y`` is the value of `output` at time ``t``. `solver` is used to solve the above differential equation.

The signature of `statefunc` must be of the form 
```julia 
function statefunc(out, dx, x, u, t)
    out .= ... # Update out
emd
```
and the signature of `outputfunc` must be of the form 
```julia 
function outputfunc(x, u, t)
    y = ... # Compute y 
    return y
end
```

!!! info 
    See [DifferentialEquations](https://docs.juliadiffeq.org/) for more information about `modelargs`, `modelkwargs`, `solverargs` `solverkwargs` and `alg`.
"""
mutable struct DAESystem{IB, OB, T, H, SF, OF, ST, I} <: AbstractDAESystem
    @generic_dynamic_system_fields
    function DAESystem(input, output, statefunc, outputfunc, state, stateder, t, modelargs=(), solverargs=(); 
        alg=DAEAlg, modelkwargs=NamedTuple(), solverkwargs=NamedTuple())
        trigger = Link()
        handshake = Link(Bool)
        integrator = construct_integrator(DAEProblem, input, statefunc, state, t, modelargs, solverargs; 
            alg=alg, stateder=stateder, modelkwargs=modelkwargs, solverkwargs=solverkwargs)
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state), typeof(integrator)}(input, output, trigger, handshake, Callback[], 
            uuid4(), statefunc, outputfunc, state, t, integrator)
    end
end

show(io::IO, ds::DAESystem) = print(io, "DAESystem(state:$(ds.state), t:$(ds.t), ", 
    "input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
