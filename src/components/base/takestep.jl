# This file includes stepping of abstract types.

import ....JuSDL.Connections: launch, AbstractBus
import ....JuSDL.Utilities: write!
using DifferentialEquations
using Sundials
import DifferentialEquations.solve

readtime(comp::AbstractComponent) = take!(comp.trigger)

readstate(comp::AbstractComponent) = typeof(comp) <: AbstractDynamicSystem ? comp.state : nothing

function readinput(comp::AbstractComponent, t)
    typeof(comp) <: AbstractSource && return nothing
    typeof(comp.input) <: AbstractBus ? take!(comp.input, t) : nothing
end

function writeoutput(comp::AbstractComponent, out)
    typeof(comp) <: AbstractSink && return nothing  
    typeof(comp.output) <: AbstractBus ? put!(comp.output, out) : nothing
end

computeoutput(comp::AbstractSource, x, u, t) = comp.outputfunc(t)
computeoutput(comp::AbstractStaticSystem, x, u, t) =  typeof(comp.outputfunc) <: Nothing ? nothing : comp.outputfunc(u, t)
computeoutput(comp::AbstractDynamicSystem, x, u, t) = typeof(comp.outputfunc) <: Nothing ? nothing : comp.outputfunc(x, u, t)
computeoutput(comp::AbstractSink, x, u, t) = nothing

evolve!(comp::AbstractSource, x, u, t) = nothing
evolve!(comp::AbstractSink, x, u, t) = (write!(comp.timebuf, t); write!(comp.databuf, u); nothing)
evolve!(comp::AbstractStaticSystem, x, u, t) = typeof(comp) <: AbstractMemory ? write!(comp.buffer, u) : nothing
function evolve!(comp::AbstractDynamicSystem, x, u, t)
    # For DDESystems, the problem for a time span of (t, t) cannot be solved. Thus, there will be no evolution in such a case.
    comp.t == t && return comp.state  
    sol = solve(comp, x, u, t)
    update!(comp, sol)
    comp.state
end

constructprob(comp::AbstractDiscreteSystem, x, u, t) = DiscreteProblem(comp.statefunc, x, (comp.t, t),  u)
constructprob(comp::AbstractODESystem, x, u, t) = ODEProblem(comp.statefunc, x, (comp.t, t), u)
constructprob(comp::AbstractDAESystem, x, u, t) = DAEProblem(comp.statefunc, x, comp.stateder, (comp.t, t), u, differential_vars=comp.diffvars)
constructprob(comp::AbstractRODESystem, x, u, t) = RODEProblem(comp.statefunc, x, (comp.t, t), u, noise=comp.noise.process, 
    rand_prototype=comp.noise.prototype, seed=comp.noise.seed)
constructprob(comp::AbstractSDESystem, x, u, t) = SDEProblem(comp.statefunc..., x, (comp.t, t), u, noise=comp.noise.process, 
    noise_rate_prototype=comp.noise.prototype, seed=comp.noise.seed)
constructprob(comp::AbstractDDESystem, x, u, t) = DDEProblem(comp.statefunc, x, comp.history.func, (comp.t, t), u, 
    constant_lags=comp.history.conslags, dependent_lags=comp.history.depslags, neutral=comp.history.neutral)

solve(comp::AbstractDynamicSystem, x, u,t) = solve(constructprob(comp, x, u, t), comp.solver.alg; comp.solver.params...)

# solve(comp::AbstractDiscreteSystem, x, u, t) = solve(DiscreteProblem(comp.statefunc, x, (comp.t, t),  u), comp.solver.alg; comp.solver.params...)
# solve(comp::AbstractODESystem, x, u, t) = solve(ODEProblem(comp.statefunc, x, (comp.t, t), u), comp.solver.alg; comp.solver.params...)
# solve(comp::AbstractDAESystem, x, u, t) = solve(DAEProblem(comp.statefunc, x, comp.stateder, (comp.t, t), u, 
#     differential_vars=comp.diffvars), comp.solver.alg; comp.solver.params...)
# solve(comp::AbstractRODESystem, x, u, t) = solve(RODEProblem(comp.statefunc, x, (comp.t, t), u, noise=comp.noise.process, 
#     rand_prototype=comp.noise.prototype, seed=comp.noise.seed), comp.solver.alg; comp.solver.params...)
# solve(comp::AbstractSDESystem, x, u, t) = solve(SDEProblem(comp.statefunc..., x, (comp.t, t), u, noise=comp.noise.process, 
#     noise_rate_prototype=comp.noise.prototype, seed=comp.noise.seed), comp.solver.alg; comp.solver.params...)
# solve(comp::AbstractDDESystem, x, u, t) = solve(DDEProblem(comp.statefunc, x, comp.history.func, (comp.t, t), u, 
#     constant_lags=comp.history.conslags, dependent_lags=comp.history.depslags, neutral=comp.history.neutral), comp.solver.alg; comp.solver.params...)

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
    comp.noise.process = NoiseProcess(noise.t[end], noise.u[end], Z, noise.dist, noise.bridge, rng=noise.rng, reseed=false)
    comp
end

function takestep(comp::AbstractComponent)
    t = readtime(comp)
    t === NaN && return t
    typeof(comp) <: AbstractMemory ? backwardstep(comp, t) : forwardstep(comp, t)
end

function forwardstep(comp, t)
    u = readinput(comp, t)
    x = readstate(comp)
    xn = evolve!(comp, x, u, t)
    y = computeoutput(comp, xn, u, t)
    writeoutput(comp, y)
    comp.callbacks(comp)
    return t
end

function backwardstep(comp, t)
    x = readstate(comp)
    y = computeoutput(comp, x, nothing, t)
    writeoutput(comp, y)
    u = readinput(comp, t)
    xn = evolve!(comp, x, u, t)
    comp.callbacks(comp)
    return t
end

function launch(comp::AbstractComponent)
    @async begin 
        while true
            takestep(comp) === NaN && break
        end
        typeof(comp) <: AbstractSink && close(comp)
    end
end

drive(comp::AbstractComponent, t) = put!(comp.trigger, t)
terminate(comp::AbstractComponent) = drive(comp, NaN)
