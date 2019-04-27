# This file is for TaskManager object.


mutable struct TaskManager{T} <: AbstractTaskManager
    pairs::Dict{T, Task}
    callbacks::Vector{Callback}
    name::String
end
TaskManager(;callbacks=Callback[], name=string(uuid4())) = TaskManager(Dict{Any,Task}(), callbacks, name)


"""
    checktasks(taksmanager)

Returns `true` if one of the task in the look-up table of the `taskmanager` fails.
"""
function checktasks(taskmanager::TaskManager)
    for (block, task) in taskmanager.pairs
        istaskfailed(task) && error("$task failed for $block")
    end
end


"""
    istaskfailed(task)

Returns `true` if current status of `task` is `:failed`.
"""
istaskfailed(task) = task.state == :failed

"""
    istaskrunning(task)

Returns true if state of `task` is `:runnable`.
"""
istaskrunning(task) = task.state == :runnable

"""
    isalive(taskmanager)

Returns true if any of the task that `taskmanager` monitors fails or there is no tasks monitored by the `taskmanager`.
"""
isalive(taskmanager) = !isempty(taskmanager.pairs) && all(istaskrunning.(values(taskmanager.pairs)))
