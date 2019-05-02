# This file is for TaskManager object.


mutable struct TaskManager{T} <: AbstractTaskManager
    pairs::Dict{T, Task}
    callbacks::Vector{Callback}
    name::String
end
TaskManager(;callbacks=Callback[], name=string(uuid4())) = TaskManager(Dict{Any,Task}(), callbacks, name)


# """
#     checktasks(taksmanager)

# Returns `true` if one of the task in the look-up table of the `taskmanager` fails.
# """
function checktasks(taskmanager::TaskManager)
    for (block, task) in taskmanager.pairs
        istaskfailed(task) && error("$task failed for $block")
    end
end



istaskfailed(task) = task.state == :failed


istaskrunning(task) = task.state == :runnable


isalive(taskmanager) = !isempty(taskmanager.pairs) && all(istaskrunning.(values(taskmanager.pairs)))
