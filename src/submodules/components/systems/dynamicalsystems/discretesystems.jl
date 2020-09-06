# This file includes the Discrete Systems

export @def_discrete_system, DiscreteSystem, DiscreteLinearSystem, HenonSystem, LoziSystem, BogdanovSystem, 
    GingerbreadmanSystem, LogisticSystem

"""
    @def_discrete_system ex 

where `ex` is the expression to define to define a new AbstractDiscreteSystem component type. The usage is as follows:
```julia
@def_discrete_system mutable struct MyDiscreteSystem{T1,T2,T3,...,TN,OP,RH,RO,ST,IP,OP} <: AbstractDiscreteSystem
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
Here, `MyDiscreteSystem` has `N` parameters. `MyDiscreteSystem` is represented by the `righthandside` and `readout` function. `state`, `input` and `output` is the state, input port and output port of `MyDiscreteSystem`.

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
    New discrete system must be a subtype of `AbstractDiscreteSystem` to function properly.

# Example 
```julia 
julia> @def_discrete_system mutable struct MyDiscreteSystem{RH, RO, IP, OP} <: AbstractDiscreteSystem 
       α::Float64 = 1. 
       β::Float64 = 2. 
       righthandside::RH = (dx, x, u, t, α=α) -> (dx[1] = α * x[1] + u[1](t))
       state::Vector{Float64} = [1.]
       readout::RO = (x, u, t) -> x
       input::IP = Inport(1) 
       output::OP = Outport(1) 
       end

julia> ds = MyDiscreteSystem();

julia> ds.input 
1-element Inport{Inpin{Float64}}:
 Inpin(eltype:Float64, isbound:false)
```
"""
macro def_discrete_system(ex) 
    checksyntax(ex, :AbstractDiscreteSystem)
    appendcommonex!(ex)
    foreach(nex -> ComponentsBase.appendex!(ex, nex), [
        :( alg::$ALG_TYPE_SYMBOL = DynamicalSystems.FunctionMap() ), 
        :( integrator::$INTEGRATOR_TYPE_SYMBOL = DynamicalSystems.construct_integrator(DynamicalSystems.DiscreteProblem, 
            input, righthandside, state, t,modelargs, solverargs; alg=alg, modelkwargs=modelkwargs, 
            solverkwargs=solverkwargs, numtaps=3) ) 
        ])
    quote 
        Base.@kwdef $ex 
    end |> esc 
end

##### Define Discrete system library

"""
    $(TYPEDEF) 

# Fields 

    $(TYPEDFIELDS)

A generic discrete system 

# Example 
```julia
julia> sfuncdiscrete(dx,x,u,t) = (dx .= 0.5x);

julia> ofuncdiscrete(x, u, t) = x;

julia> DiscreteSystem(righthandside=sfuncdiscrete, readout=ofuncdiscrete, state=[1.], input=nothing, output=Outport())
DiscreteSystem(righthandside:sfuncdiscrete, readout:ofuncdiscrete, state:[1.0], t:0.0, input:nothing, output:Outport(numpins:1, eltype:Outpin{Float64}))

```
"""
@def_discrete_system mutable struct DiscreteSystem{RH, RO, ST, IP, OP} <: AbstractDiscreteSystem
    righthandside::RH
    readout::RO 
    state::ST 
    input::IP 
    output::OP
end


"""
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)

A `DiscreteLinearSystem` with `input` and `output`. `state` is the initial state and `t` is the time. `modelargs` and `modelkwargs` are passed into `ODEProblem` and `solverargs` and `solverkwargs` are passed into `solve` method of `DifferentialEquations`. `alg` is the algorithm to solve the differential equation of the system.

The `DiscreteLinearSystem` is represented by the following state and output equations.
```math
\\begin{array}{l}
    \\dot{x} = A x + B u \\[0.25cm]
    y = C x + D u 
\\end{array}
```
where ``x`` is `state`.
"""
@def_discrete_system mutable struct DiscreteLinearSystem{IP, OP, RH, RO} <: AbstractDiscreteSystem
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


"""
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)

`Henon` system evolving with the dynamics 
```math
\\begin{array}{l}
    \\dot{x}_1 = 1 - \\alpha (x_1^2) + x_2 \\[0.25cm]
    \\dot{x}_2 = \\beta x_1
\\end{array}
```
"""
@def_discrete_system mutable struct HenonSystem{RH, RO, IP, OP} <: AbstractDiscreteSystem
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

"""
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)

`Lozi` system evolving with the dynamics 
```math
\\begin{array}{l}
    \\dot{x}_1 = 1 - \\alpha |x_1| + x_2 \\[0.25cm]
    \\dot{x}_2 = \\beta x_1
\\end{array}
```
"""
@def_discrete_system mutable struct LoziSystem{RH, RO, IP, OP} <: AbstractDiscreteSystem
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


"""
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)

Bogdanov system with equations
```math
\\begin{array}{l}
    \\dot{x}_1 = x_1 + \\dot{x}_2 \\[0.25cm]
    \\dot{x}_2 = x_2 + \\epsilon + x_2 + k x_1 (x_1 - 1) + \\mu  x_1 x_2
\\end{array}
```
"""
@def_discrete_system mutable struct BogdanovSystem{RH, RO, IP, OP} <: AbstractDiscreteSystem
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


"""
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS) 

GingerbreadmanSystem with the dynamics 
```math
\\begin{array}{l}
    \\dot{x}_1 = 1 - x_2 + |x_1|\\[0.25cm]
    \\dot{x}_2 = x_1
\\end{array}
```
"""
@def_discrete_system mutable struct GingerbreadmanSystem{RH, RO, IP, OP} <: AbstractDiscreteSystem
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


"""
    $(TYPEDEF)

# Fields 

    $(TYPEDFIELDS)
    
LogisticSystem with the dynamics 
```math
\\begin{array}{l}
    \\dot{x} = r x (1 - x)
\\end{array}
```
"""
@def_discrete_system mutable struct LogisticSystem{RH, RO, IP, OP} <: AbstractDiscreteSystem
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

