# This file is for TaskManager object.


mutable struct TaskManager{T} <: AbstractTaskManager
    pairs::Dict{T, Task}
    callbacks::Vector{Callback}
    id::UUID
end
TaskManager() = TaskManager(Dict{Any,Task}(), Callback[], uuid4())


function checktasks(taskmanager::TaskManager)
    for (block, task) in taskmanager.pairs
        istaskfailed(task) && error("$task failed for $block")
    end
end

istaskfailed(task) = task.state == :failed
istaskrunning(task) = task.state == :runnable
isalive(taskmanager) = !isempty(taskmanager.pairs) && all(istaskrunning.(values(taskmanager.pairs)))
