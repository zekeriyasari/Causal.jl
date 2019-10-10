# This file is for TaskManager object.


mutable struct TaskManager{T, S}
    pairs::Dict{T, S}
    callbacks::Vector{Callback}
    id::UUID
    TaskManager(pairs::Dict{T, S}) where {T, S}  = new{T, S}(pairs, Callback[], uuid4())
end
TaskManager() = TaskManager(Dict{Any, Union{Task, Vector{Task}}}())

show(io::IO, tm::TaskManager) = print(io, "TaskManager(pairs:$(tm.pairs))")

function checktasks(tm::TaskManager)
    for (block, task) in tm.pairs
        istaskfailed(task) && error("$task failed for $block")
    end
end

istaskfailed(task::Task) = task.state == :failed
istaskfailed(task::Vector{Task}) = any(istaskfailed.(task))  # Subsystem interface
istaskrunning(task) = task.state == :runnable
isalive(tm) = !isempty(tm.pairs) && all(istaskrunning.(values(tm.pairs)))
