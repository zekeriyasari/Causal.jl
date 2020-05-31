# This file includes RODESystems

import DifferentialEquations: RandomEM, RODEProblem
import UUIDs: uuid4


"""
    @def_rode_system

Used to define new RODE system types.
"""
macro def_rode_system(ex) 
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
        solverkwargs::SK = (dt=0.01, ) 
        alg::AL = Jusdl.RandomEM()
        integrator::IT = Jusdl.construct_integrator(Jusdl.RODEProblem, input, righthandside, state, t, modelargs, 
            solverargs; alg=alg, modelkwargs=modelkwargs, solverkwargs=solverkwargs, numtaps=3)
    end, [:TR, :HS, :CB, :ID, :MA, :MK, :SA, :SK, :AL, :IT]
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
@def_rode_system struct MultiplicativeNoiseLinearSystem{RH, RO, IP, OP} <: AbstractRODESystem
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

