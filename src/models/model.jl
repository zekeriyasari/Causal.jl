# This file includes the Model object


mutable struct Model{BL<:AbstractVector, CLK, TM}
    blocks::BL
    clk::CLK
    taskmanager::TM
    callbacks::Vector{Callback}
    id::UUID
    function Model(blocks)
        taskmanager = TaskManager()
        clk = Clock(NaN, NaN, NaN)
        new{typeof(blocks), typeof(clk), typeof(taskmanager)}(blocks, clk, taskmanager, Callback[], uuid4())
    end
end
Model(blocks...) = Model([blocks...])

show(io::IO, model::Model) = print(io, "Model(blocks:$(model.blocks))")

##### Model inspection.
function adjacency_matrix(model::Model)
    blocks = model.blocks
    n = length(model.blocks) 
    mat = zeros(Int, n, n)
    for i = 1 : n 
        for j = 1 : n 
            if isconnected(blocks[i].output, blocks[j].input)
                mat[i, j] = 1
            end
        end
    end
    mat
end

isterminated(output) = isa(output, Nothing) ? true : hasslaves(output)
has_unterminated_bus(model::Model) = any([!isterminated(block.output) for block in model.blocks if !isa(block, AbstractSink)])

function terminate_securely!(model::Model)
    # TODO: Complete the function.
    nothing
end

function has_algeraic_loop(model::Model)
    # TODO: Complete the function
    false
end

function break_algebraic_loop!(model)
    # TODO: Complete the function
    nothing
end

function inspect(model)
    # TODO : Complete the function.
    if has_unterminated_bus(model)
        msg = "Model has unterminated busses. Please check the model carefully for unterminated busses."
        throw(SimulationError(msg))
    end
    if has_algeraic_loop(model)
        try
            break_algebraic_loop!(model)
        catch
            error("Algebric loop cannot be broken.")
        end
    end
end

##### Model initialization
function initialize(model::Model)
    pairs = model.taskmanager.pairs
    blocks = model.blocks
    for block in blocks
        pairs[block] = launch(block)
    end
    isrunning(model.clk) || set!(model.clk)  # Turnon clock internal generator.
    # isrunning(model.clk) || turnon(model.clk)  # Turnon clock internal generator.
    for writer in filter(block->isa(block, Writer), model.blocks)  # Open writer files.
        writer.file = jldopen(writer.file.path, "a")
    end
end

##### Model running

# drive(component::AbstractComponent, t) = put!(component.clk_link, t)    
# update(memory::Memory, t) = write!(memory.buffer, memory.input(t))

function run(model::Model)
    taskmanager = model.taskmanager
    components = model.blocks
    clk = model.clk
    for t in clk
        foreach(component -> drive(component, t), components)       # Drive _blocks with time tick of the clock.
        # foreach(memory -> update(memory, t), memories)              # Update memories after driving _blocks.
        checktasks(taskmanager)                                     # Check if the task are running.
    end
    # components = blocks[isa.(blocks, AbstractComponent)]
    # memories = components[isa.(components, Memory)]     # Memory components
    # for t in clk
    #     foreach(component -> drive(component, t), components)       # Drive _blocks with time tick of the clock.
    #     # foreach(memory -> update(memory, t), memories)              # Update memories after driving _blocks.
    #     checktasks(taskmanager)                                     # Check if the task are running.
    # end
end

##### Model termination

# terminate(block::AbstractBlock) = drive(block, NaN)
function terminate(model::Model)
    isempty(model.taskmanager.pairs) || foreach(terminate, model.blocks)
    isrunning(model.clk) && unset!(model.clk)
    # isrunning(model.clk) && turnoff(model.clk)
    return
end


function _simulate!(sim::Simulation, reportsim::Bool)
    model = sim.model
    try
        @siminfo "Started simulation..."
        sim.state = :running

        @siminfo "Inspecting model..."
        inspect(model)
        @siminfo "Done."

        @siminfo "Initializing the model..."
        initialize(model)
        @siminfo "Done..."

        @siminfo "Running the simulation..."
        run(model)
        sim.state = :done
        sim.retcode = :success
        @siminfo "Done..."
    catch e
        sim.state = :halted
        sim.retcode = :fail
        @info e
    end

    @siminfo "Terminating the simulation..."
    terminate(model)
    @siminfo "Done."

    reportsim && report(sim)

    return sim
end

function simulate(model::Model;  simdir::String="/tmp", logtofile::Bool=false, reportsim::Bool=false)
    sim = Simulation(model, simdir)
    if logtofile
        sim.logger = setlogger(sim.path, "log.txt", setglobal=false)
        with_logger(sim.logger) do
            _simulate!(sim, reportsim)
        end
        flush(sim.logger.stream)  # Close logger file stream.
    else
        _simulate!(sim, reportsim)
    end
    return sim
end

function simulate(model::Model, t0::Real, dt::Real, tf::Real; kwargs...)
    set!(model.clk, t0, dt, tf)
    simulate(model; kwargs...)
end

