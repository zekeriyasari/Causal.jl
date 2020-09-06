
export initialize!

"""
    $(SIGNATURES)

Initializes `model` by launching component task for each of the component of `model`. The pairs component and component tasks are recordedin the task manager of the `model`. The `model` clock is [`set!`](@ref) and the files of [`Writer`](@ref) are openned.
"""
function initialize!(model::Model)
    # NOTE: Tasks to make the components be triggerable are launched here.
    # The important point here is that the simulation should be cancelled if an error is thrown in any of the tasks 
    # launched here. This is done by binding the task to the chnnel of the trigger link of the component. Hrence the 
    # lifetime of the channel of the link connecting the component to the taskmanger is determined by the lifetime of 
    # the task launched for the component. To cancel the simulation and report the stacktrace the task is `fetch`ed. 
    bind!(model)

    # Turn on clock model clock if it is running. 
    initclock!(model)

    # Clean the model 
    clean!(model)
    
    # Open the files, GUI's for sink components. 
    opensinks!(model)
end

# Find the link connecting `component` to `taskmanager`.
function whichlink(taskmanager, component)
    tpin = component.trigger
    tport = taskmanager.triggerport
    # NOTE: `component` must be connected to `taskmanager` by a single link which is checked by `only`
    # `outpin.links` must have just a single link which checked by `only`
    outpin = filter(pin -> isconnected(pin, tpin), tport) |> only 
    outpin.links |> only
end

# Bind tasks to connections 
function bind!(model::Model)
    taskmanager = model.taskmanager
    pairs = taskmanager.pairs
    nodes = model.nodes
    for node in nodes 
        component = node.component
        link = whichlink(taskmanager, component)  # Link connecting the component to taskmanager. 
        task = launch(component)    # Task launched to make `componnent` be triggerable.
        bind(link.channel, task)    # Bind the task to the channel of the link. 
        pairs[component] = task 
    end
    model 
end

# Open AbstractSink components 
function opensinks!(model::Model)
    foreach(node -> open(node.component), filter(node->isa(node.component, AbstractSink), model.nodes))
    model 
end 

# Initialze model clock 
function initclock!(model::Model)
    if isoutoftime(model.clock)
        msg = "Model clock is out of time. Its current time $(model.clock.t) should be less than its final time "
        msg *= "$(model.clock.tf). Resettting the model clock to its defaults."
        @warn msg
        set!(model.clock)
    end
    isrunning(model.clock) || set!(model.clock)  
    model
end

"""
    $(SIGNATURES)

Cleans the buffers of the links of the connections, internal buffers of components, current time of dynamical systems.
"""
function clean!(model::Model)
    cleanbranches!(model)
    cleannodes!(model)
    resetdynamicalsystems!(model)
    model 
end

function cleanbranches!(model) 
    foreach(branch -> foreach(link -> clean!(link), branch.links), model.branches)
    model 
end 

function cleannodes!(model)
    foreach(node -> cleancomponent!(node.component), model.nodes)
    model
end

function cleancomponent!(comp::T) where T
    foreach(name -> (field = getfield(comp, name); field isa Buffer && clean!(field)), fieldnames(T))
    comp 
end 

function resetdynamicalsystems!(model)
    t = model.clock.ti
    for comp in filter(comp -> comp isa AbstractDynamicSystem, getfield.(model.nodes, :component))
        comp.t != t && (comp.t = t) 
        reinit!(comp.integrator)
        comp.input === nothing || (interp = comp.interpolant; clean!(interp.timebuf); clean!(interp.databuf))
    end
    model
end
