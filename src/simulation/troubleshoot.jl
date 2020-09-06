
export troubleshoot

"""
    $(SIGNATURES)

Prints the exceptions of the tasks that are failed during the simulation of `model`.
"""
function troubleshoot(model::Model)
    fails = filter(pair -> istaskfailed(pair.second), model.taskmanager.pairs)
    if isempty(fails)
        @info "No failed tasks in $model."
    else
        for (comp, task) in fails
            println("", comp)
            @error task.exception
        end
    end
end
