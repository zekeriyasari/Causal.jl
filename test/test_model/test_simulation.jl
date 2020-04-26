# This file includes testset for Simulation 

@testset "SimulationTestSet" begin 
    @info "Running SimulationTestSet ..."

    # Simulation construction 
    model = Model()
    simname = string(uuid4())
    simdir = tempdir()
    sim = Simulation(model, simdir=simdir, simname=simname, logger=SimpleLogger())
    @test sim.model === model
    @test startswith(basename(sim.path), "Simulation-")
    @test sim.path == joinpath(simdir, "Simulation-" * simname)
    @test sim.state == :idle 
    @test sim.retcode == :unknown
    @test sim.name == "Simulation-" * simname

    # Check Writer files 
    model = Model()
    addnode(model, SinewaveGenerator(), label=:gen)
    addnode(model, Writer(Inport()), label=:writer)
    addbranch(model, :gen => :writer)
    dname1 = dirname(getnode(model, :writer).component.file.path)
    simname = string(uuid4())
    simdir = tempdir()
    sim = Simulation(model, simdir=simdir, simname=simname)
    @test dirname(getnode(model, :writer).component.file.path) == sim.path
    @test dname1 != sim.path

    # Report Simulation 
    sim = simulate(model, 0., 0.01, 10.)
    report(sim)
    filename = joinpath(sim.path, "report.jld2")
    @test isfile(filename)
    data = load(filename)
    @test data["name"] == sim.name
    @test data["path"] == sim.path
    @test data["state"] == sim.state
    @test data["retcode"] == sim.retcode
    
    @info "Done SimulationTestSet."
end # testset