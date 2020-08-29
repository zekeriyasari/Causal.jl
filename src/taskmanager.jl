# This file is for TaskManager object.

export TaskManager, checktaskmanager

"""
    $(TYPEDEF) 

A `TaskManager` with `pairs`. `pairs` is a dictionary whose keys are components and values are component tasks. Component tasks are constructed correponding to the components. A `TaskManager` is used to keep track of the component task launched corresponding to components.

# Fields 

    $(TYPEDFIELDS)
```
"""
mutable struct TaskManager{T, S, IP, OP, CB}
    pairs::Dict{T, S}
    handshakeport::IP 
    triggerport::OP
    callbacks::CB
    name::Symbol
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
    checktaskmanager(tm::TaskManager)

Throws an error if any of the component task of `tm` is failed. See also: [`TaskManager`](@ref)
"""
function checktaskmanager(tm::TaskManager)
    for (component, task) in tm.pairs
        # NOTE: If any of the tasks of the taskmanager failes during its computation, the tasks are fetched 
        # to cancel the simulation and stacktrace is printed to report the error.
        checktask(task) || (@error "Failed for $component"; fetch(task))
    end
end

function checktask(task)
    if typeof(task) <: AbstractArray
        return checktask(task...)
    else
        istaskfailed(task) ? false : true
    end
end
checktask(task...) = all(checktask.(task))
