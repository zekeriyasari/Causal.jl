# This file is for TaskManager object.

import Base: istaskdone, istaskfailed

"""
    ComponentTask(triggertask, outputtask)

Constructs a `ComponentTask` from `triggertask` and `outputtask`. `triggertask` is the task constructed for the evolution of components and `outputtask` task is contructed to make the output busses of the components writable. 

# Example
```julia 
julia> gen = SinewaveGenerator()
SinewaveGenerator(amp:1.0, freq:1.0, phase:0.0, offset:0.0, delay:0.0)

julia> taskpair = launch(gen)
(Task (runnable) @0x00007f4de65544f0, Task (runnable) @0x00007f4de5e8fd00)

julia> comptask = ComponentTask(taskpair)
ComponentTask{Task,Task}(Task (runnable) @0x00007f4de65544f0, Task (runnable) @0x00007f4de5e8fd00)
```
"""
struct ComponentTask{T, S}
    triggertask::T 
    outputtask::S 
end
ComponentTask(tasks::Tuple) = ComponentTask(tasks...)
ComponentTask(tasks::AbstractArray{<:Tuple}) = [ComponentTask.(tasks...)...]

"""
    TaskManager(pairs)

Constructs a `TaskManager` with `pairs`. `pairs` is a dictionary whose keys are components and values are component tasks. Component tasks are constructed correponding to the components. A `TaskManager` is used to keep track of the component task launched corresponding to components.

    TaskManager()

Constructs a `TaskManager` with empty `pairs.

# Example 
```julia
julia> tm = TaskManager()  # A TaskManager with empty pairs
TaskManager(pairs:Dict{Any,Any}())

julia> gen = SinewaveGenerator()  # A component
SinewaveGenerator(amp:1.0, freq:1.0, phase:0.0, offset:0.0, delay:0.0)

julia> ct = ComponentTask(launch(gen))  # A component task corresponding to gen
ComponentTask{Task,Task}(Task (runnable) @0x00007f4de1a0d390, Task (runnable) @0x00007f4de1a0d120)

julia> tm.pairs[gen] = ct  # Write a component and compontent task pair into TaskManager
ComponentTask{Task,Task}(Task (runnable) @0x00007f4de1a0d390, Task (runnable) @0x00007f4de1a0d120)

julia> println(tm.pairs)
Dict{Any,Any}(SinewaveGenerator(amp:1.0, freq:1.0, phase:0.0, offset:0.0, delay:0.0) => ComponentTask{Task,Task}(Task (runnable) @0x00007f4de1a0d390, Task (runnable) @0x00007f4de1a0d120))
```
"""
mutable struct TaskManager{T, S}
    pairs::Dict{T, S}
    callbacks::Vector{Callback}
    id::UUID
    TaskManager(pairs::Dict{T, S}) where {T, S}  = new{T, S}(pairs, Callback[], uuid4())
end
TaskManager() = TaskManager(Dict{Any, Any}())

show(io::IO, tm::TaskManager) = print(io, "TaskManager(pairs:$(tm.pairs))")

"""
    checktaskmanager(tm::TaskManager)

Throws an error if any of the component task of `tm` is failed. See also: [`TaskManager`](@ref)
"""
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

"""
    istaskfailed(task::Nothing)

Returns `false`.

    istaskfailed(comptask::ComponentTask)

Returns `true` is `triggertask` or `outputtask` of `comptask` is failed. See also: [`ComponentTask`](@ref)
"""
function istaskfailed end
istaskfailed(task::Nothing) = false
# istaskfailed(task::Task) = task.state == :failed  # Already built-in in Base module of Julia standard library.
istaskfailed(comptask::ComponentTask) = istaskfailed(comptask.triggertask) || istaskfailed(comptask.outputtask)

"""
    istaskrunning(task::Task)

Returns `true` is the state of `task` is `runnable`. 

    istaskrunning(task::Nothing)

Returns `true`

    istaskrunning(comptask::ComponentTask)

Returns `true` if `triggertask` and `outputtask` of `comptask` is running. See also: [`ComponentTask`](@ref)
"""
function istaskrunning end
istaskrunning(task::Task) = task.state == :runnable
istaskrunning(task::Nothing) = true
istaskrunning(comptask::ComponentTask) = istaskrunning(comptask.triggertask) && istaskrunning(comptask.outputtask)

"""
    istaskrunning(task::Nothing)

Returns `true` 

    istaskdone(comptask::ComponentTask)

Returns `true` if the state of `triggertask` and `outputtask` of `comptask` is `done`. See also: [`ComponentTask`](@ref)
"""
function istaskdone end
istaskdone(task::Nothing) = true
istaskdone(comptask::ComponentTask) = istaskdone(comptask.triggertask) && istaskdone(comptask.outputtask)

