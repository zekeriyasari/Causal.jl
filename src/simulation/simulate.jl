
export simulate!


macro siminfo(msg...)
    quote
        @info "$(now()) $($msg...)"
    end
end


"""
    $(SIGNATURES)

Simulates `model`. `simdir` is the path of the directory into which simulation files are saved. `simprefix` is the prefix of the simulation name `simname`. If `logtofile` is `true`, a log file for the simulation is constructed. `loglevel` determines the logging level. If `reportsim` is `true`, model components are saved into files. If `withbar` is `true`, a progress bar indicating the simualation status is displayed on the console.
"""
function simulate!(model::Model; simdir::String=tempdir(), simprefix::String="Simulation-", simname=string(uuid4()),
    logtofile::Bool=false, loglevel::LogLevel=Logging.Info, reportsim::Bool=false, withbar::Bool=true, 
    breakpoints::Vector{Int}=Int[])
    
    # Construct a Simulation
    sim = Simulation(model, simdir=simdir, simprefix=simprefix, simname=simname)
    sim.logger = logtofile ? SimpleLogger(open(joinpath(sim.path, "simlog.log"), "w+"), loglevel) : ConsoleLogger(stderr, loglevel)

    # Simualate the modoel
    with_logger(sim.logger) do
        _simulate(sim, reportsim, withbar, breakpoints)
    end
    logtofile && flush(sim.logger.stream)  # Close logger file stream.
    return sim
end

""" 
    $(SIGNATURES)

Simulates the `model` starting from the initial time `t0` until the final time `tf` with the sampling interval of `tf`. For `kwargs` are 

* `logtofile::Bool`: If `true`, a log file is contructed logging each step of the simulation. 
* `reportsim::Bool`: If `true`, `model` components are written files after the simulation. When this file is read back, the model components can be consructed back with their status at the end of the simulation.
* `simdir::String`: The path of the directory in which simulation file are recorded. 
"""
function simulate!(model::Model, t0::Real, dt::Real, tf::Real; kwargs...)
    set!(model.clock, t0, dt, tf)
    simulate!(model; kwargs...)
end

function _simulate(sim::Simulation, reportsim::Bool, withbar::Bool, breakpoints::Vector{Int})
    model = sim.model
    @siminfo "Started simulation..."
    sim.state = :running

    @siminfo "Inspecting model..."
    inspect!(model, breakpoints)
    @siminfo "Done."

    @siminfo "Initializing the model..."
    initialize!(model)
    @siminfo "Done..."

    @siminfo "Running the simulation..."
    run!(model, withbar)
    sim.state = :done
    sim.retcode = :success
    @siminfo "Done..."
    
    @siminfo "Terminating the simulation..."
    terminate!(model)
    @siminfo "Done."

    reportsim && report(sim)
    return sim
end
