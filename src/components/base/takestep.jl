# This file includes stepping of abstract types.

import ....Jusdl.Connections: launch, Bus, release
import ....Jusdl.Utilities: write!
using DifferentialEquations
using Sundials
import DifferentialEquations.solve

readtime(comp::AbstractComponent) = take!(comp.trigger)

readstate(comp::AbstractComponent) = typeof(comp) <: AbstractDynamicSystem ? comp.state : nothing

function readinput(comp::AbstractComponent)
    typeof(comp) <: AbstractSource && return nothing
    typeof(comp.input) <: Bus ? take!(comp.input) : nothing
end

function writeoutput(comp::AbstractComponent, out)
    typeof(comp) <: AbstractSink && return nothing  
    typeof(comp.output) <: Bus ? put!(comp.output, out) : nothing
end

computeoutput(comp::AbstractSource, x, u, t) = comp.outputfunc(t)
computeoutput(comp::AbstractStaticSystem, x, u, t) =  
    typeof(comp.outputfunc) <: Nothing ? nothing : comp.outputfunc(u, t)
computeoutput(comp::AbstractDynamicSystem, x, u, t) = 
    typeof(comp.outputfunc) <: Nothing ? nothing : comp.outputfunc(x, u, t)
computeoutput(comp::AbstractSink, x, u, t) = nothing

evolve!(comp::AbstractSource, x, u, t) = nothing
evolve!(comp::AbstractSink, x, u, t) = (write!(comp.timebuf, t); write!(comp.databuf, u); nothing)
evolve!(comp::AbstractStaticSystem, x, u, t) = typeof(comp) <: AbstractMemory ? write!(comp.buffer, u) : nothing
function evolve!(comp::AbstractDynamicSystem, x, u, t)
    # For DDESystems, the problem for a time span of (t, t) cannot be solved. 
    # Thus, there will be no evolution in such a case.
    comp.t == t && return comp.state  
    sol = solve(comp, x, u, t)
    update!(comp, sol)
    comp.state
end

constructprob(comp::AbstractDiscreteSystem, x, u, t) = DiscreteProblem(comp.statefunc, x, (comp.t, t),  u)
constructprob(comp::AbstractODESystem, x, u, t) = ODEProblem(comp.statefunc, x, (comp.t, t), u)
constructprob(comp::AbstractDAESystem, x, u, t) = 
    DAEProblem(comp.statefunc, x, comp.stateder, (comp.t, t), u, differential_vars=comp.diffvars)
constructprob(comp::AbstractRODESystem, x, u, t) = 
    RODEProblem(comp.statefunc, x, (comp.t, t), u, noise=comp.noise.process, rand_prototype=comp.noise.prototype, 
    seed=comp.noise.seed)
constructprob(comp::AbstractSDESystem, x, u, t) = SDEProblem(comp.statefunc..., x, (comp.t, t), u, 
    noise=comp.noise.process, noise_rate_prototype=comp.noise.prototype, seed=comp.noise.seed)
constructprob(comp::AbstractDDESystem, x, u, t) = DDEProblem(comp.statefunc, x, comp.history.func, (comp.t, t), u, 
    constant_lags=comp.history.conslags, dependent_lags=comp.history.depslags, neutral=comp.history.neutral)
solve(comp::AbstractDynamicSystem, x, u,t) = solve(constructprob(comp, x, u, t), comp.solver.alg; comp.solver.params...)

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

# NOTE: The order of reading input, trigger, state, output is different for different kind of components.
# So the different `takestep` methods have been implemented below. Note the order of reading, time, state, input, 
# output for different types of components.

# function takestep(comp::AbstractComponent)
#     # t = readtime(comp)
#     # t === missing && return t
#     # typeof(comp) <: AbstractMemory ? backwardstep(comp, t) : forwardstep(comp, t)
# end

# function forwardstep(comp, t)
#     u = readinput(comp)
#     x = readstate(comp)
#     xn = evolve!(comp, x, u, t)
#     y = computeoutput(comp, xn, u, t)
#     writeoutput(comp, y)
#     comp.callbacks(comp)
#     return t
# end

# function backwardstep(comp, t)
#     x = readstate(comp)
#     y = computeoutput(comp, x, nothing, t)
#     writeoutput(comp, y)
#     u = readinput(comp)
#     xn = evolve!(comp, x, u, t)
#     comp.callbacks(comp)
#     return t
# end

function takestep(comp::AbstractMemory)
    t = readtime(comp)
    t === missing && return t
    x = readstate(comp)
    y = computeoutput(comp, x, nothing, t)
    writeoutput(comp, y)
    u = readinput(comp)
    xn = evolve!(comp, x, u, t)
    comp.callbacks(comp)
    return t
end

function takestep(comp::AbstractSource)
    t = readtime(comp)
    t === missing && return t
    u = readinput(comp)
    x = readstate(comp)
    xn = evolve!(comp, x, u, t)
    y = computeoutput(comp, xn, u, t)
    writeoutput(comp, y)
    comp.callbacks(comp)
    return t
end

function takestep(comp::AbstractSystem)
    u = readinput(comp)
    t = readtime(comp)
    t === missing && return t 
    x = readstate(comp)
    xn = evolve!(comp, x, u, t)
    y = computeoutput(comp, xn, u, t)
    writeoutput(comp, y)
    comp.callbacks(comp)
    return t
end

function takestep(comp::AbstractSink)
    u = readinput(comp)
    t = readtime(comp)
    t === missing && return t 
    x = readstate(comp)
    xn = evolve!(comp, x, u, t)
    y = computeoutput(comp, xn, u, t)
    writeoutput(comp, y)
    comp.callbacks(comp)
    return t
end

function takestep(comp::AbstractSubSystem)
    # t = readtime(comp)
    # t === missing && return t
    foreach(takestep, comp.components)
end


function launch(comp::AbstractComponent)
    outputtask = if !(typeof(comp) <: AbstractSink)  
        @async while true 
            all(take!(comp.output) .=== missing) && break
        end
    end
    triggertask = @async begin 
        while true
            takestep(comp) === missing && break
        end
        typeof(comp) <: AbstractSink && close(comp)
    end
    return triggertask, outputtask
end

launch(comp::AbstractSubSystem) = launch.(comp.components)

drive(comp::AbstractComponent, t) = put!(comp.trigger, t)

function drive(comp::AbstractSubSystem, t)
    components = comp.components
    mask = falses(length(components))
    while !all(mask)
        idx = map(comp -> iswritable(comp.trigger), components)
        mask[idx] .= true
        foreach(comp -> drive(comp, t), components[idx])
    end
end

function release(comp::AbstractComponent)
    typeof(comp) <: AbstractSource  || release(comp.input)
    typeof(comp) <: AbstractSink    || release(comp.output)
    return 
end

function release(comp::AbstractSubSystem)
    foreach(release, comp.components)
    typeof(comp.input) <: Bus && release(comp.input)
    typeof(comp.output) <: Bus && release(comp.output)
end

# terminate(comp::AbstractComponent) = drive(comp, missing)
function terminate(comp::AbstractSource)
    put!(comp.trigger, missing)
    put!(comp.output, fill(missing, length(comp.output)))
    return 
end

function terminate(comp::AbstractSystem)
    typeof(comp.input) <: Bus && put!(comp.input, fill(missing, length(comp.input)))
    put!(comp.trigger, missing)
    typeof(comp.output) <: Bus && put!(comp.output, fill(missing, length(comp.output)))
    return
end

function terminate(comp::AbstractSink)
    put!(comp.input, fill(missing, length(comp.input)))
    put!(comp.trigger, missing)
    return 
end

function terminate(comp::AbstractMemory)
    put!(comp.output, fill(missing, length(comp.output)))
    put!(comp.trigger, missing)
    # put!(comp.input, fill(missing, length(comp.input)))
    return 
end

terminate(comp::AbstractSubSystem) = foreach(terminate, comp.components)

# terminate(comp::AbstractSubSystem) = foreach(subcomp -> drive(subcomp, missing), comp.components)
# function terminate(comp::AbstractSubSystem)
#     components = comp.components
#     mask = falses(length(components))
#     while !all(mask)
#         @show mask
#         idx = map(comp -> iswritable(comp.trigger), components)
#         mask[idx] .= true
#         for comp in components[idx]
#             put!(comp.trigger, missing)  
#         end
#     end
# end