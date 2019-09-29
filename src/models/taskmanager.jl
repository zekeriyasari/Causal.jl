# This file is for TaskManager object.


mutable struct TaskManager{T}
    pairs::Dict{T, Task}
    callbacks::Vector{Callback}
    id::UUID
    TaskManager(pairs::Dict{T, Task}) where T  = new{T}(pairs, Callback[], uuid4())
end
TaskManager() = TaskManager(Dict{Any, Task}())

show(io::IO, tm::TaskManager) = print(io, "TaskManager(pairs:$(tm.pairs))")

function checktasks(tm::TaskManager)
    for (block, task) in tm.pairs
        istaskfailed(task) && error("$task failed for $block")
    end
end

istaskfailed(task) = task.state == :failed
istaskrunning(task) = task.state == :runnable
isalive(tm) = !isempty(tm.pairs) && all(istaskrunning.(values(tm.pairs)))
