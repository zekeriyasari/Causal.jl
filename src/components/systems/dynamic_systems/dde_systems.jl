# This file includes DDESystems

import ....Components.ComponentsBase: @generic_system_fields, @generic_dynamic_system_fields, AbstractDDESystem

const DDEAlg = MethodOfSteps(Tsit5())

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
julia> const out = zeros(1)
1-element Array{Float64,1}:
 0.0

julia> histfunc(out, u, t) = (out .= 1.)
histfunc (generic function with 1 method)

julia> function statefunc(dx, x, h, u, t)
           h(out, u, t - tau) # Update out vector
           dx[1] = out[1] + x[1]
       end
statefunc (generic function with 1 method)

julia> outputfunc(x, u, t) = x
outputfunc (generic function with 1 method)

julia> tau = 1
1

julia> conslags = [tau]
1-element Array{Int64,1}:
 1

julia> hist = History(histfunc, conslags, ())
History(func:histfunc, conslags:[1], seed:(), neutral:false

julia> ds = DDESystem(nothing, Bus(), statefunc, outputfunc, [1.], hist, 0.)
DDESystem(state:[1.0], history:History(func:histfunc, conslags:[1], seed:(), neutral:false, t:0.0, input:nothing, output:Bus(nlinks:1, eltype:Link{Float64}, isreadable:false, iswritable:false), history:History(func:histfunc, conslags:[1], seed:(), neutral:false)
```

!!! info 
    See [DifferentialEquations](https://docs.juliadiffeq.org/) for more information about `modelargs`, `modelkwargs`, `solverargs` `solverkwargs` and `alg`.
"""
mutable struct DDESystem{IB, OB, T, H, SF, OF, ST, I} <: AbstractDDESystem
    @generic_dynamic_system_fields
    function DDESystem(input, output, statefunc, outputfunc, state, t, modelargs=(), solverargs=(); 
        alg=DDEAlg, modelkwargs=NamedTuple(), solverkwargs=NamedTuple())
        trigger = Link()
        handshake = Link(Bool)
        integrator = construct_integrator(DDEProblem, input, statefunc, state, t, modelargs, solverargs; 
            alg=alg, modelkwargs=modelkwargs, solverkwargs=solverkwargs)
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state), typeof(integrator)}(input, output, trigger, handshake, Callback[], 
            uuid4(), statefunc, outputfunc, state, t, integrator)
    end
end

show(io::IO, ds::DDESystem) = print(io, "DDESystem(state:$(ds.state), t:$(ds.t), ", 
    "input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")

