# This file includes the Discrete Systems


@doc raw"""
    DiscreteSystem(input, output, statefunc, outputfunc, state, t, modelargs=(), solverargs=(); 
        alg=DiscreteAlg, modelkwargs=NamedTuple(), solverkwargs=NamedTuple())

Construct a `DiscreteSystem` with `input` and `output`. `statefunc` is the state function and `outputfunc` is the output function of `DiscreteSystem`. `state` is the initial state and `t` is the time. `modelargs` and `modelkwargs` are passed into `ODEProblem` and `solverargs` and `solverkwargs` are passed into `solve` method of `DifferentialEquations`. `alg` is the algorithm to solve the diffence equation of the system.

The system is represented by
```math
    \begin{array}{l}
        x_{k + 1} = f(x_k, u_k, k) \\
        y_k = g(x_k, u_k, k)
    \end{array}
```
where ``x_k`` is the state,  ``y_k`` is the value of output, ``u_k`` is the value of input at dicrete time ``k``. ``f` is `statefunc` and ``g`` is `outputfunc`. 

The signature of `statefunc` must be of the form 
```julia 
function statefunc(dx, x, u, t)
    dx = ...   # Update dx
end
```
and the signature of `outputfunc` must be of the form 
```julia 
function outputfunc(x, u, t)
    y = ...   # Compute y
    return y
end
```

# Example 
```jldoctest 
julia> sfuncdiscrete(dx,x,u,t) = (dx .= 0.5x);

julia> ofuncdiscrete(x, u, t) = x;

julia> DiscreteSystem(sfuncdiscrete, ofuncdiscrete, [1.], 0., nothing, Outport())
DiscreteSystem(state:[1.0], t:0.0, input:nothing, output:Outport(numpins:1, eltype:Outpin{Float64}))
```

!!! info 
    See [DifferentialEquations](https://docs.juliadiffeq.org/) for more information about `modelargs`, `modelkwargs`, `solverargs`, `solverkwargs` and `alg`.
"""
mutable struct DiscreteSystem{SF, OF, ST, T, IN, IB, OB, TR, HS, CB} <: AbstractDiscreteSystem
    @generic_dynamic_system_fields
    function DiscreteSystem(statefunc, outputfunc, state, t, input, output, modelargs=(), solverargs=(); 
        alg=DiscreteAlg, modelkwargs=NamedTuple(), solverkwargs=NamedTuple(), numtaps=numtaps, callbacks=nothing,
         name=Symbol())
        trigger, handshake, integrator = init_dynamic_system(
                DiscreteProblem, statefunc, state, t, input, modelargs, solverargs; 
                alg=alg, modelkwargs=modelkwargs, solverkwargs=solverkwargs, numtaps=numtaps
            )
        new{typeof(statefunc), typeof(outputfunc), typeof(state), typeof(t), typeof(integrator), typeof(input), 
            typeof(output), typeof(trigger), typeof(handshake), typeof(callbacks)}(statefunc, outputfunc, state, t, 
            integrator, input, output, trigger, handshake, callbacks, name, uuid4())
    end
end

show(io::IO, ds::DiscreteSystem) = print(io, 
    "DiscreteSystem(state:$(ds.state), t:$(ds.t), input:$(ds.input), output:$(ds.output))")
