# This file contains ODESystem prototypes

import ....Components.Base: @generic_ode_system_fields, AbstractODESystem

const ODESolver = Solver(Tsit5())


mutable struct ODESystem{SF, OF, ST, T, IB, OB, S, L} <: AbstractODESystem
    @generic_ode_system_fields
    function ODESystem(statefunc, outputfunc, state, t, input, output)
        solver = ODESolver
        trigger = Link()
        new{typeof(statefunc), typeof(outputfunc), typeof(state), typeof(t), typeof(input), typeof(output), typeof(solver), typeof(trigger)}(statefunc, outputfunc, state, t, input, output, solver, trigger, Callback[], uuid4())
    end
end

##### LinearSystem
mutable struct LinearSystem{SF, OF, ST, T, IB, OB, S, L} <: AbstractODESystem
    @generic_ode_system_fields
    A::Matrix{Float64}
    B::Matrix{Float64}
    C::Matrix{Float64}
    D::Matrix{Float64}
    function LinearSystem(A, B, C, D, state, t, input, output)
        solver = ODESolver
        trigger = Link()
        if input === nothing
            statefunc = (dx, x, u, t) -> (dx .= A * x)
            outputfunc = (x, u, t) -> (C * x)
        else
            statefunc = (dx, x, u, t) -> (dx .= A * x .+ B * u)
            if C === nothing || D === nothing
                outputfunc = nothing
            else
                outputfunc = (x, u, t) -> (C * x .+ D * u)
            end
        end
        new{typeof(statefunc), typeof(outputfunc), typeof(state), typeof(t), typeof(input), typeof(output), typeof(solver), typeof(trigger)}(statefunc, outputfunc, state, t, input, output, solver, trigger, Callback[], uuid4(), A, B, C, D)
    end
end


##### LorenzSystem
mutable struct LorenzSystem{SF, OF, ST, T, IB, OB, S, L} <: AbstractODESystem
    @generic_ode_system_fields
    sigma::Float64
    beta::Float64
    rho::Float64
    gamma::Float64
    function LorenzSystem(sigma, beta, rho, gamma, outputfunc, state, t, input, output)
        if input === nothing
            statefunc = (dx, x, u, t) -> begin
                dx[1] = sigma * (x[2] - x[1])
                dx[2] = x[1] * (rho - x[3]) - x[2]
                dx[3] = x[1] * x[2] - beta * x[3]
                dx .*= gamma
            end
        else
            statefunc = (dx, x, u, t) -> begin
                dx[1] = sigma * (x[2] - x[1]) + u[1]
                dx[2] = x[1] * (rho - x[3]) - x[2] + u[2]
                dx[3] = x[1] * x[2] - beta * x[3] + u[3]
                dx .*= gamma
            end
        end
        solver = ODESolver 
        trigger = Link()
        new{typeof(statefunc), typeof(outputfunc), typeof(state), typeof(t), typeof(input), typeof(output), typeof(solver), typeof(trigger)}(statefunc, outputfunc, state, t, input, output, solver, trigger, Callback[], uuid4(), sigma, beta, rho, gamma)
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

mutable struct ChuaSystem{SF, OF, ST, T, IB, OB, S, L, DT} <: AbstractODESystem
    @generic_ode_system_fields
    diode::DT
    alpha::Float64
    beta::Float64
    gamma::Float64
    function ChuaSystem(diode, alpha, beta, gamma, outputfunc, state, t, input, output)
        if input === nothing
            statefunc = (dx, x, u, t) -> begin
                dx[1] = alpha * (x[2] - x[1] - diode(x[1]))
                dx[2] = x[1] - x[2] + x[3]
                dx[3] = -beta * x[2]
                dx .*= gamma
            end
        else
            statefunc = (dx, x, u, t) -> begin
            dx[1] = alpha * (x[2] - x[1] - diode(x[1])) + u[1]
            dx[2] = x[1] - x[2] + x[3] + u[2]
            dx[3] = -beta * x[2] + u[3]
            dx .*= gamma
            end
        end
        solver = ODESolver
        trigger = Link()
        new{typeof(statefunc), typeof(outputfunc), typeof(state), typeof(t), typeof(input), typeof(output), typeof(solver), typeof(trigger), typeof(diode)}(statefunc, outputfunc, state, t, input, output, solver, trigger, Callback[], uuid4(), diode, alpha, beta, gamma)
    end
end


##### Rossler System
mutable struct RosslerSystem{SF, OF, ST, T, IB, OB, S, L} <: AbstractODESystem
    @generic_ode_system_fields
    a::Float64
    b::Float64
    c::Float64
    gamma::Float64
    function RosslerSystem(a, b, c, gamma, outputfunc, state, t, input, output)
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
                dx .*= gamma
            end
        end
        solver = ODESolver 
        trigger = Link() 
        new{typeof(statefunc), typeof(outputfunc), typeof(state), typeof(t), typeof(input), typeof(output), typeof(solver), typeof(trigger)}(statefunc, outputfunc, state, t, input, output, solver, trigger, Callback[], uuid4(), a, b, c, gamma)
    end
end


##### Vanderpol System
mutable struct VanderpolSystem{SF, OF, ST, T, IB, OB, S, L} <: AbstractODESystem
    @generic_ode_system_fields
    mu::Float64
    gamma::Float64
    function VanderpolSystem(mu, gamma, outputfunc, state, t, input, output)
        if input === nothing
            statefunc = (dx, x, u, t) -> begin
                dx[1] = gamma * x[2]
                dx[2] = gamma * (-mu * (x[1]^2 - 1) * x[2] - x[1])
            end
        else
            statefunc = (dx, x, u, t) -> begin
                dx[1] = gamma * x[2] + u[1]
                dx[2] = gamma * (-mu * (x[1]^2 - 1) * x[2] - x[1]) + u[2]
            end
        end
        solver = ODESolver
        trigger = Link()
        new{typeof(statefunc), typeof(outputfunc), typeof(state), typeof(t), typeof(input), typeof(output), typeof(solver), typeof(trigger)}(statefunc, outputfunc, state, t, input, output, solver, trigger, Callback[], uuid4(), mu, gamma)
    end
end
  

##### Pretty-printing 
show(io::IO, ds::ODESystem) = println(io, "ODESystem(state:$(ds.state), t:$(ds.t), input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
show(io::IO, ds::LinearSystem) = print(io, "Linearystem(A:$(ds.A), B:$(ds.B), C:$(ds.C), D:$(ds.D), state:$(ds.state), t:$(ds.t), ",
    "input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
show(io::IO, ds::LorenzSystem) = print(io, "Lorenzystem(sigma:$(ds.sigma), beta:$(ds.beta), rho:$(ds.rho), gamma:$(ds.gamma), state:$(ds.state), t:$(ds.t), ",
    "input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
show(io::IO, d::PiecewiseLinearDiode) = print(io, "PiecewiseLinearDiode(m0:$(d.m0), m1:$(d.m1), m2:$(d.m2), bp1:$(d.bp1), bp2:$(d.bp2))")
show(io::IO, d::PolynomialDiode) = print(io, "PolynomialDiode(a:$(d.a), b:$(d.b))")
show(io::IO, ds::ChuaSystem) = print(io, "ChuaSystem(diode:$(ds.diode), alpha:$(ds.alpha), beta:$(ds.beta), gamma:$(ds.gamma), state:$(ds.state), t:$(ds.t), ",
    "input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
show(io::IO, ds::RosslerSystem) = print(io, "RosslerSystem(a:$(ds.a), b:$(ds.b), c:$(ds.c), gamma:$(ds.gamma), state:$(ds.state), t:$(ds.t), ",
    "input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
show(io::IO, ds::VanderpolSystem) = print(io, "VanderpolSystem(mu:$(ds.mu), gamma:$(ds.gamma), state:$(ds.state), t:$(ds.t), ",
    "input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
