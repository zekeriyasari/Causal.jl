
export terminate!

"""
    $(SIGNATURES)

Terminates `model` by terminating all the components of the `model`, i.e., the components tasks in the task manager of the `model` is terminated.
"""
function terminate!(model::Model)
    taskmanager = model.taskmanager
    tasks = unwrap(collect(values(taskmanager.pairs)), Task, depth=length(taskmanager.pairs))
    any(istaskstarted.(tasks)) && put!(taskmanager.triggerport, fill(NaN, length(model.nodes)))
    isrunning(model.clock) && stop!(model.clock)
    model
end

function unwrap(container, etype; depth=10)
    for i in 1 : depth
        container = vcat(container...)
        eltype(container) == etype && break
    end
    container
end
