# This file includes DAESystems



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

# Example 
```julia 
julia> function sfuncdae(out, dx, x, u, t)
           out[1] = x[1] + 1 - dx[1]
           out[2] = (x[1] + 1) * x[2] + 2
       end;

julia> ofuncdae(x, u, t) = x;

julia> x0 = [1., -1];

julia> dx0 = [2., 0.];

julia> DAESystem(sfuncdae, ofuncdae, x0, 0., nothing, Outport(1), modelkwargs=(differential_vars=[true, false],), stateder=dx0)
DAESystem(state:[1.0, -1.0], t:0.0, input:nothing, output:Outport(numpins:1, eltype:Outpin{Float64}))
```

!!! info 
    See [DifferentialEquations](https://docs.juliadiffeq.org/) for more information about `modelargs`, `modelkwargs`, `solverargs` `solverkwargs` and `alg`.
"""
mutable struct DAESystem{SF, OF, ST, T, IN, IB, OB, TR, HS, CB} <: AbstractDAESystem
    @generic_dynamic_system_fields
    function DAESystem(statefunc, outputfunc, state, t, input, output, modelargs=(), solverargs=(); 
        alg=DAEAlg, stateder=state, modelkwargs=NamedTuple(), solverkwargs=NamedTuple(), numtaps=numtaps, 
        callbacks=nothing, name=Symbol())
        trigger, handshake, integrator = init_dynamic_system(
                DAEProblem, statefunc, state, t, input, modelargs, solverargs; 
                alg=alg, stateder=stateder, modelkwargs=modelkwargs, solverkwargs=solverkwargs, numtaps=numtaps
            )
        new{typeof(statefunc), typeof(outputfunc), typeof(state), typeof(t), typeof(integrator), typeof(input), 
            typeof(output), typeof(trigger), typeof(handshake), typeof(callbacks)}(statefunc, outputfunc, state, t, 
            integrator, input, output, trigger, handshake, callbacks, name, uuid4())
    end
end

show(io::IO, ds::DAESystem) = print(io, 
    "DAESystem(state:$(ds.state), t:$(ds.t), input:$(ds.input), output:$(ds.output))")
