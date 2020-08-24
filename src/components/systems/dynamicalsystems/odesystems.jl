# This file contains ODESystem prototypes

import DifferentialEquations: Tsit5, ODEProblem
import UUIDs: uuid4


"""
    @def_ode_system ex 

where `ex` is the expression to define to define a new AbstractODESystem component type. The usage is as follows:
```julia
@def_ode_system mutable struct MyODESystem{T1,T2,T3,...,TN,OP,RH,RO,ST,IP,OP} <: AbstractODESystem
    param1::T1 = param1_default                     # optional field 
    param2::T2 = param2_default                     # optional field 
    param3::T3 = param3_default                     # optional field
        ⋮
    paramN::TN = paramN_default                     # optional field 
    righthandside::RH = righthandeside_function     # mandatory field
    readout::RO = readout_function                  # mandatory field
    state::ST = state_default                       # mandatory field
    input::IP = input_default                       # mandatory field
    output::OP = output_default                     # mandatory field 
end
```
Here, `MyODESystem` has `N` parameters. `MyODESystem` is represented by the `righthandside` and `readout` function. `state`, `input` and `output` is the state, input port and output port of `MyODESystem`.

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
    New ODE system must be a subtype of `AbstractODESystem` to function properly. 

!!! warning 
    New ODE system must be mutable type.

# Example 
```jldoctest 
julia> @def_ode_system mutable struct MyODESystem{RH, RO, IP, OP} <: AbstractODESystem 
       α::Float64 = 1. 
       β::Float64 = 2. 
       righthandside::RH = (dx, x, u, t, α=α) -> (dx[1] = α * x[1] + u[1](t))
       readout::RO = (x, u, t) -> x
       state::Vector{Float64} = [1.]
       input::IP = Inport(1) 
       output::OP = Outport(1) 
       end

julia> ds = MyODESystem();

julia> ds.input 
1-element Inport{Inpin{Float64}}:
 Inpin(eltype:Float64, isbound:false)
```
"""
macro def_ode_system(ex) 
    checksyntax(ex, :AbstractODESystem)
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
        solverkwargs::$(SOLVER_KWARGS_TYPE_SYMBOL) = NamedTuple() 
        alg::$(ALG_TYPE_SYMBOL) = Causal.Tsit5()
        integrator::$(INTEGRATOR_TYPE_SYMBOL) = Causal.construct_integrator(Causal.ODEProblem, input, righthandside, state, t, modelargs, 
            solverargs; alg=alg, modelkwargs=modelkwargs, solverkwargs=solverkwargs, numtaps=3)
    end, [TRIGGER_TYPE_SYMBOL, HANDSHAKE_TYPE_SYMBOL, CALLBACKS_TYPE_SYMBOL, ID_TYPE_SYMBOL, MODEL_ARGS_TYPE_SYMBOL, MODEL_KWARGS_TYPE_SYMBOL, SOLVER_ARGS_TYPE_SYMBOL, SOLVER_KWARGS_TYPE_SYMBOL, ALG_TYPE_SYMBOL, INTEGRATOR_TYPE_SYMBOL]
    _append_common_fields!(ex, fields...)
    deftype(ex)
end


#### Define ODE system library.

"""
    ODESystem(;righthandside, readout, state, input, output) 

Constructs a generic ODE system.

# Example
```jldoctest
julia> ds = ODESystem(righthandside=(dx,x,u,t)->(dx.=-x), readout=(x,u,t)->x, state=[1.],input=nothing, output=Outport(1));

julia> ds.state
1-element Array{Float64,1}:
 1.0
```
"""
@def_ode_system mutable struct ODESystem{RH, RO, ST, IP, OP} <: AbstractODESystem 
    righthandside::RH 
    readout::RO 
    state::ST 
    input::IP 
    output::OP
end

@doc raw"""
    ContinuousLinearSystem(input, output, modelargs=(), solverargs=(); 
        A=fill(-1, 1, 1), B=fill(0, 1, 1), C=fill(1, 1, 1), D=fill(0, 1, 1), state=rand(size(A,1)), t=0., 
        alg=ODEAlg, modelkwargs=NamedTuple(), solverkwargs=NamedTuple())

Constructs a `ContinuousLinearSystem` with `input` and `output`. `state` is the initial state and `t` is the time. `modelargs` and `modelkwargs` are passed into `ODEProblem` and `solverargs` and `solverkwargs` are passed into `solve` method of `DifferentialEquations`. `alg` is the algorithm to solve the differential equation of the system.

The `ContinuousLinearSystem` is represented by the following state and output equations.
```math
\begin{array}{l}
    \dot{x} = A x + B u \\[0.25cm]
    y = C x + D u 
\end{array}
```
where ``x`` is `state`. `solver` is used to solve the above differential equation.
"""
@def_ode_system mutable struct ContinuousLinearSystem{IP, OP, RH, RO} <: AbstractODESystem
    A::Matrix{Float64} = fill(-1., 1, 1)
    B::Matrix{Float64} = fill(1., 1, 1)
    C::Matrix{Float64} = fill(1., 1, 1)
    D::Matrix{Float64} = fill(0., 1, 1)
    input::IP = Inport(1)
    output::OP = Outport(1)
    state::Vector{Float64} = rand(size(A, 1))
    righthandside::RH = input === nothing ? (dx, x, u, t) -> (dx .= A * x) : 
        (dx, x, u, t) -> (dx .= A * x + B * map(ui -> ui(t), u.itp))
    readout::RO = input === nothing ? (x, u, t) -> (C * x) : 
           ( (C === nothing || D === nothing) ? nothing : (x, u, t) -> (C * x + D * map(ui -> ui(t), u)) )
end


@doc raw"""
    LorenzSystem(input, output, modelargs=(), solverargs=(); 
        sigma=10, beta=8/3, rho=28, gamma=1, outputfunc=allstates, state=rand(3), t=0.,
        alg=ODEAlg, cplmat=diagm([1., 1., 1.]), modelkwargs=NamedTuple(), solverkwargs=NamedTuple())

Constructs a `LorenzSystem` with `input` and `output`. `sigma`, `beta`, `rho` and `gamma` is the system parameters. `state` is the initial state and `t` is the time. `modelargs` and `modelkwargs` are passed into `ODEProblem` and `solverargs` and `solverkwargs` are passed into `solve` method of `DifferentialEquations`. `alg` is the algorithm to solve the differential equation of the system.

If `input` is `nothing`, the state equation of `LorenzSystem` is 
```math
\begin{array}{l}
    \dot{x}_1 = \gamma (\sigma (x_2 - x_1)) \\[0.25cm]
    \dot{x}_2 = \gamma (x_1 (\rho - x_3) - x_2) \\[0.25cm]
    \dot{x}_3 = \gamma (x_1 x_2 - \beta x_3) 
\end{array}
```
where ``x`` is `state`. `solver` is used to solve the above differential equation. If `input` is not `nothing`, then the state eqaution is
```math
\begin{array}{l}
    \dot{x}_1 = \gamma (\sigma (x_2 - x_1)) + \sum_{j = 1}^3 \alpha_{1j} u_j \\[0.25cm]
    \dot{x}_2 = \gamma (x_1 (\rho - x_3) - x_2) + \sum_{j = 1}^3 \alpha_{2j} u_j \\[0.25cm]
    \dot{x}_3 = \gamma (x_1 x_2 - \beta x_3) + \sum_{j = 1}^3 \alpha_{3j} u_j 
\end{array}
```
where ``A = [\alpha_{ij}]`` is `cplmat` and ``u = [u_{j}]`` is the value of the `input`. The output function is 
```math
    y = g(x, u, t)
```
where ``t`` is time `t`, ``y`` is the value of the `output` and ``g`` is `outputfunc`.
"""
@def_ode_system mutable struct LorenzSystem{RH, RO, IP, OP} <: AbstractODESystem
    σ::Float64 = 10.
    β::Float64 = 8 / 3
    ρ::Float64 = 28.
    γ::Float64 = 1.
    righthandside::RH = function lorenzrhs(dx, x, u, t, σ=σ, β=β, ρ=ρ, γ=γ)
        dx[1] = σ * (x[2] - x[1])
        dx[2] = x[1] * (ρ - x[3]) - x[2]
        dx[3] = x[1] * x[2] - β * x[3]
        dx .*= γ
    end
    readout::RO = (x, u, t) -> x
    state::Vector{Float64} = rand(3)
    input::IP = nothing 
    output::OP = Outport(3) 
end  


"""
    ForcedLorenzSystem() 

Constructs a LorenzSystem that is driven by its inputs.
"""
@def_ode_system mutable struct ForcedLorenzSystem{CM, RH, RO, IP, OP} <: AbstractODESystem
    σ::Float64 = 10. 
    β::Float64 = 8 / 3 
    ρ::Float64 = 28.
    γ::Float64 = 1.
    cplmat::CM = I(3)
    righthandside::RH = function lorenzrhs(dx, x, u, t, σ=σ, β=β, ρ=ρ, γ=γ, cplmat=cplmat)
        dx[1] = σ * (x[2] - x[1])
        dx[2] = x[1] * (ρ - x[3]) - x[2]
        dx[3] = x[1] * x[2] - β * x[3]
        dx .*= γ
        dx .+= cplmat * map(ui -> ui(t), u.itp)   # Couple inputs
    end
    readout::RO = (x, u, t) -> x
    state::Vector{Float64} = rand(3)
    input::IP = Inport(3)
    output::OP = Outport(3) 
end  


@doc raw"""
    ChenSystem(input, output, modelargs=(), solverargs=(); 
        a=35, b=3, c=28, gamma=1, outputfunc=allstates, state=rand(3), t=0.,
        alg=ODEAlg, cplmat=diagm([1., 1., 1.]), modelkwargs=NamedTuple(), solverkwargs=NamedTuple())

Constructs a `ChenSystem` with `input` and `output`. `a`, `b`, `c` and `gamma` is the system parameters. `state` is the initial state and `t` is the time. `modelargs` and `modelkwargs` are passed into `ODEProblem` and `solverargs` and `solverkwargs` are passed into `solve` method of `DifferentialEquations`. `alg` is the algorithm to solve the differential equation of the system.

If `input` is `nothing`, the state equation of `ChenSystem` is 
```math
\begin{array}{l}
    \dot{x}_1 = \gamma (a (x_2 - x_1)) \\[0.25cm]
    \dot{x}_2 = \gamma ((c - a) x_1 + c x_2 + x_1 x_3) \\[0.25cm]
    \dot{x}_3 = \gamma (x_1 x_2 - b x_3) 
\end{array}
```
where ``x`` is `state`. `solver` is used to solve the above differential equation. If `input` is not `nothing`, then the state eqaution is
```math
\begin{array}{l}
    \dot{x}_1 = \gamma (a (x_2 - x_1)) + \sum_{j = 1}^3 \alpha_{1j} u_j \\[0.25cm]
    \dot{x}_2 = \gamma ((c - a) x_1 + c x_2 + x_1 x_3) + \sum_{j = 1}^3 \alpha_{2j} u_j \\[0.25cm]
    \dot{x}_3 = \gamma (x_1 x_2 - b x_3) + \sum_{j = 1}^3 \alpha_{3j} u_j 
\end{array}
```
where ``A = [\alpha_{ij}]`` is `cplmat` and ``u = [u_{j}]`` is the value of the `input`. The output function is 
```math
    y = g(x, u, t)
```
where ``t`` is time `t`, ``y`` is the value of the `output` and ``g`` is `outputfunc`.
""" 
@def_ode_system mutable struct ChenSystem{RH, RO, IP, OP} <: AbstractODESystem
    a::Float64 = 35.
    b::Float64 = 3.
    c::Float64 = 28.
    γ::Float64 = 1.
    righthandside::RH = function chenrhs(dx, x, u, t, a=a, b=b, c=c, γ=γ)
        dx[1] = a * (x[2] - x[1])
        dx[2] = (c - a) * x[1] + c * x[2] - x[1] * x[3]
        dx[3] = x[1] * x[2] - b * x[3]
        dx .*= γ
    end
    readout::RO = (x, u, t) -> x
    state::Vector{Float64} = rand(3)
    input::IP = nothing 
    output::OP = Outport(3)
end


"""
    ForcedChenSystem() 

Constructs Chen system driven by its inputs.
"""
@def_ode_system mutable struct ForcedChenSystem{CM, RH, RO, IP, OP} <: AbstractODESystem
    a::Float64 = 35.
    b::Float64 = 3.
    c::Float64 = 28.
    γ::Float64 = 1.
    cplmat::CM = I(3)
    righthandside::RH = function chenrhs(dx, x, u, t, a=a, b=b, c=c, γ=γ)
        dx[1] = a * (x[2] - x[1])
        dx[2] = (c - a) * x[1] + c * x[2] - x[1] * x[3]
        dx[3] = x[1] * x[2] - b * x[3]
        dx .*= γ
        dx .+= cplmat * map(ui -> ui(t), u.itp)   # Couple inputs
    end
    readout::RO = (x, u, t) -> x
    state::Vector{Float64} = rand(3)
    input::IP = Inport(3)
    output::OP = Outport(3)
end


Base.@kwdef struct PiecewiseLinearDiode
    m0::Float64 = -1.143
    m1::Float64 = -0.714
    m2::Float64 = 5.
    bp1::Float64 = 1.
    bp2::Float64 = 5.
end
@inline function (d::PiecewiseLinearDiode)(x)
    m0, m1, m2, bp1, bp2 = d.m0, d.m1, d.m2, d.bp1, d.bp2
    if x < -bp2
        return m2 * x + (m2 - m1) * bp2 + (m1 - m0) * bp1
    elseif -bp2 <= x < -bp1
        return m1 * x + (m1 - m0) * bp1
    elseif -bp1 <= x < bp1
        return m0 * x
    elseif bp1 <= x < bp2
        return m1 * x +  (m0 - m1) * bp1
    else
        return m2 * x + (m1 - m2) * bp2 + (m0 - m1) * bp1
    end
end


Base.@kwdef struct PolynomialDiode
    a::Float64 = 1 / 16 
    b::Float64 = - 1 / 6
end
(d::PolynomialDiode)(x) = d.a * x^3 + d.b * x


@doc raw"""
    ChuaSystem(input, output, modelargs=(), solverargs=(); 
        diode=PiecewiseLinearDiode(), alpha=15.6, beta=28., gamma=1., outputfunc=allstates, state=rand(3), t=0., 
        alg=ODEAlg, cplmat=diagm([1., 1., 1.]), modelkwargs=NamedTuple(), solverkwargs=NamedTuple())

Constructs a `ChuaSystem` with `input` and `output`. `diode`, `alpha`, `beta` and `gamma` is the system parameters. `state` is the initial state and `t` is the time. `modelargs` and `modelkwargs` are passed into `ODEProblem` and `solverargs` and `solverkwargs` are passed into `solve` method of `DifferentialEquations`. `alg` is the algorithm to solve the differential equation of the system.

If `input` is `nothing`, the state equation of `ChuaSystem` is 
```math
\begin{array}{l}
    \dot{x}_1 = \gamma (\alpha (x_2 - x_1 - h(x_1))) \\[0.25cm]
    \dot{x}_2 = \gamma (x_1 - x_2 + x_3 ) \\[0.25cm]
    \dot{x}_3 = \gamma (-\beta x_2) 
\end{array}
```
where ``x`` is `state`. `solver` is used to solve the above differential equation. If `input` is not `nothing`, then the state eqaution is
```math
\begin{array}{l}
    \dot{x}_1 = \gamma (\alpha (x_2 - x_1 - h(x_1))) + \sum_{j = 1}^3 \theta_{1j} u_j \\[0.25cm]
    \dot{x}_2 = \gamma (x_1 - x_2 + x_3 ) + \sum_{j = 1}^3 \theta_{2j} u_j \\[0.25cm]
    \dot{x}_3 = \gamma (-\beta x_2) + \sum_{j = 1}^3 \theta_{3j} u_j 
\end{array}
```
where ``\Theta = [\theta_{ij}]`` is `cplmat` and ``u = [u_{j}]`` is the value of the `input`. The output function is 
```math
    y = g(x, u, t)
```
where ``t`` is time `t`, ``y`` is the value of the `output` and ``g`` is `outputfunc`.
"""
@def_ode_system mutable struct ChuaSystem{DT,RH, RO, IP, OP} <: AbstractODESystem
    diode::DT = PiecewiseLinearDiode()
    α::Float64 = 15.6
    β::Float64 = 28.
    γ::Float64 = 1.
    righthandside::RH = function chuarhs(dx, x, u, t, diode=diode, α=α, β=β, γ=γ)
        dx[1] = α * (x[2] - x[1] - diode(x[1]))
        dx[2] = x[1] - x[2] + x[3]
        dx[3] = -β * x[2]
        dx .*= γ
    end
    readout::RO = (x, u, t) -> x
    state::Vector{Float64} = rand(3)
    input::IP = nothing 
    output::OP = Outport(3)
end

"""
    ForcedChuaSystem() 

Constructs a Chua system with inputs.
"""
@def_ode_system mutable struct ForcedChuaSystem{DT, CM, RH, RO, IP, OP} <: AbstractODESystem
    diode::DT = PiecewiseLinearDiode()
    α::Float64 = 15.6
    β::Float64 = 28.
    γ::Float64 = 1.
    cplmat::CM = I(3)
    righthandside::RH = function chuarhs(dx, x, u, t, diode=diode, α=α, β=β, γ=γ)
        dx[1] = α * (x[2] - x[1] - diode(x[1]))
        dx[2] = x[1] - x[2] + x[3]
        dx[3] = -β * x[2]
        dx .*= γ
        dx .+= cplmat * map(ui -> ui(t), u.itp)   # Couple inputs
    end
    readout::RO = (x, u, t) -> x
    state::Vector{Float64} = rand(3)
    input::IP = Inport(3)
    output::OP = Outport(3)
end


@doc raw"""
    RosslerSystem(input, output, modelargs=(), solverargs=(); 
        a=0.38, b=0.3, c=4.82, gamma=1., outputfunc=allstates, state=rand(3), t=0., 
        alg=ODEAlg, cplmat=diagm([1., 1., 1.]), modelkwargs=NamedTuple(), solverkwargs=NamedTuple())

Constructs a `RosllerSystem` with `input` and `output`. `a`, `b`, `c` and `gamma` is the system parameters. `state` is the initial state and `t` is the time. `modelargs` and `modelkwargs` are passed into `ODEProblem` and `solverargs` and `solverkwargs` are passed into `solve` method of `DifferentialEquations`. `alg` is the algorithm to solve the differential equation of the system.

If `input` is `nothing`, the state equation of `RosslerSystem` is 
```math
\begin{array}{l}
    \dot{x}_1 = \gamma (-x_2 - x_3) \\[0.25cm]
    \dot{x}_2 = \gamma (x_1 + a x_2) \\[0.25cm]
    \dot{x}_3 = \gamma (b + x_3 (x_1 - c))
\end{array}
```
where ``x`` is `state`. `solver` is used to solve the above differential equation. If `input` is not `nothing`, then the state eqaution is
```math
\begin{array}{l}
    \dot{x}_1 = \gamma (-x_2 - x_3) + \sum_{j = 1}^3 \theta_{1j} u_j \\[0.25cm]
    \dot{x}_2 = \gamma (x_1 + a x_2 ) + \sum_{j = 1}^3 \theta_{2j} u_j \\[0.25cm]
    \dot{x}_3 = \gamma (b + x_3 (x_1 - c)) + \sum_{j = 1}^3 \theta_{3j} u_j 
\end{array}
```
where ``\Theta = [\theta_{ij}]`` is `cplmat` and ``u = [u_{j}]`` is the value of the `input`. The output function is 
```math
    y = g(x, u, t)
```
where ``t`` is time `t`, ``y`` is the value of the `output` and ``g`` is `outputfunc`.
"""
@def_ode_system mutable struct RosslerSystem{RH, RO, IP, OP} <: AbstractODESystem
    a::Float64 = 0.38
    b::Float64 = 0.3
    c::Float64 = 4.82
    γ::Float64 = 1.
    righthandside::RH = function rosslerrhs(dx, x, u, t, a=a, b=b, c=c, γ=γ)
        dx[1] = -x[2] - x[3]
        dx[2] = x[1] + a * x[2]
        dx[3] = b + x[3] * (x[1] - c)
        dx .*= γ
    end
    readout::RO = (x, u, t) -> x
    state::Vector{Float64} = rand(3)
    input::IP = nothing
    output::OP = Outport(3)
end

"""
    ForcedRosslerSystem()

Constructs a Rossler system driven by its input.
"""
@def_ode_system mutable struct ForcedRosslerSystem{CM, RH, RO, IP, OP} <: AbstractODESystem
    a::Float64 = 0.38
    b::Float64 = 0.3
    c::Float64 = 4.82
    γ::Float64 = 1.
    cplmat::CM = I(3)
    righthandside::RH = function rosslerrhs(dx, x, u, t, a=a, b=b, c=c, γ=γ)
        dx[1] = -x[2] - x[3]
        dx[2] = x[1] + a * x[2]
        dx[3] = b + x[3] * (x[1] - c)
        dx .*= γ
        dx .+= cplmat * map(ui -> ui(t), u.itp)   # Couple inputs
    end
    readout::RO = (x, u, t) -> x
    state::Vector{Float64} = rand(3)
    input::IP = Inport(3)
    output::OP = Outport(3)
end


@doc raw"""
    VanderpolSystem(input, output, modelargs=(), solverargs=(); 
        mu=5., gamma=1., outputfunc=allstates, state=rand(2), t=0., 
        alg=ODEAlg, cplmat=diagm([1., 1]), modelkwargs=NamedTuple(), solverkwargs=NamedTuple())

Constructs a `VanderpolSystem` with `input` and `output`. `mu` and `gamma` is the system parameters. `state` is the initial state and `t` is the time. `modelargs` and `modelkwargs` are passed into `ODEProblem` and `solverargs` and `solverkwargs` are passed into `solve` method of `DifferentialEquations`. `alg` is the algorithm to solve the differential equation of the system.

If `input` is `nothing`, the state equation of `VanderpolSystem` is 
```math
\begin{array}{l}
    \dot{x}_1 = \gamma (x_2) \\[0.25cm]
    \dot{x}_2 = \gamma (\mu (x_1^2 - 1) x_2 - x_1 )
\end{array}
```
where ``x`` is `state`. `solver` is used to solve the above differential equation. If `input` is not `nothing`, then the state eqaution is
```math
\begin{array}{l}
    \dot{x}_1 = \gamma (x_2) + \sum_{j = 1}^3 \theta_{1j} u_j \\[0.25cm]
    \dot{x}_2 = \gamma (\mu (x_1^2 - 1) x_2 - x_1) + \sum_{j = 1}^3 \theta_{2j} u_j 
\end{array}
```
where ``\Theta = [\theta_{ij}]`` is `cplmat` and ``u = [u_{j}]`` is the value of the `input`. The output function is 
```math
    y = g(x, u, t)
```
where ``t`` is time `t`, ``y`` is the value of the `output` and ``g`` is `outputfunc`.
"""
@def_ode_system mutable struct VanderpolSystem{RH, RO, IP, OP} <: AbstractODESystem
    μ::Float64 = 5.
    γ::Float64 = 1.
    righthandside::RH = function vanderpolrhs(dx, x, u, t, μ=μ, γ=γ)
        dx[1] = x[2]
        dx[2] = -μ * (x[1]^2 - 1) * x[2] - x[1]
        dx .*= γ
    end
    readout::RO = (x, u, t) -> x
    state::Vector{Float64} = rand(2) 
    input::IP = nothing 
    output::OP = Outport(3)
end

"""
    ForcedVanderpolSystem() 

Constructs a Vanderpol system driven by its input.
"""
@def_ode_system mutable struct ForcedVanderpolSystem{CM, RH, RO, IP, OP} <: AbstractODESystem
    μ::Float64 = 5.
    γ::Float64 = 1.
    cplmat::CM = I(2)
    righthandside::RH = function vanderpolrhs(dx, x, u, t, μ=μ, γ=γ)
        dx[1] = x[2]
        dx[2] = -μ * (x[1]^2 - 1) * x[2] - x[1]
        dx .*= γ
        dx .+= cplmat * map(ui -> ui(t), u.itp)   # Couple inputs
    end
    readout::RO = (x, u, t) -> x
    state::Vector{Float64} = rand(2) 
    input::IP = Inport(2)
    output::OP = Outport(3)
end
  

@doc raw"""
    Integrator(state=zeros(0), t=0., modelargs=(), solverargs=(); 
        alg=ODEAlg, modelkwargs=NamedTuple(), solverkwargs=NamedTuple(), numtaps=numtaps, callbacks=nothing, 
        name=Symbol())

Constructs an integrator whose input output relation is given by 
```math 
u(t) = ki * \int_{0}^{t} u(\tau) d\tau
```
where ``u(t)`` is the input, ``y(t)`` is the output and ``ki`` is the integration constant.
"""
@def_ode_system mutable struct Integrator{RH, RO, IP, OP} <: AbstractODESystem
    ki::Float64 = 1.
    righthandside::RH = (dx, x, u, t) -> (dx[1] = ki * u[1](t))
    readout::RO = (x, u, t) -> x
    state::Vector{Float64} = rand(1)
    input::IP = Inport() 
    output::OP = Outport()
end

##### Pretty-printing 
show(io::IO, ds::ODESystem) = print(io, 
    "ODESystem(righthandside:$(ds.righthandside), readout:$(ds.readout), state:$(ds.state), t:$(ds.t), ",
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::ContinuousLinearSystem) = print(io, 
    "ContinuousLinearSystem(A:$(ds.A), B:$(ds.B), C:$(ds.C), D:$(ds.D), state:$(ds.state), t:$(ds.t), ",
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::LorenzSystem) = print(io, 
    "LorenzSystem(σ:$(ds.σ), β:$(ds.β), ρ:$(ds.ρ), γ:$(ds.γ), state:$(ds.state), t:$(ds.t), ",
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::ForcedLorenzSystem) = print(io, 
    "LorenzSystem(σ:$(ds.σ), β:$(ds.β), ρ:$(ds.ρ), γ:$(ds.γ), cplmat:$(ds.cplmat), state:$(ds.state), t:$(ds.t), ",
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::ChenSystem) = print(io, 
    "ChenSystem(a:$(ds.a), b:$(ds.b), c:$(ds.c), γ:$(ds.γ), state:$(ds.state), t:$(ds.t), ",
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::ForcedChenSystem) = print(io, 
    "ChenSystem(a:$(ds.a), b:$(ds.b), c:$(ds.c), γ:$(ds.γ), cplmat:$(ds.cplmat), state:$(ds.state), t:$(ds.t), ",
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::ChuaSystem) = print(io, 
    "ChuaSystem(diode:$(ds.diode), α:$(ds.α), β:$(ds.β), γ:$(ds.γ), state:$(ds.state), ",
    "t:$(ds.t), input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::ForcedChuaSystem) = print(io, 
    "ChuaSystem(diode:$(ds.diode), α:$(ds.α), β:$(ds.β), γ:$(ds.γ), cplmat:$(ds.cplmat), state:$(ds.state), ",
    "t:$(ds.t), input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::RosslerSystem) = print(io, 
    "RosslerSystem(a:$(ds.a), b:$(ds.b), c:$(ds.c), γ:$(ds.γ), state:$(ds.state), t:$(ds.t), ",
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::ForcedRosslerSystem) = print(io, 
    "RosslerSystem(a:$(ds.a), b:$(ds.b), c:$(ds.c), γ:$(ds.γ), cplmat:$(ds.cplmat), state:$(ds.state), t:$(ds.t), ",
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::VanderpolSystem) = print(io, 
    "VanderpolSystem(μ:$(ds.μ), γ:$(ds.γ), state:$(ds.state), t:$(ds.t), ",
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::ForcedVanderpolSystem) = print(io, 
    "VanderpolSystem(μ:$(ds.μ), γ:$(ds.γ), cplmat:$(ds.cplmat), state:$(ds.state), t:$(ds.t), ",
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::Integrator) = print(io, 
    "Integrator(ki:$(ds.ki), state:$(ds.state), t:$(ds.t), input:$(ds.input), output:$(ds.output))")
