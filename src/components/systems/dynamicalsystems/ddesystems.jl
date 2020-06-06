# This file includes DDESystems

import DifferentialEquations: MethodOfSteps, Tsit5 
import UUIDs: uuid4

"""
    @def_dde_system

Used to define DDE system
"""
macro def_dde_system(ex)
    fields = quote
        trigger::TR = Inpin()
        handshake::HS = Outpin{Bool}()
        callbacks::CB = nothing
        name::Symbol = Symbol()
        id::ID = Jusdl.uuid4()
        t::Float64 = 0.
        modelargs::MA = () 
        modelkwargs::MK = NamedTuple() 
        solverargs::SA = () 
        solverkwargs::SK = NamedTuple() 
        alg::AL = Jusdl.MethodOfSteps(Tsit5())
        integrator::IT = Jusdl.construct_integrator(
            Jusdl.DDEProblem, input, (righthandside, history), state, t, modelargs, solverargs; 
            alg=alg, modelkwargs=(; 
            zip(
                (keys(modelkwargs)..., :constant_lags, :dependent_lags), 
                (values(modelkwargs)..., constlags, depslags))...
                ), 
            solverkwargs=solverkwargs, numtaps=3)
    end, [:TR, :HS, :CB, :ID, :MA, :MK, :SA, :SK, :AL, :IT]
    _append_common_fields!(ex, fields...)
    deftype(ex)
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
    constlags::Vector{Float64} = Jusdl._delay_feedback_system_constlags
    depslags::Nothing = nothing
    righthandside::RH = Jusdl._delay_feedback_system_rhs
    history::HST = Jusdl._delay_feedback_system_history
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
    cache=Jusdl._delay_feedback_system_cache, τ=Jusdl._delay_feedback_system_tau)
    h(cache, u, t - τ)  # Update cache 
    dx[1] = cache[1] + x[1]
end

##### Pretty-printing

show(io::IO, ds::DDESystem) = print(io, 
    "DDESystem(righthandside:$(ds.righthandside), readout:$(ds.readout), state:$(ds.state), t:$(ds.t), ", 
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::DelayFeedbackSystem) = print(io, 
    "DelayFeedbackSystem(state:$(ds.state), t:$(ds.t), input:$(ds.input), output:$(ds.output))")

