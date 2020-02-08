# This file includes the Discrete Systems

import ....Components.ComponentsBase: @generic_system_fields, @generic_dynamic_system_fields, AbstractDiscreteSystem

const DiscreteSolver = Solver(FunctionMap())


@doc raw"""
    DiscreteSystem(input, output, statefunc, outputfunc, state, t;  solver=DiscreteSolver)

Construct a `DiscreteSystem` with `input` and `output`. `statefunc` is the state function and `outputfunc` is the output function of `DiscreteSystem`. `state` is the state and `t` is the current time of `t`. `solver` is numerical difference eqaution solver of the system. The system is represented by
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
"""
mutable struct DiscreteSystem{IB, OB, T, H, SF, OF, ST, IV, S} <: AbstractDiscreteSystem
    @generic_dynamic_system_fields
    function DiscreteSystem(input, output, statefunc, outputfunc, state, t;  solver=DiscreteSolver)
        trigger = Link()
        handshake = Link(Bool)
        inputval = typeof(input) <: Bus ? rand(eltype(state), length(input)) : nothing
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state),  typeof(inputval), typeof(solver)}(input, output, trigger, handshake, Callback[], uuid4(), statefunc, 
            outputfunc, state, inputval, t, solver)
    end
end

show(io::IO, ds::DiscreteSystem) = print(io, "DiscreteSystem(state:$(ds.state), t:$(ds.t), ",
    "input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
