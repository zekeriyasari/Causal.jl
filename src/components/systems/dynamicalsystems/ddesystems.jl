# This file includes DDESystems


@doc raw"""
    DDESystem(input, output, statefunc, outputfunc, state, t, modelargs=(), solverargs=(); 
        alg=DDEAlg, modelkwargs=NamedTuple(), solverkwargs=NamedTuple())

Constructs a `DDESystem` with `input` and `output`. `statefunc` is the state function and `outputfunc` is the output function of `DDESystem`. `state` is the initial state and `t` is the time. `modelargs` and `modelkwargs` are passed into `ODEProblem` and `solverargs` and `solverkwargs` are passed into `solve` method of `DifferentialEquations`. `alg` is the algorithm to solve the differential equation of the system.

The `DDESystem` is represented by
```math 
    \begin{array}{l}
        \dot{x} = f(x, h, u, t) \\
        y = g(x, u, t)
    \end{array}
```
where ``t`` is the time `t`, ``x`` is the value of `state`, ``u`` is the value of `input`, ``y`` is the value of `output`. ``f`` is `statefunc`, ``g`` is `outputfunc`. ``h``is the history function of `history`. `solver` is used to solve the above differential equation.

The syntax of `statefunc` must be of the form 
```julia 
function statefunc(dx, x, u, t)
    dx .= ... # Update dx
end
```
and the syntax of `outputfunc` must be of the form 
```julia 
function outputfunc(x, u, t)
    y = ... # Compute y 
    return y
end
```
# Example 
```jldoctest
julia> const out = zeros(1);

julia> histfunc(out, u, t) = (out .= 1.);

julia> function sfuncdde(dx, x, h, u, t)
           h(out, u, t - tau) # Update out vector
           dx[1] = out[1] + x[1]
       end;

julia> ofuncdde(x, u, t) = x;

julia> tau = 1;

julia> conslags = [tau];

julia> DDESystem((sfuncdde, histfunc), ofuncdde, [1.],  0., nothing, Outport())
DDESystem(state:[1.0], t:0.0, input:nothing, output:Outport(numpins:1, eltype:Outpin{Float64}))
```

!!! info 
    See [DifferentialEquations](https://docs.juliadiffeq.org/) for more information about `modelargs`, `modelkwargs`, `solverargs` `solverkwargs` and `alg`.
"""
mutable struct DDESystem{SF, OF, ST, T, IN, IB, OB, TR, HS, CB} <: AbstractDDESystem
    @generic_dynamic_system_fields
    function DDESystem(statefunc, outputfunc, state, t, input, output, modelargs=(), solverargs=(); 
        alg=DDEAlg, modelkwargs=NamedTuple(), solverkwargs=NamedTuple(), numtaps=numtaps, callbacks=nothing, 
        name=Symbol())
        trigger, handshake, integrator = init_dynamic_system(
                DDEProblem, statefunc, state, t, input, modelargs, solverargs; 
                alg=alg, modelkwargs=modelkwargs, solverkwargs=solverkwargs, numtaps=numtaps
            )
        new{typeof(statefunc), typeof(outputfunc), typeof(state), typeof(t), typeof(integrator), typeof(input), 
            typeof(output), typeof(trigger), typeof(handshake), typeof(callbacks)}(statefunc, outputfunc, state, t, 
            integrator, input, output, trigger, handshake, callbacks, name, uuid4())
    end
end

show(io::IO, ds::DDESystem) = print(io, 
    "DDESystem(state:$(ds.state), t:$(ds.t), input:$(ds.input), output:$(ds.output))")

