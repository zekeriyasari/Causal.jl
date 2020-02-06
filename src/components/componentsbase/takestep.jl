# This file includes stepping of abstract types.

import ....Jusdl.Connections: launch, Bus, release, isreadable
import ....Jusdl.Utilities: write!
using DifferentialEquations
using Sundials
import DifferentialEquations.solve

##### Input-Output reading and writing.
"""
    readtime(comp::AbstractComponent)

Returns current time of `comp` from its `trigger` link.

!!! note 
    To read time of `comp`, `comp` must be launched. See also: [`launch(comp::AbstractComponent)`](@ref).
"""
readtime(comp::AbstractComponent) = take!(comp.trigger)

"""
    readstate(comp::AbstractComponent)

Returns the state of `comp` if `comp` is `AbstractDynamicSystem`. Otherwise, returns `nothing`. 
"""
readstate(comp::AbstractComponent) = typeof(comp) <: AbstractDynamicSystem ? comp.state : nothing

"""
    readinput(comp::AbstractComponent)

Returne the input value of `comp` if the `input` of `comp` is `Bus`. Otherwise, returns `nothing`.

!!! note 
    To read input value of `comp`, `comp` must be launched. See also: [`launch(comp::AbstractComponent)`](@ref)
"""
function readinput(comp::AbstractComponent)
    typeof(comp) <: AbstractSource && return nothing
    typeof(comp.input) <: Bus ? take!(comp.input) : nothing
end

"""
    writeoutput(comp::AbstractComponent, out)

Writes `out` to the output of `comp` if the `output` of `comp` is `Bus`. Otherwise, does `nothing`.
"""
function writeoutput(comp::AbstractComponent, out)
    typeof(comp) <: AbstractSink && return nothing  
    typeof(comp.output) <: Bus ? put!(comp.output, out) : nothing
end

"""
    computeoutput(comp, x, u, t)

Computes the output of `comp` according to its `outputfunc` if `outputfunc` is not `nothing`. Otherwise, `nothing` is done. `x` is the state, `u` is the value of input, `t` is the time. 
"""
computeoutput
computeoutput(comp::AbstractSource, x, u, t) = comp.outputfunc(t)
computeoutput(comp::AbstractStaticSystem, x, u, t) =  
    typeof(comp.outputfunc) <: Nothing ? nothing : comp.outputfunc(u, t)
function computeoutput(comp::AbstractDynamicSystem, x, u, t)
    typeof(comp.outputfunc) <: Nothing && return nothing
    typeof(u) <: Nothing ? comp.outputfunc(x, u, t) : comp.outputfunc(x, map(ui -> t -> ui, u), t) 
end
    # typeof(comp.outputfunc) <: Nothing ? nothing : comp.outputfunc(x, constructinput(comp, u, t), t)
computeoutput(comp::AbstractSink, x, u, t) = nothing

"""
    evolve!(comp::AbstractSource, x, u, t)

Does nothing. `x` is the state, `u` is the value of `input` and `t` is time.

    evolve!(comp::AbstractSink, x, u, t) 

Writes `t` to time buffer `timebuf` and `u` to `databuf` of `comp`. `x` is the state, `u` is the value of `input` and `t` is time.

    evolve!(comp::AbstractStaticSystem, x, u, t)

Writes `u` to `buffer` of `comp` if `comp` is an `AbstractMemory`. Otherwise, `nothing` is done. `x` is the state, `u` is the value of `input` and `t` is time. 
    
    evolve!(comp::AbstractDynamicSystem, x, u, t)

Solves the differential equaition of the system of `comp` for the time interval `(comp.t, t)` for the inital condition `x`. `u` is the input function defined for `(comp.t, t)`. The `comp` is updated with the computed state and time `t`. See also: [`update!(comp::AbstractDynamicSystem, sol, u)`](@ref)
"""
evolve!
evolve!(comp::AbstractSource, x, u, t) = nothing
evolve!(comp::AbstractSink, x, u, t) = (write!(comp.timebuf, t); write!(comp.databuf, u); nothing)
evolve!(comp::AbstractStaticSystem, x, u, t) = typeof(comp) <: AbstractMemory ? write!(comp.buffer, u) : nothing
function evolve!(comp::AbstractDynamicSystem, x, u, t)
    # For DDESystems, the problem for a time span of (t, t) cannot be solved. 
    # Thus, there will be no evolution in such a case.
    comp.t == t && return comp.state  
    sol = solve(comp, x, u, t)
    update!(comp, sol, u)
    comp.state
end

interpolate(t0::Real, t1::Real, u0::Real, u1::Real) = 
    t -> t0 <= t <= t1 ? u0 + (t - t0) / (t1 - t0) * (u1 - u0) : error("Extrapolation is not allowed.")
interpolate(t0::Real, t1::Real, u0::AbstractVector{<:Real}, u1::AbstractVector{<:Real}) = 
    map(items -> interpolate(t0, t1, items[1], items[2]), zip(u0, u1))

constructinput(comp, u, t) = typeof(u) <: Nothing ? u : interpolate(comp.t, t, comp.inputval, u)

constructprob(comp::AbstractDiscreteSystem, x, u, t) = 
    DiscreteProblem(comp.statefunc, x, (comp.t, t), constructinput(comp, u, t))
constructprob(comp::AbstractODESystem, x, u, t) = 
    ODEProblem(comp.statefunc, x, (comp.t, t), constructinput(comp, u, t))
constructprob(comp::AbstractDAESystem, x, u, t) = 
    DAEProblem(comp.statefunc, x, comp.stateder, (comp.t, t), constructinput(comp, u, t),
    differential_vars=comp.diffvars)
constructprob(comp::AbstractRODESystem, x, u, t) = 
    RODEProblem(comp.statefunc, x, (comp.t, t), constructinput(comp, u, t), 
    noise=comp.noise.process, rand_prototype=comp.noise.prototype, seed=comp.noise.seed)
constructprob(comp::AbstractSDESystem, x, u, t) = 
    SDEProblem(comp.statefunc..., x, (comp.t, t), constructinput(comp, u, t), noise=comp.noise.process, 
    noise_rate_prototype=comp.noise.prototype, seed=comp.noise.seed)
constructprob(comp::AbstractDDESystem, x, u, t) = 
    DDEProblem(comp.statefunc, x, comp.history.func, (comp.t, t), constructinput(comp, u, t), 
    constant_lags=comp.history.conslags, dependent_lags=comp.history.depslags, neutral=comp.history.neutral)

solve(comp::AbstractDynamicSystem, x, u,t) = solve(constructprob(comp, x, u, t), comp.solver.alg; comp.solver.params...)

"""
    update!(comp::AbstractDynamicSystem, sol, u)

Updates `comp` with the differential equation solution `sol` and the input value `u`. The time `t`, state `state` and `inputval` is updated. Furthermore, `stateder` is also updated if `comp` isa `AbstractDAESystem` and `noise` is update if `comp` is `AbstractSDESystem` or `AbstractRODESystem`.
"""
function update!(comp::AbstractDynamicSystem, sol, u)
    update_time!(comp, sol.t[end])
    update_state!(comp, sol.u[end])
    update_inputval!(comp, u)
    typeof(comp) <: Union{<:AbstractSDESystem, <:AbstractRODESystem} && update_noise!(comp, sol.W)
    typeof(comp) <: AbstractDAESystem && update_stateder!(comp, sol.du[end])
    comp
end
update_time!(comp::AbstractDynamicSystem, t) = (comp.t = t; comp)
update_state!(comp::AbstractDynamicSystem, state) = (comp.state = state; comp)
update_inputval!(comp::AbstractDynamicSystem, u) = (comp.inputval = u; comp)
update_stateder!(comp::AbstractDAESystem, stateder) = (comp.stateder = stateder; comp)
function update_noise!(comp::Union{<:AbstractSDESystem, <:AbstractRODESystem}, noise)
    Z = typeof(noise.Z) <: Nothing ? noise.Z : noise.Z[end]
    comp.noise.process = NoiseProcess(noise.t[end], noise.u[end], Z, noise.dist, noise.bridge, rng=noise.rng, 
    reseed=false)
    comp
end

##### Task management
"""
    takestep(comp::AbstractComponent)

Reads the time `t` from the `trigger` link of `comp`. If `comp` is an `AbstractMemory`, a backward step is taken. Otherwise, a forward step is taken. See also: [`forwardstep`](@ref), [`backwardstep`](@ref).
"""
function takestep(comp::AbstractComponent)
    t = readtime(comp)
    # t === missing && return t
    t === NaN && return t
    typeof(comp) <: AbstractMemory ? backwardstep(comp, t) : forwardstep(comp, t)
end

"""
    forwardstep(comp, t)

Makes `comp` takes a forward step.  The input value `u` and state `x` of `comp` are read. Using `x`, `u` and time `t`,  `comp` is evolved. The output `y` of `comp` is computed and written into the output bus of `comp`. 
"""
function forwardstep(comp, t)
    u = readinput(comp)
    x = readstate(comp)
    xn = evolve!(comp, x, u, t)
    y = computeoutput(comp, xn, u, t)
    writeoutput(comp, y)
    comp.callbacks(comp)
    return t
end


"""
    backwardstep(comp, t)

Reads the state `x`. Using the time `t` and `x`, computes and writes the ouput value `y` of `comp`. Then, the input value `u` is read and `comp` is evolved.  
"""
function backwardstep(comp, t)
    x = readstate(comp)
    y = computeoutput(comp, x, nothing, t)
    writeoutput(comp, y)
    u = readinput(comp)
    xn = evolve!(comp, x, u, t)
    comp.callbacks(comp)
    return t
end


"""
    launch(comp::AbstractComponent)

Returns a tuple of tasks so that `trigger` link and `output` bus of `comp` is drivable. When launched, `comp` is ready to be driven from its `trigger` link. See also: [`drive(comp::AbstractComponent, t)`](@ref)
"""
function launch(comp::AbstractComponent)
    outputtask = if !(typeof(comp) <: AbstractSink)  # Check for `AbstractSink`.
        if !(typeof(comp.output) <: Nothing)  # Check for `Terminator`.
            @async while true 
                val = take!(comp.output)
                # all(val .=== missing) && break
                all(val .=== NaN) && break
            end
        end
    end
    triggertask = @async begin 
        while true
            # takestep(comp) === missing && break
            takestep(comp) === NaN && break
            put!(comp.handshake, true)
        end
        typeof(comp) <: AbstractSink && close(comp)
    end
    return triggertask, outputtask
end

"""
    drive(comp::AbstractComponent, t)

Writes `t` to the `trigger` link of `comp`. When driven, `comp` takes a step. See also: [`takestep(comp::AbstractComponent)`](@ref)
"""
drive(comp::AbstractComponent, t) = put!(comp.trigger, t)

"""
    approve(comp::AbstractComponent)

Read `handshake` link of `comp`. When not approved or `false` is read from the `handshake` link, the task launched for the `trigger` link of `comp` gets stuck during `comp` is taking step.
"""
approve(comp::AbstractComponent) = take!(comp.handshake)

"""
    release(comp::AbstractComponent)

Releases the `input` and `output` bus of `comp`.
""" 
function release(comp::AbstractComponent)
    typeof(comp) <: AbstractSource  || typeof(comp.input) <: Nothing    || release(comp.input)
    typeof(comp) <: AbstractSink    || typeof(comp.output) <: Nothing   || release(comp.output)
    return 
end


"""
    terminate(comp::AbstractComponent)

Closes the `trigger` link and `output` bus of `comp`.
"""
function terminate(comp::AbstractComponent)
    typeof(comp) <: AbstractSink || typeof(comp.output) <: Nothing || close(comp.output)
    close(comp.trigger)
    return 
end

##### SubSystem interface
"""
    launch(comp::AbstractSubSystem)

Launches all subcomponents of `comp`. See also: [`launch(comp::AbstractComponent)`](@ref)
"""
launch(comp::AbstractSubSystem) = launch.(comp.components)

"""
    takestep(comp::AbstractSubSystem)

Makes `comp` to take a step by making each subcomponent of `comp` take a step. See also: [`takestep(comp::AbstractComponent)`](@ref)
"""
function takestep(comp::AbstractSubSystem)
    t = readtime(comp)
    # t === missing && return t
    t === NaN && return t
    foreach(takestep, comp.components)
    approve(comp) ||  @warn "Could not be approved in the subsystem"
    put!(comp.handshake, true)
end

"""
    drive(comp::AbstractSubSystem, t)

Drives `comp` by driving each subcomponent of `comp`. See also: [`drive(comp::AbstractComponent, t)`](@ref)
"""
drive(comp::AbstractSubSystem, t) = foreach(component -> drive(component, t), comp.components)

"""
    approve(comp::AbstractSubSystem)

Approves `comp` by approving each subcomponent of `comp`. See also: [`approve(comp::AbstractComponent)`](@ref)
"""
approve(comp::AbstractSubSystem) = all(approve.(comp.components))


""" 
    release(comp::AbstractSubSystem)

Releases `comp` by releasing each subcomponent of `comp`. See also: [`release(comp::AbstractComponent)`](@ref)
"""
function release(comp::AbstractSubSystem)
    foreach(release, comp.components)
    typeof(comp.input) <: Bus && release(comp.input)
    typeof(comp.output) <: Bus && release(comp.output)
end

"""
    terminate(comp::AbstractSubSystem)

Terminates `comp` by terminating each subcomponent of `comp`. See also: [`terminate(comp::AbstractComponent)`](@ref)
"""
terminate(comp::AbstractSubSystem) = foreach(terminate, comp.components)
