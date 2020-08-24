# This file includes RODESystems

import DifferentialEquations: RandomEM, RODEProblem
import UUIDs: uuid4


"""
    @def_rode_system ex 

where `ex` is the expression to define to define a new AbstractRODESystem component type. The usage is as follows:
```julia
@def_rode_system mutable struct MyRODESystem{T1,T2,T3,...,TN,OP,RH,RO,ST,IP,OP} <: AbstractRODESystem
    param1::T1 = param1_default                 # optional field 
    param2::T2 = param2_default                 # optional field 
    param3::T3 = param3_default                 # optional field
        ⋮
    paramN::TN = paramN_default                 # optional field 
    righthandside::RH = righthandside_function  # mandatory field
    readout::RO = readout_function              # mandatory field
    state::ST = state_default                   # mandatory field
    input::IP = input_default                   # mandatory field
    output::OP = output_default                 # mandatory field
end
```
Here, `MyRODESystem` has `N` parameters. `MyRODESystem` is represented by the `righthandside` and `readout` function. `state`, `input` and `output` is the initial state, input port and output port of `MyRODESystem`.

!!! warning 
    `righthandside` must have the signature 
    ```julia
    function righthandside((dx, x, u, t, W, args...; kwargs...)
        dx .= .... # update dx
    end
    ```
    and `readout` must have the signature 
    ```julia
    function readout(x, u, t)
        y = ...
        return y
    end
    ```

!!! warning 
    New RODE system must be a subtype of `AbstractRODESystem` to function properly.

# Example 
```jldoctest 
julia> @def_rode_system mutable struct MySystem{RH, RO, IP, OP} <: AbstractRODESystem
           A::Matrix{Float64} = [2. 0.; 0 -2]
           righthandside::RH = (dx, x, u, t, W) -> (dx .= A * x * W)
           readout::RO = (x, u, t) -> x 
           state::Vector{Float64} = rand(2) 
           input::IP = nothing 
           output::OP = Outport(2)
       end

julia> ds = MySystem();
```
"""
macro def_rode_system(ex) 
    checksyntax(ex, :AbstractRODESystem)
    fields = quote
        trigger::$(TRIGGER_TYPE_SYMBOL) = Inpin()
        handshake::$(HANDSHAKE_TYPE_SYMBOL) = Outpin{Bool}()
        callbacks::$(CALLBACKS_TYPE_SYMBOL) = nothing
        name::Symbol = Symbol()
        id::$(ID_TYPE_SYMBOL) = Causal.uuid4()
        t::Float64 = 0.
        modelargs::$(MODEL_ARGS_TYPE_SYMBOL) = () 
        modelkwargs::$(MODEL_KWARGS_TYPE_SYMBOL) = NamedTuple() 
        solverargs::$(SOLVER_ARGS_TYPE_SYMBOL) = () 
        solverkwargs::$(SOLVER_KWARGS_TYPE_SYMBOL) = (dt=0.01, ) 
        alg::$(ALG_TYPE_SYMBOL) = Causal.RandomEM()
        integrator::$(INTEGRATOR_TYPE_SYMBOL) = Causal.construct_integrator(Causal.RODEProblem, input, righthandside, state, t, modelargs, 
            solverargs; alg=alg, modelkwargs=modelkwargs, solverkwargs=solverkwargs, numtaps=3)
    end, [TRIGGER_TYPE_SYMBOL, HANDSHAKE_TYPE_SYMBOL, CALLBACKS_TYPE_SYMBOL, ID_TYPE_SYMBOL, MODEL_ARGS_TYPE_SYMBOL, MODEL_KWARGS_TYPE_SYMBOL, SOLVER_ARGS_TYPE_SYMBOL, SOLVER_KWARGS_TYPE_SYMBOL, ALG_TYPE_SYMBOL, INTEGRATOR_TYPE_SYMBOL]
    _append_common_fields!(ex, fields...)
    deftype(ex)
end

##### Define RODE sytem library 

"""
    RODESystem(; righthandside, readout, state, input, output)

Constructs a generic RODE system 
"""
@def_rode_system mutable struct RODESystem{RH, RO, ST, IP, OP} <: AbstractRODESystem 
    righthandside::RH 
    readout::RO 
    state::ST 
    input::IP 
    output::OP
end

@doc raw"""
    MultiplicativeNoiseLinearSystem() 

Constructs a `MultiplicativeNoiseLinearSystem` with the dynamics 
```math 
\begin{array}{l}
    \dot{x} = A x W
\end{array}
where `W` is the noise process.
```
"""
@def_rode_system mutable struct MultiplicativeNoiseLinearSystem{RH, RO, IP, OP} <: AbstractRODESystem
    A::Matrix{Float64} = [2. 0.; 0 -2]
    righthandside::RH = (dx, x, u, t, W) -> (dx .= A * x * W)
    readout::RO = (x, u, t) -> x 
    state::Vector{Float64} = rand(2) 
    input::IP = nothing 
    output::OP = Outport(2)
end

##### Pretty printing 
show(io::IO, ds::RODESystem) = print(io, 
    "RODESystem(righthandside:$(ds.righthandside), readout:$(ds.readout), state:$(ds.state), t:$(ds.t), input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::MultiplicativeNoiseLinearSystem) = print(io, 
    "MultiplicativeNoiseLinearSystem(A:$(ds.A), state:$(ds.state), t:$(ds.t), input:$(ds.input), output:$(ds.output))")

