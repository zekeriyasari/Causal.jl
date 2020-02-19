# This file contains ODESystem prototypes

import ....Components.ComponentsBase: @generic_system_fields, @generic_dynamic_system_fields, AbstractODESystem

const ODEAlg = Tsit5()


@doc raw"""
    ODESystem(input, output, statefunc, outputfunc, state, t,; solver=ODESolver)

Constructs an `ODESystem` with `input` and `output`. `statefunc` is the state function and `outputfunc` is the output function. `ODESystem` is represented by the equations.
```math 
    \begin{array}{l}
        \dot{x} = f(x, u, t) \\[0.25cm]
        y = g(x, u, t)
    \end{array}
```
where ``t`` is the time `t`, ``x`` is `state`, ``u`` is the value of `input`, ``y`` is the value of `output`. ``f`` is `statefunc` and ``g`` is `outputfunc`. `solver` is used to solve the above differential equation.

The signature of `statefunc` must be of the form,
```julia 
function statefunc(dx, x, u, t)
    dx .= ... # Update dx 
end
```
and the signature of `outputfunc` must be of the form,
```julia 
function outputfunc(x, u, t)
    y = ... # Compute y
    return y
end
```

# Example 
```jldoctest
julia> sfunc(dx,x,u,t) = (dx .= 0.5x)
sfunc (generic function with 1 method)

julia> ofunc(x, u, t) = x
ofunc (generic function with 1 method)

julia> ds = ODESystem(Bus(1), Bus(1), sfunc, ofunc, [1.], 0.)
ODESystem(state:[1.0], t:0.0, input:Bus(nlinks:1, eltype:Link{Float64}, isreadable:false, iswritable:false), output:Bus(nlinks:1, eltype:Link{Float64}, isreadable:false, iswritable:false))
```
"""
mutable struct ODESystem{IB, OB, T, H, SF, OF, ST, I} <: AbstractODESystem
    @generic_dynamic_system_fields
    function ODESystem(input, output, statefunc, outputfunc, state, t, args...; alg=ODEAlg, kwargs...)
        trigger = Link()
        handshake = Link(Bool)
        integrator = construct_integrator(ODEProblem, input, statefunc, state, t, alg, args...; kwargs...)
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state),  typeof(integrator)}(input, output, trigger, handshake, Callback[], uuid4(), 
            statefunc, outputfunc, state, t, integrator)
    end
end

##### LinearSystem
@doc raw"""
    LinearSystem(input, output; A=fill(-1, 1, 1), B=fill(0, 1, 1), C=fill(1, 1, 1), D=fill(0, 1, 1), 
        state=rand(size(A,1)), t=0., solver=ODESolver)

Constructs a `LinearSystem` with `input` and `output`. The `LinearSystem` is represented by the following state and output equations.
```math
\begin{array}{l}
    \dot{x} = A x + B u \\[0.25cm]
    y = C x + D u 
\end{array}
```
where ``x`` is `state`. `solver` is used to solve the above differential equation.
"""
mutable struct LinearSystem{IB, OB, T, H, SF, OF, ST, I} <: AbstractODESystem
    @generic_dynamic_system_fields
    A::Matrix{Float64}
    B::Matrix{Float64}
    C::Matrix{Float64}
    D::Matrix{Float64}
    function LinearSystem(input, output, args...; A=fill(-1, 1, 1), B=fill(0, 1, 1), C=fill(1, 1, 1), D=fill(0, 1, 1), 
        state=rand(size(A,1)), t=0, alg=ODEAlg, kwargs...)
        trigger = Link()
        handshake = Link(Bool)
        if input === nothing
            statefunc = (dx, x, u, t) -> (dx .= A * x)
            outputfunc = (x, u, t) -> (C * x)
        else
            statefunc = (dx, x, u, t) -> (dx .= A * x + B * map(ui -> ui(t), u.funcs))
            if C === nothing || D === nothing
                outputfunc = nothing
            else
                outputfunc = (x, u, t) -> (C * x + D * map(ui -> ui(t), u.funcs))
            end
        end
        integrator = construct_integrator(ODEProblem, input, statefunc, state, t, alg, args...; kwargs...)
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state), typeof(integrator)}(input, output, trigger, handshake, Callback[], uuid4(), 
            statefunc, outputfunc, state, t, integrator, A, B, C, D)
    end
end


##### Lorenz System
@doc raw"""
    LorenzSystem(input, output; sigma=10, beta=8/3, rho=28, gamma=1, outputfunc=allstates, state=rand(3), t=0.,
        solver=ODESolver, cplmat=diagm([1., 1., 1.]))

Constructs a `LorenzSystem` with `input` and `output`. `sigma`, `beta`, `rho` and `gamma` is the system parameters. If `input` is `nothing`, the state equation of `LorenzSystem` is 
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
mutable struct LorenzSystem{IB, OB, T, H, SF, OF, ST, I} <: AbstractODESystem
    @generic_dynamic_system_fields
    sigma::Float64
    beta::Float64
    rho::Float64
    gamma::Float64
    function LorenzSystem(input, output, args...; sigma=10, beta=8/3, rho=28, gamma=1, outputfunc=allstates, state=rand(3), t=0.,
        alg=ODEAlg, cplmat=diagm([1., 1., 1.]), kwargs...)
        if input === nothing
            statefunc = (dx, x, u, t) -> begin
                dx[1] = sigma * (x[2] - x[1])
                dx[2] = x[1] * (rho - x[3]) - x[2]
                dx[3] = x[1] * x[2] - beta * x[3]
                dx .*= gamma
            end
        else
            statefunc = (dx, x, u, t) -> begin
                dx[1] = sigma * (x[2] - x[1])
                dx[2] = x[1] * (rho - x[3]) - x[2]
                dx[3] = x[1] * x[2] - beta * x[3]
                dx .*= gamma
                dx .+= cplmat * map(ui -> ui(t), u.funcs)   # Couple inputs
            end
        end
        trigger = Link()
        handshake = Link(Bool)
        integrator = construct_integrator(ODEProblem, input, statefunc, state, t, alg, args...; kwargs...)
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state), typeof(integrator)}(input, output, trigger, handshake, Callback[], uuid4(), 
            statefunc, outputfunc, state, t, integrator, sigma, beta, rho, gamma)
    end
end

##### Chen System 
@doc raw"""
    ChenSystem(input, output; a=35, b=3, c=28, gamma=1, outputfunc=allstates, state=rand(3), t=0.,
        solver=ODESolver, cplmat=diagm([1., 1., 1.]))

Constructs a `ChenSystem` with `input` and `output`. `a`, `b`, `c` and `gamma` is the system parameters. If `input` is `nothing`, the state equation of `LorenzSystem` is 
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
mutable struct ChenSystem{IB, OB, T, H, SF, OF, ST, I} <: AbstractODESystem
    @generic_dynamic_system_fields
    a::Float64
    b::Float64
    c::Float64
    gamma::Float64
    function ChenSystem(input, output, args...; a=35, b=3, c=28, gamma=1, outputfunc=allstates, state=rand(3), t=0.,
        alg=ODEAlg, cplmat=diagm([1., 1., 1.]), kwargs...)
        if input === nothing
            statefunc = (dx, x, u, t) -> begin
                dx[1] = a * (x[2] - x[1])
                dx[2] = (c - a) * x[1] + c * x[2] - x[1] * x[3]
                dx[3] = x[1] * x[2] - b * x[3]
                dx .*= gamma
            end
        else
            statefunc = (dx, x, u, t) -> begin
                dx[1] = a * (x[2] - x[1])
                dx[2] = (c - a) * x[1] + c * x[2] - x[1] * x[3]
                dx[3] = x[1] * x[2] - b * x[3]
                dx .*= gamma
                dx .+= cplmat * map(ui -> ui(t), u.funcs)   # Couple inputs
            end
        end
        trigger = Link()
        handshake = Link(Bool)
        integrator = construct_integrator(ODEProblem, input, statefunc, state, t, alg, args...; kwargs...)
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state), typeof(integrator)}(input, output, trigger, handshake, Callback[], uuid4(), 
            statefunc, outputfunc, state, t, integrator, a, b, c, gamma)
    end
end


##### Chua System
struct PiecewiseLinearDiode
    m0::Float64
    m1::Float64
    m2::Float64
    bp1::Float64
    bp2::Float64
end
PiecewiseLinearDiode() = PiecewiseLinearDiode(-1.143, -0.714, 5., 1., 5.)

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


struct PolynomialDiode
    a::Float64
    b::Float64
end
PolynomialDiode() = PolynomialDiode(1/16, -1/6)

(d::PolynomialDiode)(x) = d.a * x^3 + d.b * x


@doc raw"""
    ChuaSystem(input, output; diode=PiecewiseLinearDiode(), alpha=15.6, beta=28., gamma=1., 
        outputfunc=allstates, state=rand(3), t=0., solver=ODESolver, cplmat=diagm([1., 1., 1.]))

Constructs a `ChuaSystem` with `input` and `output`. `diode`, `alpha`, `beta` and `gamma` is the system parameters. If `input` is `nothing`, the state equation of `LorenzSystem` is 
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
mutable struct ChuaSystem{IB, OB, T, H, SF, OF, ST, I, DT} <: AbstractODESystem
    @generic_dynamic_system_fields
    diode::DT
    alpha::Float64
    beta::Float64
    gamma::Float64
    function ChuaSystem(input, output, args...; diode=PiecewiseLinearDiode(), alpha=15.6, beta=28., gamma=1., 
        outputfunc=allstates, state=rand(3), t=0., alg=ODEAlg, cplmat=diagm([1., 1., 1.]), kwargs...)
        if input === nothing
            statefunc = (dx, x, u, t) -> begin
                dx[1] = alpha * (x[2] - x[1] - diode(x[1]))
                dx[2] = x[1] - x[2] + x[3]
                dx[3] = -beta * x[2]
                dx .*= gamma
            end
        else
            statefunc = (dx, x, u, t) -> begin
            dx[1] = alpha * (x[2] - x[1] - diode(x[1]))
            dx[2] = x[1] - x[2] + x[3]
            dx[3] = -beta * x[2]
            dx .*= gamma
            dx .+= cplmat * map(ui -> ui(t), u.funcs)
            end
        end
        trigger = Link()
        handshake = Link(Bool)
        integrator = construct_integrator(ODEProblem, input, statefunc, state, t, alg, args...; kwargs...)
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state), typeof(integrator), typeof(diode)}(input, output, trigger, handshake,
            Callback[], uuid4(), statefunc, outputfunc, state, t, integrator, diode, alpha, beta, gamma)
    end
end


##### Rossler System
@doc raw"""
    RosslerSystem(input, output; a=0.38, b=0.3, c=4.82, gamma=1., outputfunc=allstates, state=rand(3), t=0., 
        solver=ODESolver, cplmat=diagm([1., 1., 1.]))

Constructs a `RosllerSystem` with `input` and `output`. `a`, `b`, `c` and `gamma` is the system parameters. If `input` is `nothing`, the state equation of `LorenzSystem` is 
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
mutable struct RosslerSystem{IB, OB, T, H, SF, OF, ST, I} <: AbstractODESystem
    @generic_dynamic_system_fields
    a::Float64
    b::Float64
    c::Float64
    gamma::Float64
    function RosslerSystem(input, output, args...; a=0.38, b=0.3, c=4.82, gamma=1., outputfunc=allstates, state=rand(3), t=0., 
        alg=ODEAlg, cplmat=diagm([1., 1., 1.]), kwargs...)
        if input === nothing
            statefunc = (dx, x, u, t) -> begin
                dx[1] = -x[2] - x[3]
                dx[2] = x[1] + a * x[2]
                dx[3] = b + x[3] * (x[1] - c)
                dx .*= gamma
            end
        else
            statefunc = (dx, x, u, t) -> begin
                dx[1] = -x[2] - x[3]
                dx[2] = x[1] + a * x[2]
                dx[3] = b + x[3] * (x[1] - c)
                dx .+= cplmat * map(ui -> ui(t), u.funcs)
                dx .*= gamma
            end
        end
        trigger = Link() 
        handshake = Link(Bool)
        integrator = construct_integrator(ODEProblem, input, statefunc, state, t, alg, args...; kwargs...)
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state), typeof(integrator)}(input, output, trigger, handshake, Callback[], uuid4(), 
            statefunc, outputfunc, state, t, integrator, a, b, c, gamma)
    end
end


##### Vanderpol System
@doc raw"""
    VanderpolSystem(input, output; mu=5., gamma=1., outputfunc=allstates, state=rand(2), t=0., 
        solver=ODESolver, cplmat=diagm([1., 1]))

Constructs a `VanderpolSystem` with `input` and `output`. `mu` and `gamma` is the system parameters. If `input` is `nothing`, the state equation of `LorenzSystem` is 
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
mutable struct VanderpolSystem{IB, OB, T, H, SF, OF, ST, I} <: AbstractODESystem
    @generic_dynamic_system_fields
    mu::Float64
    gamma::Float64
    function VanderpolSystem(input, output, args...; mu=5., gamma=1., outputfunc=allstates, state=rand(2), t=0., 
        alg=ODEAlg, cplmat=diagm([1., 1]), kwargs...)
        if input === nothing
            statefunc = (dx, x, u, t) -> begin
                dx[1] = x[2]
                dx[2] = -mu * (x[1]^2 - 1) * x[2] - x[1]
                dx .*= gamma
            end
        else
            statefunc = (dx, x, u, t) -> begin
                dx[1] = x[2] 
                dx[2] = -mu * (x[1]^2 - 1) * x[2] - x[1]
                dx .*= gamma
                dx .+= cplmat * map(ui -> ui(t), u.funcs)
            end
        end
        trigger = Link()
        handshake = Link(Bool)
        integrator = construct_integrator(ODEProblem, input, statefunc, state, t, alg, args...; kwargs...)
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state), typeof(integrator)}(input, output, trigger, handshake, Callback[], uuid4(), 
            statefunc, outputfunc, state, t, integrator, mu, gamma)
    end
end
  

##### Pretty-printing 
show(io::IO, ds::ODESystem) = println(io, 
    "ODESystem(state:$(ds.state), t:$(ds.t), input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
show(io::IO, ds::LinearSystem) = print(io, 
    "Linearystem(A:$(ds.A), B:$(ds.B), C:$(ds.C), D:$(ds.D), state:$(ds.state), t:$(ds.t), ",
    "input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
show(io::IO, ds::LorenzSystem) = print(io, 
    "LorenzSystem(sigma:$(ds.sigma), beta:$(ds.beta), rho:$(ds.rho), gamma:$(ds.gamma), state:$(ds.state), t:$(ds.t), ",
    "input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
show(io::IO, ds::ChenSystem) = print(io, 
    "ChenSystem(a:$(ds.a), b:$(ds.b), c:$(ds.c), gamma:$(ds.gamma), state:$(ds.state), t:$(ds.t), ",
    "input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
show(io::IO, d::PiecewiseLinearDiode) = print(io, 
    "PiecewiseLinearDiode(m0:$(d.m0), m1:$(d.m1), m2:$(d.m2), bp1:$(d.bp1), bp2:$(d.bp2))")
show(io::IO, d::PolynomialDiode) = print(io, "PolynomialDiode(a:$(d.a), b:$(d.b))")
show(io::IO, ds::ChuaSystem) = print(io, 
    "ChuaSystem(diode:$(ds.diode), alpha:$(ds.alpha), beta:$(ds.beta), gamma:$(ds.gamma), state:$(ds.state), ",
    "t:$(ds.t), input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
show(io::IO, ds::RosslerSystem) = print(io, 
    "RosslerSystem(a:$(ds.a), b:$(ds.b), c:$(ds.c), gamma:$(ds.gamma), state:$(ds.state), t:$(ds.t), ",
    "input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
show(io::IO, ds::VanderpolSystem) = print(io, 
    "VanderpolSystem(mu:$(ds.mu), gamma:$(ds.gamma), state:$(ds.state), t:$(ds.t), ",
    "input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
