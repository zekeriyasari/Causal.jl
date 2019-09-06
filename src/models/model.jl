# This file includes the Model object


mutable struct Model{BL<:AbstractVector, CLK, TM<:AbstractTaskManager} <: AbstractModel
    blocks::BL
    clk::CLK
    taskmanager::TM
    callbacks::Vector{Callback}
    name::String
    function Model(blocks, clk, callbacks, name)
        taskmanager = TaskManager()
        new{typeof(blocks), typeof(clk),  typeof(taskmanager)}(blocks, clk, taskmanager, callbacks, name)
    end
end
Model(blocks...; clk=Clock(0., 0.01, 10.), callbacks=Callback[], name=string(uuid4())) = 
    Model([blocks...], clk, callbacks, name)

##### Model inspection.

function adjacency_matrix(model::AbstractModel)
    blocks = model.blocks
    n = length(model.blocks) 
    mat = zeros(Int, n, n)
    for i = 1 : n 
        for j = 1 : n 
            if isconnected(blocks[i].output, block[j].input)
                mat[i, j] = 1
            end
        end
    end
    mat
end

is_terminated(output) = isa(output, Nothing) ? true : hasslaves(output)

function has_unterminated_bus(model::AbstractModel)
    any([!is_terminated(block.output) for block in model.blocks if !isa(block, AbstractSink)])
end

function terminate_securely!(model::AbstractModel)
    # TODO: Complete the function.
    nothing
end

function has_algeraic_loop(model::AbstractModel)
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

function initialize(model::AbstractModel)
    pairs = model.taskmanager.pairs
    blocks = model.blocks
    for block in blocks
        pairs[block] = launch(block)
    end
    isset(model.clk) || set!(model.clk)  # Turnon clock internal generator.
    # isset(model.clk) || turnon(model.clk)  # Turnon clock internal generator.
    for writer in filter(block->isa(block, Writer), model.blocks)  # Open writer files.
        writer.file = jldopen(writer.file.path, "a")
    end
end

##### Model running

# drive(component::AbstractComponent, t) = put!(component.clk_link, t)    
# update(memory::Memory, t) = write!(memory.buffer, memory.input(t))

function run(model::AbstractModel)
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
function terminate(model::AbstractModel)
    isempty(model.taskmanager.pairs) || foreach(terminate, model.blocks)
    isset(model.clk) && unset!(model.clk)
    # isset(model.clk) && turnoff(model.clk)
    return
end


function _simulate!(sim::Simulation, reportsim::Bool)
    model = sim.model
    try
        @siminfo "Started simulation..."
        sim.status = :running

        @siminfo "Inspecting model..."
        inspect(model)
        @siminfo "Done."

        @siminfo "Initializing the model..."
        initialize(model)
        @siminfo "Done..."

        @siminfo "Running the simulation..."
        run(model)
        sim.status = :done
        sim.retcode = :success
        @siminfo "Done..."
    catch e
        sim.status = :halted
        sim.retcode = :fail
        @info e
    end

    @siminfo "Terminating the simulation..."
    terminate(model)
    @siminfo "Done."

    reportsim && report(sim)

    return sim
end

function simulate(model::AbstractModel;  simdir::String="/tmp", logtofile::Bool=false, reportsim::Bool=false)
    sim = Simulation(model, simdir=simdir)
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

# function simulate(model::AbstractModel, t0, dt, tf; record_clk_data::Bool=true, kwargs...)
#     set!(model.clk, t0, dt, tf)
#     if record_clk_data
#         @info "Constructing a Writer with name $(`clk_data.jld2`) for the clock"
#         clk_writer = Writer(Bus(), "clk_data.jld2")
#         push!(model.clk.buffer.callbacks, BufferFullCallback(buf -> clk_writer(buf.data)))
#         push!(model.blocks, clk_writer)
#     end
#     simulate(model; kwargs...)
# end

