# This file includes stepping of an abstract types.

import ....JuSDL.Connections: launch, AbstractBus
import ....JuSDL.Utilities: write!
using DifferentialEquations
using Sundials
import DifferentialEquations.solve

read_time(comp::AbstractComponent) = take!(comp.trigger)

read_state(comp::AbstractComponent) = typeof(comp) <: AbstractDynamicSystem ? comp.state : nothing

function read_input(comp::AbstractComponent, t)
    typeof(comp) <: AbstractSource && return nothing
    typeof(comp.input) <: AbstractBus ? take!(comp.input, t) : nothing
end

function write_output(comp::AbstractComponent, out)
    typeof(comp) <: AbstractSink && return nothing  
    typeof(comp.output) <: AbstractBus ? put!(comp.output, out) : nothing
end

compute_output(comp::AbstractSource, x, u, t) = comp.outputfunc(t)
compute_output(comp::AbstractStaticSystem, x, u, t) =  typeof(comp.outputfunc)<:Nothing ? 
    nothing : comp.outputfunc(u, t)
compute_output(comp::AbstractDynamicSystem, x, u, t) = typeof(comp.outputfunc)<:Nothing ? 
    nothing : comp.outputfunc(x, u, t)
compute_output(comp::AbstractSink, x, u, t) = nothing

evolve!(comp::AbstractSource, x, u, t) = nothing
evolve!(comp::AbstractSink, x, u, t) = (write!(comp.timebuf, t); write!(comp.databuf, u); nothing)
evolve!(comp::AbstractStaticSystem, x, u, t) = typeof(comp) <: AbstractMemory ? write!(comp.buffer, u) : nothing
function evolve!(comp::AbstractDynamicSystem, x, u, t)
    sol = solve(comp, x, u, t)
    update!(comp, sol)
    comp.state
end

solve(comp::AbstractDiscreteSystem, x, u, t) = solve(DiscreteProblem(comp.statefunc, x, (comp.t, t),  u), 
    comp.solver.alg; comp.solver.params...)
solve(comp::AbstractODESystem, x, u, t) = solve(ODEProblem(comp.statefunc, x, (comp.t, t), u), comp.solver.alg; 
    comp.solver.params...)
solve(comp::AbstractDAESystem, x, u, t) = solve(DAEProblem(comp.statefunc, x, comp.stateder, (comp.t, t), u, 
    differential_vars=comp.diffvars), comp.solver.alg; comp.solver.params...)
solve(comp::AbstractRODESystem, x, u, t) = solve(RODEProblem(comp.statefunc, x, (comp.t, t), u, 
    noise=comp.noise.process, rand_prototype=comp.noise.prototype, seed=comp.noise.seed), comp.solver.alg; 
    comp.solver.params...)
solve(comp::AbstractSDESystem, x, u, t) = solve(SDEProblem(comp.statefunc..., x, (comp.t, t), u, 
    noise=comp.noise.process, noise_rate_prototype=comp.noise.prototype, seed=comp.noise.seed), comp.solver.alg; comp.solver.params...)
solve(comp::AbstractDDESystem, x, u, t) = solve(DDEProblem(comp.statefunc[1], x, comp.statefunc[2], (comp.t, t), u, 
    constant_lags=comp.history.conslags, dependent_lags=comp.history.depslags, neutral=comp.history.neutral), 
    comp.solver.alg; comp.solver.params...)

function update!(comp::AbstractDynamicSystem, sol)
    update_time!(comp, sol.t[end])
    update_state!(comp, sol.u[end])
    typeof(comp) <: Union{<:AbstractSDESystem, <:AbstractRODESystem} && update_noise!(comp, sol.W)
    typeof(comp) <: AbstractDAESystem && update_stateder!(comp, sol.du[end])
    comp
end
update_time!(comp::AbstractDynamicSystem, t) = (comp.t = t; comp)
update_state!(comp::AbstractDynamicSystem, state) = (comp.state = state; comp)
update_stateder!(comp::AbstractDAESystem, stateder) = (comp.stateder = stateder; comp)
function update_noise!(comp::Union{<:AbstractSDESystem, <:AbstractRODESystem}, noise)
    Z = typeof(noise.Z) <: Nothing ? noise.Z : noise.Z[end]
    comp.noise.process = NoiseProcess(noise.t[end], noise.u[end], Z, noise.dist, noise.bridge, rng=noise.rng, 
    reseed=false)
    comp
end

function take_step(comp::AbstractComponent)
    t = read_time(comp)
    t === NaN && return t
    typeof(comp) <: AbstractMemory ? backward_step(comp, t) : forward_step(comp, t)
end

function forward_step(comp, t)
    u = read_input(comp, t)
    x = read_state(comp)
    xn = evolve!(comp, x, u, t)
    y = compute_output(comp, xn, u, t)
    write_output(comp, y)
    comp.callbacks(comp)
    return t
end

function backward_step(comp, t)
    x = read_state(comp)
    y = compute_output(comp, x, nothing, t)
    write_output(comp, y)
    u = read_input(comp, t)
    xn = evolve!(comp, x, u, t)
    comp.callbacks(comp)
    return t
end

function launch(comp::AbstractComponent)
    @async begin 
        while true
            take_step(comp) === NaN && break
        end
        typeof(comp) <: AbstractSink && close(comp)
    end
end

drive(comp::AbstractComponent, t) = put!(comp.trigger, t)
terminate(comp::AbstractComponent) = drive(comp, NaN)
