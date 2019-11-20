# This file is for TaskManager object.

import Base: istaskdone

struct ComponentTask{T, S}
    triggertask::T 
    outputtask::S 
end
ComponentTask(tasks::Tuple) = ComponentTask(tasks...)
ComponentTask(tasks::AbstractArray{<:Tuple}) = [ComponentTask.(tasks...)...]

mutable struct TaskManager{T, S}
    pairs::Dict{T, S}
    callbacks::Vector{Callback}
    id::UUID
    TaskManager(pairs::Dict{T, S}) where {T, S}  = new{T, S}(pairs, Callback[], uuid4())
end
TaskManager() = TaskManager(Dict{Any, Any}())

show(io::IO, tm::TaskManager) = print(io, "TaskManager(pairs:$(tm.pairs))")

function checktaskmanager(tm::TaskManager)
    for (block, comptask) in tm.pairs
        # istaskfailed(comptask) && error("$comptask failed for $block")
        checkcomptask(comptask) || error("$comptask failed for $block")
    end
end
function checkcomptask(comptask)
    if typeof(comptask) <: ComponentTask
        istaskfailed(comptask) ? false : true
    elseif typeof(comptask) <: AbstractArray
        return checkcomptask(comptask...)
    end
end
checkcomptask(comptask...) = all(checkcomptask.(comptask))

istaskfailed(task::Nothing) = false
istaskfailed(task::Task) = task.state == :failed
istaskfailed(comptask::ComponentTask) = istaskfailed(comptask.triggertask) || istaskfailed(comptask.outputtask)

istaskrunning(task::Task) = task.state == :runnable
istaskrunning(task::Nothing) = true
istaskrunning(comptask::ComponentTask) = istaskrunning(comptask.triggertask) && istaskrunning(comptask.outputtask)

istaskdone(task::Nothing) = true
istaskdone(comptask::ComponentTask) = istaskdone(comptask.triggertask) && istaskdone(comptask.outputtask)

