# This file includes the Discrete Systems

import ....Components.ComponentsBase: @generic_system_fields, @generic_dynamic_system_fields, AbstractDiscreteSystem

const DiscreteAlg = FunctionMap()


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
julia> sfunc(dx,x,u,t) = (dx .= 0.5x)
sfunc (generic function with 1 method)
julia> ofunc(x, u, t) = x
ofunc (generic function with 1 method)

julia> ds = DiscreteSystem(Bus(1), Bus(1), sfunc, ofunc, [1.], 0.)
DiscreteSystem(state:[1.0], t:0.0, input:Bus(nlinks:1, eltype:Link{Float64}, isreadable:false, iswritable:false), output:Bus(nlinks:1, eltype:Link{Float64}, isreadable:false, iswritable:false))
```

!!! info 
    See [DifferentialEquations](https://docs.juliadiffeq.org/) for more information about `modelargs`, `modelkwargs`, `solverargs`, `solverkwargs` and `alg`.
"""
mutable struct DiscreteSystem{IB, OB, T, H, SF, OF, ST, I} <: AbstractDiscreteSystem
    @generic_dynamic_system_fields
    function DiscreteSystem(input, output, statefunc, outputfunc, state, t, modelargs=(), solverargs=(); 
        alg=DiscreteAlg, modelkwargs=NamedTuple(), solverkwargs=NamedTuple())
        trigger = Link()
        handshake = Link(Bool)
        integrator = construct_integrator(DiscreteProblem, input, statefunc, state, t, modelargs, solverargs; 
            alg=alg, modelkwargs=modelkwargs, solverkwargs=solverkwargs)
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state),  typeof(integrator)}(input, output, trigger, handshake, Callback[], uuid4(), statefunc, 
            outputfunc, state, t, integrator)
    end
end

show(io::IO, ds::DiscreteSystem) = print(io, "DiscreteSystem(state:$(ds.state), t:$(ds.t), ",
    "input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
