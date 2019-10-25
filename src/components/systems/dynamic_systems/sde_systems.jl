# This file contains SDESystem prototypes

import ....Components.Base: @generic_system_fields, @generic_dynamic_system_fields, AbstractSDESystem

const SDESolver = Solver(LambaEM{true}())
const SDENoise = Noise(WienerProcess(0.,0.))


mutable struct SDESystem{IB, OB, T, H, SF, OF, ST, IV, S, N} <: AbstractSDESystem
    @generic_dynamic_system_fields
    noise::N
    function SDESystem(input, output, statefunc, outputfunc, state, t, noise; solver=SDESolver)
        trigger = Link()
        handshake = Link{Bool}()
        inputval = typeof(input) <: Bus ? rand(eltype(state), length(input)) : nothing
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state), typeof(inputval), typeof(solver), typeof(noise)}(input, output, trigger, Callback[], uuid4(),
            statefunc, outputfunc, state, inputval, t, solver, noise)
    end
end

show(io::IO, ds::SDESystem) = print(io, 
    "SDESystem(state:$(ds.state), t:$(ds.t), input:$(checkandshow(ds.input)), ",
    "output:$(checkandshow(ds.output)), noise:$(checkandshow(ds.noise)))")

##### Noisy Linear System

# mutable struct NoisyLinearSystem{SF, OF, T<:AbstractFloat, IB, OB, SW, B, N, NP} <: AbstractSDESystem
#     @generic_dynamic_system_fields
#     noise::N
#     noise_prototype::NP 
#     seed::UInt
#     A::Matrix{Float64}
#     B::Matrix{Float64}
#     C::Matrix{Float64}
#     D::Matrix{Float64}
#     function NoisyLinearSystem(A, B, C, D, diffusion, outputfunc, state, t, noise, noise_prototype, seed, 
#         input, solver, solver_kwargs, callbacks, name)
#         if input == nothing
#             driftfunc = (dx, x, u, t) -> (dx .= A * x)
#             outputfunc = (x, u, t) -> (C * x)
#         else
#             driftfunc = (dx, x, u, t) -> (dx .= A * x .+ B * u)
#             if C == nothing || D == nothing
#                 outputfunc = nothing
#             else
#                 outputfunc = (x, u, t) -> (C * x .+ D * u)
#             end
#         end
#         statefunc = (driftfunc, diffusion)
#         trigger = Link()
#         output = Bus(infer_number_of_outputs(outputfunc, state, input, t))  
#         buffer = length(state) == 1 ? Buffer(64) : Buffer(64, length(state))
#         new{typeof(statefunc), typeof(outputfunc), typeof(t), typeof(input), typeof(output), typeof(solver), 
#         typeof(buffer), typeof(noise), typeof(noise_prototype)}(statefunc, outputfunc, state, t, input, output, solver, solver_kwargs, buffer, trigger, callbacks, name, noise, noise_prototype, seed, A, B, C, D)
#     end
# end
# NoisyLinearSystem(;A=fill(1., 1, 1), B=fill(0., 1, 1), C=fill(1., 1, 1), D=fill(0., 1, 1), diffusion=Diffusion(ones(1)),    outputfunc=nothing, state=rand(1), t=0., noise=WienerProcess(0., zeros(1)), noise_prototype=nothing, seed=UInt(0), 
#     input=nothing, solver=LambaEM{true}(), solver_kwargs=Dict{Symbol, Any}(), callbacks=Callback[], 
#     name=string(uuid4())) = 
#     NoisyLinearSystem(A, B, C, D, diffusion, outputfunc, state, t, noise, noise_prototype, seed, input, solver, 
#     solver_kwargs, callbacks, name)

# ##### Noisy Lorenz System

# mutable struct NoisyLorenzSystem{SF, OF, T<:AbstractFloat, IB, OB, SW, B, N, NP} <: AbstractSDESystem
#     @generic_dynamic_system_fields
#     noise::N
#     noise_prototype::NP 
#     seed::UInt
#     sigma::Float64
#     beta::Float64
#     rho::Float64
#     gamma::Float64
#     function NoisyLorenzSystem(sigma, beta, rho, gamma, diffusion, outputfunc, state, t, noise, noise_prototype, seed, 
#         input, solver, solver_kwargs, callbacks, name)
#         if input == nothing
#             driftfunc = (dx, x, u, t) -> begin
#                 dx[1] = sigma * (x[2] - x[1])
#                 dx[2] = x[1] * (rho - x[3]) - x[2]
#                 dx[3] = x[1] * x[2] - beta * x[3]
#                 dx .*= gamma
#             end
#         else
#             driftfunc = (dx, x, u, t) -> begin
#                 dx[1] = sigma * (x[2] - x[1]) + u[1](t)
#                 dx[2] = x[1] * (rho - x[3]) - x[2] + u[2](t)
#                 dx[3] = x[1] * x[2] - beta * x[3] + u[3](t)
#                 dx .*= gamma
#             end
#         end
#         statefunc = (driftfunc, diffusion)
#         trigger = Link()
#         output = outputfunc == nothing ? nothing : Bus(infer_number_of_outputs(outputfunc, state, input, t))  
#         buffer = length(state) == 1 ? Buffer(64) : Buffer(64, length(state))
#         new{typeof(statefunc), typeof(outputfunc), typeof(t), typeof(input), typeof(output), typeof(solver), 
#         typeof(buffer), typeof(noise), typeof(noise_prototype)}(statefunc, outputfunc, state, t, input, output, solver, solver_kwargs, buffer, trigger, callbacks, name, noise, noise_prototype, seed, sigma, beta, rho, gamma)
#     end
# end
# NoisyLorenzSystem(;sigma=10, beta=8/3, rho=28, gamma=1, diffusion=Diffusion(ones(3)), outputfunc=nothing, 
#     state=rand(3), t=0., noise=WienerProcess(0., zeros(3)), noise_prototype=nothing, seed=UInt(0), input=nothing, 
#     solver=LambaEM{true}(), solver_kwargs=Dict{Symbol, Any}(), callbacks=Callback[], name=string(uuid4())) = 
#     NoisyLorenzSystem(sigma, beta, rho, gamma, diffusion, outputfunc, state, t, noise, noise_prototype, seed, input, 
#     solver, solver_kwargs, callbacks, name)

# ##### Noisy Chua System

# mutable struct NoisyChuaSystem{SF, OF, T<:AbstractFloat, IB, OB, SW, B, N, NP, D} <: AbstractSDESystem
#     @generic_dynamic_system_fields
#     noise::N 
#     noise_prototype::NP 
#     seed::UInt
#     diode::D
#     alpha::Float64
#     beta::Float64
#     gamma::Float64
#     function NoisyChuaSystem(diode, alpha, beta, gamma, diffusion, outputfunc, state, t, input, noise, noise_prototype,    seed, solver, solver_kwargs, callbacks, name)
#         if input == nothing
#             driftfunc = (dx, x, u, t) -> begin
#                 dx[1] = alpha * (x[2] - x[1] - diode(x[1]))
#                 dx[2] = x[1] - x[2] + x[3]
#                 dx[3] = -beta * x[2]
#                 dx .*= gamma
#             end
#         else
#             driftfunc = (dx, x, u, t) -> begin
#             dx[1] = alpha * (x[2] - x[1] - diode(x[1])) + u[1](t)
#             dx[2] = x[1] - x[2] + x[3] + u[2](t)
#             dx[3] = -beta * x[2] + u[3](t)
#             dx .*= gamma
#             end
#         end
#         statefunc = (driftfunc, diffusion)
#         trigger = Link()
#         output = outputfunc == nothing ? nothing : Bus(infer_number_of_outputs(outputfunc, state, input, t))  
#         buffer = length(state) == 1 ? Buffer(64) : Buffer(64, length(state))
#         new{typeof(statefunc), typeof(outputfunc), typeof(t), typeof(input), typeof(output), typeof(solver), 
#         typeof(buffer), typeof(noise), typeof(noise_prototype), typeof(diode)}(statefunc, outputfunc, state, t, input, 
#         output, solver, solver_kwargs, buffer, trigger, callbacks, name, noise, noise_prototype, seed, diode, alpha, 
#         beta, gamma)
#     end
# end
# NoisyChuaSystem(;diode=PiecewiseLinearDiode(), alpha=15.6, beta=28, gamma=1., diffusion=Diffusion(ones(3)), 
#     outputfunc=nothing, state=rand(3)*1e-6, t=0., noise=WienerProcess(0., zeros(3)), noise_prototype=nothing, 
#     seed=UInt(0), input=nothing, solver=LambaEM{true}(), solver_kwargs=Dict{Symbol, Any}(), callbacks=Callback[], 
#     name=string(uuid4())) = 
#     NoisyChuaSystem(diode, alpha, beta, gamma, diffusion, outputfunc, state, t, input, noise, noise_prototype, seed, 
#     solver, solver_kwargs, callbacks, name)

# ##### Noisy Rossler System

# mutable struct NoisyRosslerSystem{SF, OF, T<:AbstractFloat, IB, OB, SW, B, N, NP} <: AbstractSDESystem
#     @generic_dynamic_system_fields
#     noise::N
#     noise_prototype::NP 
#     seed::UInt
#     a::Float64
#     b::Float64
#     c::Float64
#     gamma::Float64
#     function NoisyRosslerSystem(a, b, c, gamma, diffusion, outputfunc, state, t, noise, noise_prototype, seed, input, 
#         solver, solver_kwargs, callbacks, name)
#         if input == nothing
#             driftfunc = (dx, x, u, t) -> begin
#                 dx[1] = -x[2] - x[3]
#                 dx[2] = x[1] + a * x[2]
#                 dx[3] = b + x[3] * (x[1] - c)
#                 dx .*= gamma
#             end
#         else
#             driftfunc = (dx, x, u, t) -> begin
#                 dx[1] = -x[2] - x[3] + u[1](t)
#                 dx[2] = x[1] + a * x[2] + u[2](t)
#                 dx[3] = b + x[3] * (x[1] - c) + u[3](t)
#                 dx .*= gamma
#             end
#         end
#         statefunc = (driftfunc, diffusion)
#         trigger = Link()
#         output = outputfunc == nothing ? nothing : Bus(infer_number_of_outputs(outputfunc, state, input, t))  
#         buffer = length(state) == 1 ? Buffer(64) : Buffer(64, length(state))
#         new{typeof(statefunc), typeof(outputfunc), typeof(t), typeof(input), typeof(output), typeof(solver), 
#         typeof(buffer), typeof(noise), typeof(noise_prototype)}(statefunc, outputfunc, state, t, input, 
#         output, solver, solver_kwargs, buffer, trigger, callbacks, name, noise, noise_prototype, seed, a, b, c, gamma)
#     end
# end
# NoisyRosslerSystem(;a=0.2, b=0.2, c=5.7, gamma=1., diffusion=Diffusion(ones(3)), outputfunc=nothing, 
#     state=rand(3)*1e-6, t=0., noise=WienerProcess(0., zeros(3)), noise_prototype=nothing, seed=UInt(0), input=nothing, 
#     solver=LambaEM{true}(), solver_kwargs=Dict{Symbol, Any}(), callbacks=Callback[], name=string(uuid4())) = 
#     NoisyRosslerSystem(a, b, c, gamma, diffusion, outputfunc, state, t, noise, noise_prototype, seed, input, 
#     solver, solver_kwargs, callbacks, name)

# ##### Noisy Vanderpol System

# mutable struct NoisyVanderpolSystem{SF, OF, T<:AbstractFloat, IB, OB, SW, B, N, NP} <: AbstractSDESystem
#     @generic_dynamic_system_fields
#     noise::N 
#     noise_prototype::NP 
#     seed::UInt
#     mu::Float64
#     gamma::Float64
#     function NoisyVanderpolSystem(mu, gamma, diffusion, outputfunc, state, t, noise, noise_prototype, seed, input, 
#         solver, solver_kwargs, callbacks, name)
#         if input == nothing
#             driftfunc = (dx, x, u, t) -> begin
#                 dx[1] = gamma * x[2]
#                 dx[2] = gamma * (-mu * (x[1]^2 - 1) * x[2] - x[1])
#             end
#         else
#             driftfunc = (dx, x, u, t) -> begin
#                 dx[1] = gamma * x[2] + u[1](t)
#                 dx[2] = gamma * (-mu * (x[1]^2 - 1) * x[2] - x[1]) + u[2](t)
#             end
#         end
#         statefunc = (driftfunc, diffusion)
#         trigger = Link()
#         output = outputfunc == nothing ? nothing : Bus(infer_number_of_outputs(outputfunc, state, input, t))  
#         buffer = length(state) == 1 ? Buffer(64) : Buffer(64, length(state))
#         new{typeof(statefunc), typeof(outputfunc), typeof(t), typeof(input), typeof(output), typeof(solver), 
#         typeof(buffer), typeof(noise), typeof(noise_prototype)}(statefunc, outputfunc, state, t, input, 
#         output, solver, solver_kwargs, buffer, trigger, callbacks, name, noise, noise_prototype, seed, mu, gamma)
#     end
# end
# NoisyVanderpolSystem(;mu=5., gamma=1., diffusion=Diffusion(ones(2)), outputfunc=nothing, 
#     state=rand(2), t=0., noise=WienerProcess(0., zeros(2)), noise_prototype=nothing, seed=UInt(0), input=nothing, 
#     solver=LambaEM{true}(), solver_kwargs=Dict{Symbol, Any}(), callbacks=Callback[], name=string(uuid4())) = 
#     NoisyVanderpolSystem(mu, gamma, diffusion, outputfunc, state, t, noise, noise_prototype, seed, input, 
#     solver, solver_kwargs, callbacks, name)
