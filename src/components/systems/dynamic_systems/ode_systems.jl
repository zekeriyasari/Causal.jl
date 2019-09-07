# This file contains ODESystem prototypes

import ....Components.Base: @generic_ode_system_fields, AbstractODESystem

const ODESolver = Solver(Tsit5())


mutable struct ODESystem{SF, OF, IB, OB, S} <:AbstractODESystem
    @generic_ode_system_fields
    function ODESystem(statefunc, outputfunc, state, t, input, solver)
        check_methods(:ODESystem, statefunc, outputfunc)
        trigger = Link()
        output = outputfunc === nothing ? nothing : Bus(infer_number_of_outputs(outputfunc, state, input, t))  
        new{typeof(statefunc), typeof(outputfunc), typeof(input), typeof(output), typeof(solver)}(statefunc, outputfunc,
        state, t, input, output, solver, trigger, Callback[], uuid4())
    end
end
ODESystem(statefunc, outputfunc, state, t=0., input=nothing; solver=ODESolver) = ODESystem(statefunc, outputfunc, state, t, input, solver)

##### LinearSystem
mutable struct LinearSystem{SF, OF, IB, OB, S} <: AbstractODESystem
    @generic_ode_system_fields
    A::Matrix{Float64}
    B::Matrix{Float64}
    C::Matrix{Float64}
    D::Matrix{Float64}
    function LinearSystem(A, B, C, D, state, t, input,  solver)
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
        trigger = Link()
        output = Bus(infer_number_of_outputs(outputfunc, state, input, t))  
        new{typeof(statefunc), typeof(outputfunc), typeof(input), typeof(output), typeof(solver)}(statefunc, outputfunc, state, t, input, output, solver, trigger, 
            Callback[], uuid4(), A, B, C, D)
    end
end
LinearSystem(;A=fill(1., 1, 1), B=fill(0., 1, 1), C=fill(1., 1, 1), D=fill(0., 1, 1), state=rand(1), t=0., input=nothing, solver=ODESolver) = 
    LinearSystem(A, B, C, D, state, t, input, solver)

##### LorenzSystem
mutable struct LorenzSystem{SF, OF, IB, OB, S} <: AbstractODESystem
    @generic_ode_system_fields
    sigma::Float64
    beta::Float64
    rho::Float64
    gamma::Float64
    function LorenzSystem(sigma, beta, rho, gamma, outputfunc, state, t, input, solver)
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
        trigger = Link()
        output = outputfunc === nothing ? nothing : Bus(infer_number_of_outputs(outputfunc, state, input, t))  
        new{typeof(statefunc), typeof(outputfunc), typeof(input), typeof(output), typeof(solver)}(statefunc, outputfunc, state, t, input, output, solver, trigger, 
            Callback[], uuid4(), sigma, beta, rho, gamma)
    end
end
LorenzSystem(;sigma=10, beta=8/3, rho=28, gamma=1, outputfunc=nothing, state=rand(3), t=0., input=nothing, solver=ODESolver) = 
    LorenzSystem(sigma, beta, rho, gamma, outputfunc, state, t, input, solver)

##### Chua System
struct PiecewiseLinearDiode
    m0::Float64
    m1::Float64
    m2::Float64
    bp1::Float64
    bp2::Float64
end
PiecewiseLinearDiode(;m0=-1.143, m1=-0.714, m2=5.,  bp1=1., bp2=5.) = PiecewiseLinearDiode(m0, m1, m2, bp1, bp2)

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
PolynomialDiode(;a=1/16, b=-1/6) = PolynomialDiode(a, b)

(d::PolynomialDiode)(x) = d.a * x^3 + d.b * x

mutable struct ChuaSystem{SF, OF, IB, OB, S, DT} <: AbstractODESystem
    @generic_ode_system_fields
    diode::DT
    alpha::Float64
    beta::Float64
    gamma::Float64
    function ChuaSystem(diode, alpha, beta, gamma, outputfunc, state, t, input, solver)
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
        trigger = Link()
        output = outputfunc === nothing ? nothing : Bus(infer_number_of_outputs(outputfunc, state, input, t))  
        new{typeof(statefunc), typeof(outputfunc), typeof(input), typeof(output), typeof(solver), typeof(diode)}(statefunc, outputfunc, state, t, input, output, solver, 
            trigger, Callback[], uuid4(), diode, alpha, beta, gamma)
    end
end
ChuaSystem(;diode=PiecewiseLinearDiode(), alpha=15.6, beta=28, gamma=1., outputfunc=nothing, state=rand(3)*1e-6, t=0., input=nothing, solver=ODESolver) = 
    ChuaSystem(diode, alpha, beta, gamma, outputfunc, state, t, input, solver)

##### Rossler System
mutable struct RosslerSystem{SF, OF, IB, OB, S} <: AbstractODESystem
    @generic_ode_system_fields
    a::Float64
    b::Float64
    c::Float64
    gamma::Float64
    function RosslerSystem(a, b, c, gamma, outputfunc, state, t, input, solver)
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
        trigger = Link()
        output = outputfunc === nothing ? nothing : Bus(infer_number_of_outputs(outputfunc, state, input, t))  
        new{typeof(statefunc), typeof(outputfunc), typeof(input), typeof(output), typeof(solver)}(statefunc, outputfunc, state, t, input, output, solver, trigger, 
            Callback[], uuid4(), a, b, c, gamma)
    end
end
RosslerSystem(;a=0.2, b=0.2, c=5.7, gamma=1., outputfunc=nothing, state=rand(3),  t=0., input=nothing, solver=ODESolver) = 
    RosslerSystem(a, b, c, gamma, outputfunc, state, t, input, solver)

##### Vanderpol System
mutable struct VanderpolSystem{SF, OF, IB, OB, S} <: AbstractODESystem
    @generic_ode_system_fields
    mu::Float64
    gamma::Float64
    function VanderpolSystem(mu, gamma, outputfunc, state, t, input, solver)
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
        trigger = Link()
        output = outputfunc === nothing ? nothing : Bus(infer_number_of_outputs(outputfunc, state, input, t))  
        new{typeof(statefunc), typeof(outputfunc), typeof(input), typeof(output), typeof(solver)}(statefunc, outputfunc,state, t, input, output, solver, trigger, 
            Callback[], uuid4(), mu, gamma)
    end
end
VanderpolSystem(;mu=5., gamma=1., outputfunc=nothing, state=rand(2),  t=0., input=nothing, solver=ODESolver) = 
    VanderpolSystem(mu, gamma, outputfunc, state, t, input, solver)
    
