# This file contains ODESystem prototypes


@doc raw"""
    ODESystem(input, output, statefunc, outputfunc, state, t, modelargs=(), solverargs=(); 
        alg=ODEAlg, modelkwargs=NamedTuple(), solverkwargs=NamedTuple())

Constructs an `ODESystem` with `input` and `output`. `statefunc` is the state function and `outputfunc` is the output function. `state` is the initial state and `t` is the time. `modelargs` and `modelkwargs` are passed into `ODEProblem` and `solverargs` and `solverkwargs` are passed into `solve` method of `DifferentialEquations`. `alg` is the algorithm to solve the differential equation of the system.

`ODESystem` is represented by the equations.
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
```julia
julia> sfuncode(dx,x,u,t) = (dx[1] = 0.5x[1] + u[1](t));

julia> ofuncode(x, u, t) = x;

julia> ds = ODESystem(sfuncode, ofuncode, [1.], 0., Inport(), Outport())
ODESystem(state:[1.0], t:0.0, input:Inport(numpins:1, eltype:Inpin{Float64}), output:Outport(numpins:1, eltype:Outpin{Float64}))

julia> ds = ODESystem(sfuncode, ofuncode, [1.], 0., Inport(), Outport(), solverkwargs=(dt=0.1, reltol=1e-6))
ODESystem(state:[1.0], t:0.0, input:Inport(numpins:1, eltype:Inpin{Float64}), output:Outport(numpins:1, eltype:Outpin{Float64}))
```

!!! info 
    See [DifferentialEquations](https://docs.juliadiffeq.org/) for more information about `modelargs`, `modelkwargs`, 
    `solverargs`, `solverkwargs` and `alg`.
"""
mutable struct ODESystem{SF, OF, ST, T, IN, IB, OB, TR, HS, CB} <: AbstractODESystem
    @generic_dynamic_system_fields
    function ODESystem(statefunc, outputfunc, state, t, input, output, modelargs=(), solverargs=(); 
        alg=ODEAlg, modelkwargs=NamedTuple(), solverkwargs=NamedTuple(), numtaps=numtaps, callbacks=nothing, 
        name=Symbol())
        trigger, handshake, integrator = init_dynamic_system(
                ODEProblem, statefunc, state, t, input, modelargs, solverargs; 
                alg=alg, modelkwargs=modelkwargs, solverkwargs=solverkwargs, numtaps=numtaps
            )
        new{typeof(statefunc), typeof(outputfunc), typeof(state), typeof(t), typeof(integrator), typeof(input), 
            typeof(output), typeof(trigger), typeof(handshake), typeof(callbacks)}(statefunc, outputfunc, state, t, 
            integrator, input, output, trigger, handshake, callbacks, name, uuid4())
    end
end

##### LinearSystem
@doc raw"""
    LinearSystem(input, output, modelargs=(), solverargs=(); 
        A=fill(-1, 1, 1), B=fill(0, 1, 1), C=fill(1, 1, 1), D=fill(0, 1, 1), state=rand(size(A,1)), t=0., 
        alg=ODEAlg, modelkwargs=NamedTuple(), solverkwargs=NamedTuple())

Constructs a `LinearSystem` with `input` and `output`. `state` is the initial state and `t` is the time. `modelargs` and `modelkwargs` are passed into `ODEProblem` and `solverargs` and `solverkwargs` are passed into `solve` method of `DifferentialEquations`. `alg` is the algorithm to solve the differential equation of the system.

The `LinearSystem` is represented by the following state and output equations.
```math
\begin{array}{l}
    \dot{x} = A x + B u \\[0.25cm]
    y = C x + D u 
\end{array}
```
where ``x`` is `state`. `solver` is used to solve the above differential equation.
"""
mutable struct LinearSystem{SF, OF, ST, T, IN, IB, OB, TR, HS, CB} <: AbstractODESystem
    @generic_dynamic_system_fields
    A::Matrix{Float64}
    B::Matrix{Float64}
    C::Matrix{Float64}
    D::Matrix{Float64}
    function LinearSystem(input=Inport(), output=Outport(), modelargs=(), solverargs=(); 
        A=fill(-1, 1, 1), B=fill(0, 1, 1), C=fill(1, 1, 1), D=fill(0, 1, 1), state=rand(size(A,1)), t=0., 
        alg=ODEAlg, modelkwargs=NamedTuple(), solverkwargs=NamedTuple(), numtaps=numtaps, callbacks=nothing, 
        name=Symbol())
        if input === nothing
            statefunc = (dx, x, u, t) -> (dx .= A * x)
            outputfunc = (x, u, t) -> (C * x)
        else
            statefunc = (dx, x, u, t) -> (dx .= A * x + B * map(ui -> ui(t), u.itp))
            if C === nothing || D === nothing
                outputfunc = nothing
            else
                outputfunc = (x, u, t) -> (C * x + D * map(ui -> ui(t), u))
            end
        end
        trigger, handshake, integrator = init_dynamic_system(
                ODEProblem, statefunc, state, t, input, modelargs, solverargs; 
                alg=alg, modelkwargs=modelkwargs, solverkwargs=solverkwargs, numtaps=numtaps
            )
        new{typeof(statefunc), typeof(outputfunc), typeof(state), typeof(t), typeof(integrator), typeof(input), 
            typeof(output), typeof(trigger), typeof(handshake), typeof(callbacks)}(statefunc, outputfunc, state, t, 
            integrator, input, output, trigger, handshake, callbacks, name, uuid4(), A, B, C, D)
    end
end


##### Lorenz System
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
mutable struct LorenzSystem{SF, OF, ST, T, IN, IB, OB, TR, HS, CB} <: AbstractODESystem
    @generic_dynamic_system_fields
    sigma::Float64
    beta::Float64
    rho::Float64
    gamma::Float64
    function LorenzSystem(input=nothing, output=Outport(3), modelargs=(), solverargs=(); 
        sigma=10, beta=8/3, rho=28, gamma=1, outputfunc=allstates, state=rand(3), t=0.,
        alg=ODEAlg, cplmat=diagm([1., 1., 1.]), modelkwargs=NamedTuple(), solverkwargs=NamedTuple(), numtaps=numtaps,
        callbacks=nothing, name=Symbol())
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
                dx .+= cplmat * map(ui -> ui(t), u.itp)   # Couple inputs
            end
        end
        trigger, handshake, integrator = init_dynamic_system(
                ODEProblem, statefunc, state, t, input, modelargs, solverargs; 
                alg=alg, modelkwargs=modelkwargs, solverkwargs=solverkwargs, numtaps=numtaps
            )
        new{typeof(statefunc), typeof(outputfunc), typeof(state), typeof(t), typeof(integrator), typeof(input), 
            typeof(output), typeof(trigger), typeof(handshake), typeof(callbacks)}(statefunc, outputfunc, state, t, 
            integrator, input, output, trigger, handshake, callbacks, name, uuid4(), sigma, beta, rho, gamma)
    end
end

##### Chen System 
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
mutable struct ChenSystem{SF, OF, ST, T, IN, IB, OB, TR, HS, CB} <: AbstractODESystem
    @generic_dynamic_system_fields
    a::Float64
    b::Float64
    c::Float64
    gamma::Float64
    function ChenSystem(input=nothing, output=Outport(3), modelargs=(), solverargs=(); 
        a=35, b=3, c=28, gamma=1, outputfunc=allstates, state=rand(3), t=0.,
        alg=ODEAlg, cplmat=diagm([1., 1., 1.]), modelkwargs=NamedTuple(), solverkwargs=NamedTuple(), numtaps=numtaps,
        callbacks=nothing, name=Symbol())
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
                dx .+= cplmat * map(ui -> ui(t), u.itp)   # Couple inputs
            end
        end
        trigger, handshake, integrator = init_dynamic_system(
                ODEProblem, statefunc, state, t, input, modelargs, solverargs; 
                alg=alg, modelkwargs=modelkwargs, solverkwargs=solverkwargs, numtaps=numtaps
            )
        new{typeof(statefunc), typeof(outputfunc), typeof(state), typeof(t), typeof(integrator), typeof(input), 
            typeof(output), typeof(trigger), typeof(handshake), typeof(callbacks)}(statefunc, outputfunc, state, t, 
            integrator, input, output, trigger, handshake, callbacks, name, uuid4(), a, b, c, gamma)
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
mutable struct ChuaSystem{SF, OF, ST, T, IN, IB, OB, TR, HS, CB, DT} <: AbstractODESystem
    @generic_dynamic_system_fields
    diode::DT
    alpha::Float64
    beta::Float64
    gamma::Float64
    function ChuaSystem(input=nothing, output=Outport(3), modelargs=(), solverargs=(); 
        diode=PiecewiseLinearDiode(), alpha=15.6, beta=28., gamma=1., outputfunc=allstates, state=rand(3), t=0., 
        alg=ODEAlg, cplmat=diagm([1., 1., 1.]), modelkwargs=NamedTuple(), solverkwargs=NamedTuple(), numtaps=numtaps, 
        callbacks=nothing, name=Symbol())
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
            dx .+= cplmat * map(ui -> ui(t), u.itp)
            end
        end
        trigger, handshake, integrator = init_dynamic_system(
                ODEProblem, statefunc, state, t, input, modelargs, solverargs; 
                alg=alg, modelkwargs=modelkwargs, solverkwargs=solverkwargs, numtaps=numtaps
            )
        new{typeof(statefunc), typeof(outputfunc), typeof(state), typeof(t), typeof(integrator), typeof(input), 
            typeof(output), typeof(trigger), typeof(handshake), typeof(callbacks), typeof(diode)}(statefunc, 
            outputfunc, state, t, integrator, input, output, trigger, handshake, callbacks, name, uuid4(), diode, alpha, beta, 
            gamma)
    end
end


##### Rossler System
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
mutable struct RosslerSystem{SF, OF, ST, T, IN, IB, OB, TR, HS, CB} <: AbstractODESystem
    @generic_dynamic_system_fields
    a::Float64
    b::Float64
    c::Float64
    gamma::Float64
    function RosslerSystem(input=nothing, output=Outport(3), modelargs=(), solverargs=(); 
        a=0.38, b=0.3, c=4.82, gamma=1., outputfunc=allstates, state=rand(3), t=0., 
        alg=ODEAlg, cplmat=diagm([1., 1., 1.]), modelkwargs=NamedTuple(), solverkwargs=NamedTuple(), numtaps=numtaps,
        callbacks=nothing, name=Symbol())
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
                dx .+= cplmat * map(ui -> ui(t), u.itp)
                dx .*= gamma
            end
        end
        trigger, handshake, integrator = init_dynamic_system(
                ODEProblem, statefunc, state, t, input, modelargs, solverargs; 
                alg=alg, modelkwargs=modelkwargs, solverkwargs=solverkwargs, numtaps=numtaps
            )
        new{typeof(statefunc), typeof(outputfunc), typeof(state), typeof(t), typeof(integrator), typeof(input), 
            typeof(output), typeof(trigger), typeof(handshake), typeof(callbacks)}(statefunc, outputfunc, state, t, 
            integrator, input, output, trigger, handshake, callbacks, name, uuid4(), a, b, c, gamma)
    end
end


##### Vanderpol System
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
mutable struct VanderpolSystem{SF, OF, ST, T, IN, IB, OB, TR, HS, CB} <: AbstractODESystem
    @generic_dynamic_system_fields
    mu::Float64
    gamma::Float64
    function VanderpolSystem(input=nothing, output=Outport(2), modelargs=(), solverargs=(); 
        mu=5., gamma=1., outputfunc=allstates, state=rand(2), t=0., 
        alg=ODEAlg, cplmat=diagm([1., 1]), modelkwargs=NamedTuple(), solverkwargs=NamedTuple(), numtaps=numtaps, 
        callbacks=nothing, name=Symbol())
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
                dx .+= cplmat * map(ui -> ui(t), u.itp)
            end
        end
        trigger, handshake, integrator = init_dynamic_system(
                ODEProblem, statefunc, state, t, input, modelargs, solverargs; 
                alg=alg, modelkwargs=modelkwargs, solverkwargs=solverkwargs, numtaps=numtaps
            )
        new{typeof(statefunc), typeof(outputfunc), typeof(state), typeof(t), typeof(integrator), typeof(input), 
            typeof(output), typeof(trigger), typeof(handshake), typeof(callbacks)}(statefunc, outputfunc, state, t, 
            integrator, input, output, trigger, handshake, callbacks, name, uuid4(), mu, gamma)
    end
end
  

# # ##### Pretty-printing 
show(io::IO, ds::ODESystem) = print(io, 
    "ODESystem(state:$(ds.state), t:$(ds.t), input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::LinearSystem) = print(io, 
    "Linearystem(A:$(ds.A), B:$(ds.B), C:$(ds.C), D:$(ds.D), state:$(ds.state), t:$(ds.t), ",
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::LorenzSystem) = print(io, 
    "LorenzSystem(sigma:$(ds.sigma), beta:$(ds.beta), rho:$(ds.rho), gamma:$(ds.gamma), state:$(ds.state), t:$(ds.t), ",
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::ChenSystem) = print(io, 
    "ChenSystem(a:$(ds.a), b:$(ds.b), c:$(ds.c), gamma:$(ds.gamma), state:$(ds.state), t:$(ds.t), ",
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, d::PiecewiseLinearDiode) = print(io, 
    "PiecewiseLinearDiode(m0:$(d.m0), m1:$(d.m1), m2:$(d.m2), bp1:$(d.bp1), bp2:$(d.bp2))")
show(io::IO, d::PolynomialDiode) = print(io, "PolynomialDiode(a:$(d.a), b:$(d.b))")
show(io::IO, ds::ChuaSystem) = print(io, 
    "ChuaSystem(diode:$(ds.diode), alpha:$(ds.alpha), beta:$(ds.beta), gamma:$(ds.gamma), state:$(ds.state), ",
    "t:$(ds.t), input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::RosslerSystem) = print(io, 
    "RosslerSystem(a:$(ds.a), b:$(ds.b), c:$(ds.c), gamma:$(ds.gamma), state:$(ds.state), t:$(ds.t), ",
    "input:$(ds.input), output:$(ds.output))")
show(io::IO, ds::VanderpolSystem) = print(io, 
    "VanderpolSystem(mu:$(ds.mu), gamma:$(ds.gamma), state:$(ds.state), t:$(ds.t), ",
    "input:$(ds.input), output:$(ds.output))")
