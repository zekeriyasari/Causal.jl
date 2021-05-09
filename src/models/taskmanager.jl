# This file is for TaskManager object.

"""
    $TYPEDEF 

Constructs a `TaskManager` with `pairs`. `pairs` is a dictionary whose keys are components and values are component tasks.
Component tasks are constructed correponding to the components. A `TaskManager` is used to keep track of the component task
launched corresponding to components.

# Fields 

    $TYPEDFIELDS
```
"""
mutable struct TaskManager{T, S, IP, OP, CB}
    "Node-task pair"
    pairs::Dict{T, S}
    "Handshake port of task manager. Used for handshake"
    handshakeport::IP 
    "Trigger port of task manager. Used to trigger components"
    triggerport::OP
    "Callback set. [`Callback`](@ref)"
    callbacks::CB
    "Name of task manager"
    name::Symbol
    "Unique identifier"
    id::UUID
    function TaskManager(pairs::Dict{T, S}; callbacks=nothing, name=Symbol()) where {T, S}
        triggerport, handshakeport =  Outport(0), Inport{Bool}(0)
        new{T, S, typeof(handshakeport), typeof(triggerport), typeof(callbacks)}(pairs, handshakeport, triggerport, 
            callbacks, name, uuid4())
    end
end
TaskManager() = TaskManager(Dict{Any, Any}())

show(io::IO, tm::TaskManager) = print(io, "TaskManager(pairs:$(tm.pairs))")

"""
    $SIGNATURES

Throws an error if any of the component task of `tm` is failed. See also: [`TaskManager`](@ref)
"""
function checktaskmanager(tm::TaskManager)
    for (component, comptask) in tm.pairs
        # NOTE: If any of the tasks of the taskmanager failes during its computation, the tasks are fetched to cancel the
        # simulation and stacktrace is printed to report the error.
        checkcomptask(comptask) || (@error "Failed for $component"; fetch(comptask))
    end
end

function checkcomptask(comptask)
    if typeof(comptask) <: AbstractArray
        return checkcomptask(comptask...)
    else
        istaskfailed(comptask) ? false : true
    end
end
checkcomptask(comptask...) = all(checkcomptask.(comptask))

"""
    $SIGNATURES

Returns `true` is the state of `task` is `runnable`. 
"""
istaskrunning(task::Task) = task.state == :runnable
