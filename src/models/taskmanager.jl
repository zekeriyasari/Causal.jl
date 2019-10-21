# This file is for TaskManager object.

import Base: istaskdone

struct ComponentTask{T, S}
    triggertask::T 
    outputtask::S 
end
ComponentTask(tasks::Union{<:AbstractArray, <:Tuple}) = ComponentTask(tasks[1], tasks[2])

mutable struct TaskManager{T, S}
    pairs::Dict{T, S}
    callbacks::Vector{Callback}
    id::UUID
    TaskManager(pairs::Dict{T, S}) where {T, S}  = new{T, S}(pairs, Callback[], uuid4())
end
TaskManager() = TaskManager(Dict{Any, Union{<:ComponentTask, Vector{<:ComponentTask}}}())

show(io::IO, tm::TaskManager) = print(io, "TaskManager(pairs:$(tm.pairs))")

function checktaskmanager(tm::TaskManager)
    for (block, task) in tm.pairs
        istaskfailed(task) && error("$task failed for $block")
    end
end

istaskfailed(task::Nothing) = false
istaskfailed(task::Task) = task.state == :failed
istaskfailed(comptask::ComponentTask) = istaskfailed(comptask.triggertask) || istaskfailed(comptask.outputtask)
istaskfailed(comptasks::Vector{<:ComponentTask}) = any(istaskfailed.(comptasks))  # Subsystem interface

istaskrunning(task::Task) = task.state == :runnable
istaskrunning(task::Nothing) = true
istaskrunning(comptask::ComponentTask) = istaskrunning(comptask.triggertask) && istaskrunning(comptask.outputtask)
istaskrunning(comptasks::Vector{<:ComponentTask}) = all(istaskrunning.(comptasks))

istaskdone(task::Nothing) = true
istaskdone(comptask::ComponentTask) = istaskdone(comptask.triggertask) && istaskdone(comptask.outputtask)
istaskdone(comptasks::Vector{<:ComponentTask}) = all(istaskdone.(comptasks))

