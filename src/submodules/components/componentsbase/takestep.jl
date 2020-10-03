# This file includes stepping of abstract types.

export readtime!, readstate, readinput!, writeoutput!, computeoutput, evolve!, takestep!, forwardstep, backwardstep, 
    drive!, approve!, terminate!

##### Input-Output reading and writing.
"""
    $(SIGNATURES)

Returns current time of `comp` read from its `trigger` link.

!!! note 
    To read time of `comp`, `comp` must be launched. See also: [`launch(comp::AbstractComponent)`](@ref).
"""
readtime!(comp::AbstractComponent) = take!(comp.trigger)

"""
    $(SIGNATURES)

Returns the state of `comp` if `comp` is `AbstractDynamicSystem`. Otherwise, returns `nothing`. 
"""
readstate(comp::AbstractComponent) = typeof(comp) <: AbstractDynamicSystem ? comp.state : nothing

"""
    $(SIGNATURES)

Returns the input value of `comp` if the `input` of `comp` is `Inport`. Otherwise, returns `nothing`.

!!! note 
    To read input value of `comp`, `comp` must be launched. See also: [`launch(comp::AbstractComponent)`](@ref)
"""
function readinput!(comp::AbstractComponent)
    typeof(comp) <: AbstractSource && return nothing
    input = comp.input 
    # When the length of the input is one, we unwrap the read value with `only`.
    typeof(input) <: Inport ? (length(input) == 1 ? only(take!(input)) : take!(input)) : nothing
end

"""
    $(SIGNATURES)

Writes `out` to the output of `comp` if the `output` of `comp` is `Outport`. Otherwise, does `nothing`.
"""
function writeoutput!(comp::AbstractComponent, out)
    typeof(comp) <: AbstractSink && return nothing  
    # NOTE: When output has single pin, we wrap the output as [out].
    output = comp.output  
    typeof(output) <: Outport ? ( length(output) == 1 ? put!(output, [out]) : put!(output, out) ) : nothing
end


"""
    $(SIGNATURES)

Computes the output of `comp` according to its `readout` if `readout` is not `nothing`. Otherwise, `nothing` is done. `x` is the state, `u` is the value of input, `t` is the time. 
"""
function computeoutput end
computeoutput(comp::AbstractSource, x, u, t) = readout(comp, t)
computeoutput(comp::AbstractStaticSystem, x, u, t) =  
    typeof(comp.output) <: Nothing ? nothing : readout(comp, u, t)
function computeoutput(comp::AbstractDynamicSystem, x, u, t)
    typeof(comp.output) <: Nothing && return nothing
    typeof(u) <: Nothing ? readout(comp, x, u, t) : readout(comp, x, map(uu -> t -> uu, u), t) 
end
computeoutput(comp::AbstractSink, x, u, t) = nothing

"""
    $(SIGNATURES)

Evolves `comp` with the current input `u` and `t`.

* If `comp` is `AbstractSource`, nothing is done.

* If `comp` is `AbstractSink`, writes `t` to time buffer `timebuf` and `u` to `databuf` of `comp`. `u` is the value of `input` and `t` is time.

* If `comp` is `AbstractStaticSystem`, writes `u` to `buffer` of `comp` if `comp` is an `AbstractMemory`. Otherwise, `nothing` is done. `u` is the value of `input` and `t` is time. 

* If `compo` is `AbstractDynamicSystem`, solves the differential equation of the system of `comp` for the time interval `(comp.t, t)` for the inital condition `x` where `x` is the current state of `comp` . `u` is the input function defined for `(comp.t, t)`. The `comp` is updated with the computed state and time `t`. 
"""
function evolve! end
evolve!(comp::AbstractSource, u, t) = nothing
function evolve!(comp::AbstractSink, u, t) 
    timebuf = comp.timebuf
    databuf = comp.databuf 
    write!(timebuf, t)
    length(comp.input) == 1 ? write!(databuf, u) : for (buf, item) in zip(databuf, u) write!(buf, item) end
    comp.sinkcallback(comp)
    nothing
end

function evolve!(comp::AbstractStaticSystem, u, t) 
    if typeof(comp) <: AbstractMemory 
        write!(comp.timebuf, t)
        write!(comp.databuf, u)
    end
end
function evolve!(comp::AbstractDynamicSystem, u, t)
    # For DDESystems, the problem for a time span of (t, t) cannot be solved. 
    # Thus, there will be no evolution in such a case.
    updateinterp!(comp.interpolant, u, t)
    comp.t == t && return comp.state  
    
    # Advance the system and update the system.
    integrator = comp.integrator
    step!(integrator, t - comp.t, true)
    comp.t = integrator.t
    comp.state = deepcopy(integrator.u) # Isolate integrator state from comp state by using `copy`.

    # Return comp state
    return comp.state
end
updateinterp!(interp::Nothing) = nothing
updateinterp!(interp::Nothing, u, t) = nothing
function updateinterp!(interp::Interpolant, u, t)
    write!(interp.timebuf, t)
    write!(interp.databuf, u)
    update!(interp)
end

##### Task management
"""
    $(SIGNATURES)

Reads the time `t` from the `trigger` link of `comp`. If `comp` is an `AbstractMemory`, a backward step is taken. Otherwise, a forward step is taken. See also: [`forwardstep`](@ref), [`backwardstep`](@ref).
"""
function takestep!(comp::AbstractComponent)
    t = readtime!(comp)
    t === NaN && return t
    typeof(comp) <: AbstractMemory ? backwardstep(comp, t) : forwardstep(comp, t)
end

"""
    $(SIGNATURES)

Makes `comp` takes a forward step.  The input value `u` and state `x` of `comp` are read. Using `x`, `u` and time `t`,  `comp` is evolved. The output `y` of `comp` is computed and written into the output bus of `comp`. 
"""
function forwardstep(comp, t)
    u = readinput!(comp)
    x = evolve!(comp, u, t)
    y = computeoutput(comp, x, u, t)
    writeoutput!(comp, y)
    applycallbacks(comp)
    return t
end


"""
    $SIGNATURES)

Reads the state `x`. Using the time `t` and `x`, computes and writes the ouput value `y` of `comp`. Then, the input value `u` is read and `comp` is evolved.  
"""
function backwardstep(comp, t)
    x = readstate(comp)
    y = computeoutput(comp, x, nothing, t)
    writeoutput!(comp, y)
    u = readinput!(comp)
    xn = evolve!(comp, u, t)
    applycallbacks(comp)
    return t
end

"""
    $(SIGNATURES)

Returns a tuple of tasks so that `trigger` link and `output` bus of `comp` is drivable. When launched, `comp` is ready to be driven from its `trigger` link. See also: [`drive!(comp::AbstractComponent, t)`](@ref)
"""
function launch(comp::AbstractComponent) 
    @async begin 
        while true
            takestep!(comp) === NaN && break
            put!(comp.handshake, true)
        end
        typeof(comp) <: AbstractSink && close(comp)
    end
end

"""
    $(SIGNATURES)

Writes `t` to the `trigger` link of `comp`. When driven, `comp` takes a step. See also: [`takestep!(comp::AbstractComponent)`](@ref)
"""
drive!(comp::AbstractComponent, t) = put!(comp.trigger, t)

"""
    $(SIGNATURES)

Read `handshake` link of `comp`. When not approved or `false` is read from the `handshake` link, the task launched for the `trigger` link of `comp` gets stuck during `comp` is taking step.
"""
approve!(comp::AbstractComponent) = take!(comp.handshake)


"""
    $(SIGNATURES)

Closes the `trigger` link and `output` bus of `comp`.
"""
function terminate!(comp::AbstractComponent)
    typeof(comp) <: AbstractSink || typeof(comp.output) <: Nothing || close(comp.output)
    close(comp.trigger)
    return 
end

##### SubSystem interface
"""
    $(SIGNATURES)

Launches all subcomponents of `comp`. See also: [`launch(comp::AbstractComponent)`](@ref)
"""
function launch(comp::AbstractSubSystem)
    comptask = @async begin 
        while true
            if takestep!(comp) === NaN 
                put!(comp.triggerport, fill(NaN, length(comp.components)))
                break   
            end
            put!(comp.handshake, true)
        end
    end
    [launch.(comp.components)..., comptask]
end

"""
    $(SIGNATURES)

Makes `comp` to take a step by making each subcomponent of `comp` take a step. See also: [`takestep!(comp::AbstractComponent)`](@ref)
"""
function takestep!(comp::AbstractSubSystem)
    t = readtime!(comp)
    t === NaN && return t
    put!(comp.triggerport, fill(t, length(comp.components)))
    all(take!(comp.handshakeport)) || @warn "Could not be approved in the subsystem"
    # foreach(takestep!, comp.components)
    # approve!(comp) ||  @warn "Could not be approved in the subsystem"
    # put!(comp.handshake, true)
end

"""
    $(SIGNATURES)

Drives `comp` by driving each subcomponent of `comp`. See also: [`drive!(comp::AbstractComponent, t)`](@ref)
"""
drive!(comp::AbstractSubSystem, t) = foreach(component -> drive!(component, t), comp.components)

"""
    $(SIGNATURES)

Approves `comp` by approving each subcomponent of `comp`. See also: [`approve!(comp::AbstractComponent)`](@ref)
"""
approve!(comp::AbstractSubSystem) = all(approve!.(comp.components))

"""
    $(SIGNATURES)

Terminates `comp` by terminating each subcomponent of `comp`. See also: [`terminate!(comp::AbstractComponent)`](@ref)
"""
terminate!(comp::AbstractSubSystem) = foreach(terminate!, comp.components)

