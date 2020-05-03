# This file is for TaskManager object.

"""
    TaskManager(pairs)

Constructs a `TaskManager` with `pairs`. `pairs` is a dictionary whose keys are components and values are component tasks. Component tasks are constructed correponding to the components. A `TaskManager` is used to keep track of the component task launched corresponding to components.

    TaskManager()

Constructs a `TaskManager` with empty `pairs`.
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
    for (component, comptask) in tm.pairs
        checkcomptask(comptask) || (@info "Failed for $component"; fetch(comptask))  # `fetch` is called to print error.
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
    istaskfailed(task::Nothing)

Returns `false`.

    istaskfailed(comptask::ComponentTask)

Returns `true` is `triggertask` or `outputtask` of `comptask` is failed.
"""
# function istaskfailed end
# istaskfailed(task::Nothing) = false
# istaskfailed(comptask::ComponentTask) = istaskfailed(comptask.triggertask) || istaskfailed(comptask.outputtask)

"""
    istaskrunning(task::Task)

Returns `true` is the state of `task` is `runnable`. 

    istaskrunning(task::Nothing)

Returns `true`

    istaskrunning(comptask::ComponentTask)

Returns `true` if `triggertask` and `outputtask` of `comptask` is running. 
"""
function istaskrunning end
istaskrunning(task::Task) = task.state == :runnable
# istaskrunning(task::Nothing) = true
# istaskrunning(comptask::ComponentTask) = istaskrunning(comptask.triggertask) && istaskrunning(comptask.outputtask)

# """
#     istaskrunning(task::Nothing)

# Returns `true` 

#     istaskdone(comptask::ComponentTask)

# Returns `true` if the state of `triggertask` and `outputtask` of `comptask` is `done`.
# """
# function istaskdone end
# istaskdone(task::Nothing) = true
# istaskdone(comptask::ComponentTask) = istaskdone(comptask.triggertask) && istaskdone(comptask.outputtask)

