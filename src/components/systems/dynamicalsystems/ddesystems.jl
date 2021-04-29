# This file includes DDESystems

import DifferentialEquations: MethodOfSteps, Tsit5 
import UUIDs: uuid4

"""
    @def_dde_system ex 

where `ex` is the expression to define to define a new AbstractDDESystem component type. The usage is as follows:
```julia
@def_dde_system mutable struct MyDDESystem{T1,T2,T3,...,TN,OP,RH,RO,ST,IP,OP} <: AbstractDDESystem
    param1::T1 = param1_default                 # optional field 
    param2::T2 = param2_default                 # optional field 
    param3::T3 = param3_default                 # optional field
        ⋮
    paramN::TN = paramN_default                 # optional field 
    constlags::CL = constlags_default           # mandatory field
    depslags::DL = depslags_default             # mandatory field
    righthandside::RH = righthandside_function  # mandatory field
    history::HST = history_function             # mandatory field
    readout::RO = readout_function              # mandatory field
    state::ST = state_default                   # mandatory field
    input::IP = input_defauult                  # mandatory field
    output::OP = output_default                 # mandatory field
end
```
Here, `MyDDESystem` has `N` parameters. `MyDDESystem` is represented by the `righthandside` and `readout` function. `state`, `input` and `output` is the state, input port and output port of `MyDDESystem`.

!!! warning 
    `righthandside` must have the signature 
    ```julia
    function righthandside(dx, x, u, t, args...; kwargs...)
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
    New DDE system must be a subtype of `AbstractDDESystem` to function properly.

# Example 
```julia 
julia> _delay_feedback_system_cache = zeros(1)
1-element Array{Float64,1}:
 0.0

julia> _delay_feedback_system_tau = 1.
1.0

julia> _delay_feedback_system_constlags = [1.]
1-element Array{Float64,1}:
 1.0

julia> _delay_feedback_system_history(cache, u, t) = (cache .= 1.)
_delay_feedback_system_history (generic function with 1 method)

julia> function _delay_feedback_system_rhs(dx, x, h, u, t, 
           cache=_delay_feedback_system_cache, τ=_delay_feedback_system_tau)
           h(cache, u, t - τ)  # Update cache 
           dx[1] = cache[1] + x[1]
       end
_delay_feedback_system_rhs (generic function with 3 methods)

julia> @def_dde_system mutable struct MyDDESystem{RH, HST, RO, IP, OP} <: AbstractDDESystem
           constlags::Vector{Float64} = _delay_feedback_system_constlags
           depslags::Nothing = nothing
           righthandside::RH = _delay_feedback_system_rhs
           history::HST = _delay_feedback_system_history
           readout::RO = (x, u, t) -> x 
           state::Vector{Float64} = rand(1)
           input::IP = nothing 
           output::OP = Outport(1)
       end

julia> ds = MyDDESystem();
```
"""
macro def_dde_system(ex)
    checksyntax(ex, :AbstractDDESystem)
    appendcommonex!(ex)
    foreach(nex -> appendex!(ex, nex), [
        :( alg::$ALG_TYPE_SYMBOL = Causal.MethodOfSteps(Causal.Tsit5()) ), 
        :( integrator::$INTEGRATOR_TYPE_SYMBOL = Causal.construct_integrator(
            Causal.DDEProblem, input, (righthandside, history), state, t, modelargs, solverargs; 
            alg=alg, modelkwargs=(; 
            zip(
                (keys(modelkwargs)..., :constant_lags, :dependent_lags), 
                (values(modelkwargs)..., constlags, depslags))...
                ), 
            solverkwargs=solverkwargs, numtaps=3) ) 
        ])
    quote 
        Base.@kwdef $ex 
    end |> esc 
end

##### Define DDE system library.

"""
    DDESystem(; constantlags, depslags, righthandside, history, readout, state, input, output) 

Construct a generic DDE system 
"""
@def_dde_system mutable struct DDESystem{CL, DL, RH, HST, RO, ST, IP, OP} <: AbstractDDESystem
    constlags::CL 
    depslags::DL 
    righthandside::RH 
    history::HST 
    readout::RO 
    state::ST 
    input::IP 
    output::OP
end

"""
    DDESystem(; constantlags, depslags, righthandside, history, readout, state, input, output)

Constructs DelayFeedbackSystem
"""
@def_dde_system mutable struct DelayFeedbackSystem{RH, HST, RO, IP, OP} <: AbstractDDESystem
    constlags::Vector{Float64} = Causal._delay_feedback_system_constlags
    depslags::Nothing = nothing
    righthandside::RH = Causal._delay_feedback_system_rhs
    history::HST = Causal._delay_feedback_system_history
    readout::RO = (x, u, t) -> x 
    state::Vector{Float64} = rand(1)
    input::IP = nothing 
    output::OP = Outport(1)
end

_delay_feedback_system_cache = zeros(1)
_delay_feedback_system_tau = 1.
_delay_feedback_system_constlags = [1.]
_delay_feedback_system_history(cache, u, t) = (cache .= 1.)
function _delay_feedback_system_rhs(dx, x, h, u, t, 
    cache=Causal._delay_feedback_system_cache, τ=Causal._delay_feedback_system_tau)
    h(cache, u, t - τ)  # Update cache 
    dx[1] = cache[1] + x[1]
end

##### Pretty-printing

show(io::IO, ds::DDESystem) = print(io, 
    "DDESystem(righthandside:$(ds.righthandside), readout:$(ds.readout), state:$(ds.state), t:$(ds.t), ", 
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::DelayFeedbackSystem) = print(io, 
    "DelayFeedbackSystem(state:$(ds.state), t:$(ds.t), input:$(ds.input), output:$(ds.output))")

