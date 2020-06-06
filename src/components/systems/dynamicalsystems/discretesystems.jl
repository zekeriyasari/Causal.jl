# This file includes the Discrete Systems

import DifferentialEquations: FunctionMap, DiscreteProblem
import UUIDs: uuid4

"""
    @def_discrete_system

Used to define discrete time system
"""
macro def_discrete_system(ex) 
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
        alg::AL = Jusdl.FunctionMap()
        integrator::IT = Jusdl.construct_integrator(Jusdl.DiscreteProblem, input, righthandside, state, t, modelargs, 
            solverargs; alg=alg, modelkwargs=modelkwargs, solverkwargs=solverkwargs, numtaps=3)
    end, [:TR, :HS, :CB, :ID, :MA, :MK, :SA, :SK, :AL, :IT]
    _append_common_fields!(ex, fields...)
    deftype(ex)
end

##### Define Discrete system library

"""
    DiscreteSystem(; righthandside, readout, state, input, output)

Constructs a generic discrete system 
"""
@def_discrete_system mutable struct DiscreteSystem{RH, RO, ST, IP, OP} <: AbstractDiscreteSystem
    righthandside::RH
    readout::RO 
    state::ST 
    input::IP 
    output::OP
end


@doc raw"""
    DiscreteLinearSystem(input, output, modelargs=(), solverargs=(); 
        A=fill(-1, 1, 1), B=fill(0, 1, 1), C=fill(1, 1, 1), D=fill(0, 1, 1), state=rand(size(A,1)), t=0., 
        alg=ODEAlg, modelkwargs=NamedTuple(), solverkwargs=NamedTuple())

Constructs a `DiscreteLinearSystem` with `input` and `output`. `state` is the initial state and `t` is the time. `modelargs` and `modelkwargs` are passed into `ODEProblem` and `solverargs` and `solverkwargs` are passed into `solve` method of `DifferentialEquations`. `alg` is the algorithm to solve the differential equation of the system.

The `DiscreteLinearSystem` is represented by the following state and output equations.
```math
\begin{array}{l}
    \dot{x} = A x + B u \\[0.25cm]
    y = C x + D u 
\end{array}
```
where ``x`` is `state`. `solver` is used to solve the above differential equation.
"""
@def_ode_system mutable struct DiscreteLinearSystem{IP, OP, RH, RO} <: AbstractDiscreteSystem
    A::Matrix{Float64} = fill(-1., 1, 1)
    B::Matrix{Float64} = fill(0., 1, 1)
    C::Matrix{Float64} = fill(1., 1, 1)
    D::Matrix{Float64} = fill(-1., 1, 1)
    input::IP = Inport(1)
    output::OP = nothing
    state::Vector{Float64} = rand(size(A, 1))
    righthandside::RH = input === nothing ? (dx, x, u, t) -> (dx .= A * x) : 
        (dx, x, u, t) -> (dx .= A * x + B * map(ui -> ui(t), u.itp))
    readout::RO = input === nothing ? (x, u, t) -> (C * x) : 
           ( (C === nothing || D === nothing) ? nothing : (x, u, t) -> (C * x + D * map(ui -> ui(t), u)) )
end


@doc raw"""
    Henon()

Constructs a `Henon` system evolving with the dynamics 
```math
\begin{array}{l}
    \dot{x}_1 = 1 - \alpha (x_1^2) + x_2 \\[0.25cm]
    \dot{x}_2 = \beta x_1
\end{array}
```
"""
@def_discrete_system struct HenonSystem{RH, RO, IP, OP} <: AbstractDiscreteSystem
    α::Float64 = 1.4 
    β::Float64 = 0.3 
    γ::Float64 = 1.
    righthandside::RH = function henonrhs(dx, x, u, t, α=α, β=β, γ=γ)
        dx[1] = 1 - α * x[1]^2 + x[2] 
        dx[2] = β * x[1]
        dx .*= γ
    end 
    readout::RO = (x, u, t) -> x 
    state::Vector{Float64} = rand(2)
    input::IP = nothing
    output::OP = Outport(2)
end

@doc raw"""
    LoziSystem()

Constructs a `Lozi` system evolving with the dynamics 
```math
\begin{array}{l}
    \dot{x}_1 = 1 - \alpha |x_1| + x_2 \\[0.25cm]
    \dot{x}_2 = \beta x_1
\end{array}
```
"""
@def_discrete_system struct LoziSystem{RH, RO, IP, OP} <: AbstractDiscreteSystem
    α::Float64 = 1.4 
    β::Float64 = 0.3 
    γ::Float64 = 1.
    righthandside::RH = function lozirhs(dx, x, u, t, α=α, β=β, γ=γ)
        dx[1] = 1 - α * abs(x[1]) + x[2] 
        dx[2] = β * x[1]
        dx .*= γ
    end 
    readout::RO = (x, u, t) -> x 
    state::Vector{Float64} = rand(2)
    input::IP = nothing
    output::OP = Outport(2)
end


@doc raw"""
    BogdanovSystem() 

Constructs a Bogdanov system with equations
```math
\begin{array}{l}
    \dot{x}_1 = x_1 + \dot{x}_2 \\[0.25cm]
    \dot{x}_2 = x_2 + \epsilon + x_2 + k x_1 (x_1 - 1) + \mu  x_1 x_2
\end{array}
```
"""
@def_discrete_system struct BogdanovSystem{RH, RO, IP, OP} <: AbstractDiscreteSystem
    ε::Float64 = 0. 
    μ::Float64 = 0. 
    k::Float64 = 1.2 
    γ::Float64 = 1.
    righthandside::RH = function bogdanovrhs(dx, x, u, t, ε=ε, μ=μ, k=k, γ=γ)
        dx[2]= x[2] + ε * x[2] + k * x[1] * (x[1] - 1) + μ * x[1] * x[2]
        dx[1] = x[1] + dx[2]
        dx .*= γ
    end 
    readout::RO = (x, u, t) -> x 
    state::Vector{Float64} = rand(2)
    input::IP = nothing
    output::OP = Outport(2)
end


@doc raw"""
    GingerbreadmanSystem() 

Constructs a GingerbreadmanSystem with the dynamics 
```math
\begin{array}{l}
    \dot{x}_1 = 1 - x_2 + |x_1|\\[0.25cm]
    \dot{x}_2 = x_1
\end{array}
```
"""
@def_discrete_system struct GingerbreadmanSystem{RH, RO, IP, OP} <: AbstractDiscreteSystem
    γ::Float64 = 1.
    righthandside::RH = function gingerbreadmanrhs(dx, x, u, t, γ=γ)
        dx[1] = 1 - x[2] + abs(x[1])
        dx[2] = x[1]
        dx .*= γ
    end
    readout::RO = (x, u, t) -> x 
    state::Vector{Float64} = rand(2)
    input::IP = nothing 
    output::OP = Outport(2)
end


@doc raw"""
    LogisticSystem() 

Constructs a LogisticSystem with the dynamics 
```math
\begin{array}{l}
    \dot{x} = r x (1 - x)
\end{array}
```
"""
@def_discrete_system struct LogisticSystem{RH, RO, IP, OP} <: AbstractDiscreteSystem
    r::Float64 = 1.
    γ::Float64 = 1.
    righthandside::RH = function logisticrhs(dx, x, u, t, r = r, γ=γ)
        dx[1] = r * x[1] * (1 - x[1])
        dx[1] *= γ
    end
    readout::RO = (x, u, t) -> x 
    state::Vector{Float64} = rand(1)
    input::IP = nothing 
    output::OP = Outport(1)
end


##### Pretty-printting 

show(io::IO, ds::DiscreteSystem) = print(io, 
    "DiscreteSystem(righthandside:$(ds.righthandside), readout:$(ds.readout), state:$(ds.state), t:$(ds.t), ",
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::DiscreteLinearSystem) = print(io, 
    "DiscreteLinearystem(A:$(ds.A), B:$(ds.B), C:$(ds.C), D:$(ds.D), state:$(ds.state), t:$(ds.t), ",
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::HenonSystem) = print(io, 
    "HenonSystem(α:$(ds.α), β:$(ds.β), γ:$(ds.γ),state:$(ds.state), t:$(ds.t), input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::LoziSystem) = print(io, 
    "LoziSystem(α:$(ds.α), β:$(ds.β), γ:$(ds.γ), state:$(ds.state), t:$(ds.t), ",
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::BogdanovSystem) = print(io, 
    "BogdanovSystem(ε:$(ds.ε), μ:$(ds.μ), k:$(ds.k), γ:$(ds.γ), state:$(ds.state), t:$(ds.t), ",
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::GingerbreadmanSystem) = print(io, 
    "GingerbreadmanSystem(γ:$(ds.γ), state:$(ds.state), t:$(ds.t), input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::LogisticSystem) = print(io, 
    "LogisticSystem(r:$(ds.r), γ:$(ds.γ), state:$(ds.state), t:$(ds.t), input:$(ds.input), output:$(ds.output))")

