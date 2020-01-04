# This file contains ODESystem prototypes

import ....Components.Base: @generic_system_fields, @generic_dynamic_system_fields, AbstractODESystem

const ODESolver = Solver(Tsit5())


mutable struct ODESystem{IB, OB, T, H, SF, OF, ST, IV, S} <: AbstractODESystem
    @generic_dynamic_system_fields
    function ODESystem(input, output, statefunc, outputfunc, state, t; solver=ODESolver)
        trigger = Link()
        handshake = Link{Bool}()
        # inputval = typeof(input) <: Bus ? Vector{eltype(input)}(undef, length(input)) : nothing
        inputval = typeof(input) <: Bus ? rand(eltype(state), length(input)) : nothing
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state),  typeof(inputval), typeof(solver)}(input, output, trigger, handshake, Callback[], uuid4(), 
            statefunc, outputfunc, state, inputval, t, solver)
    end
end

##### LinearSystem
mutable struct LinearSystem{IB, OB, T, H, SF, OF, ST, IV, S} <: AbstractODESystem
    @generic_dynamic_system_fields
    A::Matrix{Float64}
    B::Matrix{Float64}
    C::Matrix{Float64}
    D::Matrix{Float64}
    function LinearSystem(input, output; A=fill(-1, 1, 1), B=fill(0, 1, 1), C=fill(1, 1, 1), D=fill(0, 1, 1), 
        state=rand(size(A,1)), t=0., solver=ODESolver)
        trigger = Link()
        handshake = Link{Bool}()
        inputval = typeof(input) <: Bus ? rand(eltype(state), length(input)) : nothing
        if input === nothing
            statefunc = (dx, x, u, t) -> (dx .= A * x)
            outputfunc = (x, u, t) -> (C * x)
        else
            statefunc = (dx, x, u, t) -> (dx .= A * x + B * map(ui -> ui(t), u))
            if C === nothing || D === nothing
                outputfunc = nothing
            else
                outputfunc = (x, u, t) -> (C * x + D * map(ui -> ui(t), u))
            end
        end
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state), typeof(inputval), typeof(solver)}(input, output, trigger, handshake, Callback[], uuid4(), 
            statefunc, outputfunc, state, inputval, t, solver, A, B, C, D)
    end
end


##### Lorenz System
mutable struct LorenzSystem{IB, OB, T, H, SF, OF, ST, IV, S} <: AbstractODESystem
    @generic_dynamic_system_fields
    sigma::Float64
    beta::Float64
    rho::Float64
    gamma::Float64
    function LorenzSystem(input, output; sigma=10, beta=8/3, rho=28, gamma=1, outputfunc=allstates, state=rand(3), t=0.,
        solver=ODESolver, cplmat=diagm([1., 1., 1.]))
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
                dx .+= cplmat * map(ui -> ui(t), u)   # Couple inputs
            end
        end
        trigger = Link()
        handshake = Link{Bool}()
        inputval = typeof(input) <: Bus ? rand(eltype(state), length(input)) : nothing
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state), typeof(inputval), typeof(solver)}(input, output, trigger, handshake, Callback[], uuid4(), 
            statefunc, outputfunc, state, inputval, t, solver, sigma, beta, rho, gamma)
    end
end

##### Chen System 
mutable struct ChenSystem{IB, OB, T, H, SF, OF, ST, IV, S} <: AbstractODESystem
    @generic_dynamic_system_fields
    a::Float64
    b::Float64
    c::Float64
    gamma::Float64
    function ChenSystem(input, output; a=35, b=3, c=28, gamma=1, outputfunc=allstates, state=rand(3), t=0.,
        solver=ODESolver, cplmat=diagm([1., 1., 1.]))
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
                dx .+= cplmat * map(ui -> ui(t), u)   # Couple inputs
            end
        end
        trigger = Link()
        handshake = Link{Bool}()
        inputval = typeof(input) <: Bus ? rand(eltype(state), length(input)) : nothing
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state), typeof(inputval), typeof(solver)}(input, output, trigger, handshake, Callback[], uuid4(), 
            statefunc, outputfunc, state, inputval, t, solver, a, b, c, gamma)
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

mutable struct ChuaSystem{IB, OB, T, H, SF, OF, ST, IV, S, DT} <: AbstractODESystem
    @generic_dynamic_system_fields
    diode::DT
    alpha::Float64
    beta::Float64
    gamma::Float64
    function ChuaSystem(input, output; diode=PiecewiseLinearDiode(), alpha=15.6, beta=28., gamma=1., 
        outputfunc=allstates, state=rand(3), t=0., solver=ODESolver, cplmat=diagm([1., 1., 1.]))
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
            dx .+= cplmat * map(ui -> ui(t), u)
            end
        end
        trigger = Link()
        handshake = Link{Bool}()
        inputval = typeof(input) <: Bus ? rand(eltype(state), length(input)) : nothing
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state), typeof(inputval), typeof(solver), typeof(diode)}(input, output, trigger, handshake,
            Callback[], uuid4(), statefunc, outputfunc, state, inputval, t, solver, diode, alpha, beta, gamma)
    end
end


##### Rossler System
mutable struct RosslerSystem{IB, OB, T, H, SF, OF, ST, IV, S} <: AbstractODESystem
    @generic_dynamic_system_fields
    a::Float64
    b::Float64
    c::Float64
    gamma::Float64
    function RosslerSystem(input, output; a=0.38, b=0.3, c=4.82, gamma=1., outputfunc=allstates, state=rand(3), t=0., 
        solver=ODESolver, cplmat=diagm([1., 1., 1.]))
        if input === nothing
            statefunc = (dx, x, u, t) -> begin
                dx[1] = -x[2] - x[3]
                dx[2] = x[1] + a * x[2]
                dx[3] = b + x[3] * (x[1] - c)
                dx .*= gamma
            end
        else
            statefunc = (dx, x, u, t) -> begin
                dx[1] = -x[2] - x[3] + u[1]
                dx[2] = x[1] + a * x[2] + u[2]
                dx[3] = b + x[3] * (x[1] - c) + u[3]
                dx .+= cplmat * map(ui -> ui(t), u)
                dx .*= gamma
            end
        end
        trigger = Link() 
        handshake = Link{Bool}()
        inputval = typeof(input) <: Bus ? rand(eltype(state), length(input)) : nothing
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state), typeof(inputval), typeof(solver)}(input, output, trigger, handshake, Callback[], uuid4(), 
            statefunc, outputfunc, state, inputval, t, solver, a, b, c, gamma)
    end
end


##### Vanderpol System
mutable struct VanderpolSystem{IB, OB, T, H, SF, OF, ST, IV, S} <: AbstractODESystem
    @generic_dynamic_system_fields
    mu::Float64
    gamma::Float64
    function VanderpolSystem(input, output; mu=5., gamma=1., outputfunc=allstates, state=rand(2), t=0., 
        solver=ODESolver, cplmat=diagm([1., 1]))
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
                dx .+= cplmat * map(ui -> ui(t), u)
            end
        end
        trigger = Link()
        handshake = Link{Bool}()
        inputval = typeof(input) <: Bus ? rand(eltype(state), length(input)) : nothing
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state), typeof(inputval), typeof(solver)}(input, output, trigger, handshake, Callback[], uuid4(), 
            statefunc, outputfunc, state, inputval, t, solver, mu, gamma)
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
