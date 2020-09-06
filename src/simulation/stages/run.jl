
export run!

macro def(name, code)
    quote
        macro $(esc(name))()
            esc($(Meta.quot(code)))
        end
    end
end

# Copy-paste loop body. See `run!(model, withbar)`.
# NOTE: We first trigger the component, Then the tasks fo the `taskmanager` is checked. If an error is thrown in one 
# of the tasks, the simulation is cancelled and stacktrace is printed reporting the error. In order to ensure the 
# time synchronization between the components of the model, `handshakeport` of the taskmanger is read. When all the 
# components take step succesfully, then the simulation goes with the next step after calling the callbacks of the 
# components.
# Note we first check the tasks of the taskmanager and then read the `handshakeport` of the taskmanager. Otherwise, 
# the simulation gets stuck without printing the stacktrace if an error occurs in one of the tasks of the taskmanager.
@def loopbody begin 
    put!(triggerport, fill(t, ncomponents))
    checktaskmanager(taskmanager)          
    all(take!(handshakeport)) || @warn "Taking step could not be approved."
    applycallbacks(model)
end


"""
    $(SIGNATURES)

Runs the `model` by triggering the components of the `model`. This triggering is done by generating clock tick using the model clock `model.clock`. Triggering starts with initial time of model clock, goes on with a step size of the sampling period of the model clock, and finishes at the finishing time of the model clock. If `withbar` is `true`, a progress bar indicating the simulation status is displayed on the console.

!!! warning 
    The `model` must first be initialized to be run. See also: [`initialize!`](@ref).
"""
function run!(model::Model, withbar::Bool=true)
    taskmanager = model.taskmanager
    triggerport, handshakeport = taskmanager.triggerport, taskmanager.handshakeport
    ncomponents = length(model.nodes)
    clock = model.clock
    withbar ? (@showprogress clock.dt for t in clock @loopbody end) : (for t in clock @loopbody end)
    model
end
