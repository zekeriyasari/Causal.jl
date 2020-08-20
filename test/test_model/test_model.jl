# This file includes testset for Model 

@testset "ModelTestSet" begin 
    @info "Running ModelTestSet ..."

    # Model construction
    model = Model()
    @test isempty(model.nodes)
    @test isempty(model.branches)
    @test isempty(model.taskmanager.pairs)
    @test model.clock.t == 0.
    @test model.clock.dt == 0.01
    @test model.clock.tf == 1.
    @test typeof(model.graph) <: SimpleDiGraph
    @test nv(model.graph) == 0
    @test ne(model.graph) == 0

    # Adding nodes to model 
    model = Model()
    comps = [SinewaveGenerator(), Gain(), Gain(), Writer()]
    for (k,comp) in enumerate(comps)
        node = addnode!(model, comp)
        @test node.component === comp 
        @test node.idx == k 
        @test node.label === nothing 
        @test length(model.nodes) == k 
        @test nv(model.graph) == k 
        @test ne(model.graph) == 0
    end
    n = length(model.nodes)
    singen = FunctionGenerator(readout=sin)
    newnode = addnode!(model, singen, label=:gen)
    @test newnode.idx == n + 1
    @test newnode.label == :gen
    rampgen = RampGenerator()
    @test_throws Exception addnode!(model, rampgen, label=:gen)

    # Accessing nodes in model 
    node = getnode(model, 1)
    @test node.idx == 1
    @test node.label == nothing
    @test node.component == comps[1]
    node = getnode(model, :gen)
    @test node.idx == 5
    @test node.label == :gen
    @test node.component == singen

    # Adding branches to model 
    model = Model() 
    @test_throws BoundsError addbranch!(model, 1 => 2)
    @test_throws MethodError addbranch!(model, 1, 2)
    for (comp, label) in zip(
            [FunctionGenerator(readout=t -> [sin(t), cos(t)], output=Outport(2)), Gain(input=Inport(2)), Gain(input=Inport(3)), Writer(input=Inport(3))],
            [:gen, :gain1, :gain2, :writer]
        )
        addnode!(model, comp, label=label)
    end
    branch = addbranch!(model, :gen => :gain1)
    @test branch.nodepair == (1 => 2)
    @test branch.indexpair == ((:) => (:))
    @test typeof(branch.links) <: Vector{<:Link}
    @test length(branch.links) == 2
    @test length(model.branches) == 1
    @test ne(model.graph) == 1
    @test collect(edges(model.graph)) == [Edge(1, 2)]
    branch2 = addbranch!(model, 2 => 3, 1 => 1)
    @test branch2.nodepair == (2 => 3)
    @test branch2.indexpair == (1 => 1)
    @test typeof(branch2.links) <: Vector{<:Link}
    @test length(model.branches) == 2 
    @test ne(model.graph) == 2 
    branch3 = addbranch!(model, 3 => :writer, 1:2 => 2:3)
    @test length(model.branches) == 3
    @test ne(model.graph) == 3
    
    # Accessing branches 
    br = getbranch(model, 1 => 2)
    @test br === branch 
    br2 = getbranch(model, :gain1 => :gain2)
    @test br2 === branch2
    @test_throws MethodError getbranch(model, 3 => :writer)

    # Deleting branches
    n = length(model.nodes)
    br = deletebranch!(model, 1 => 2)
    @test br === branch
    @test branch ∉ model.branches
    @test Edge(1, 2) ∉ edges(model.graph)
    @test length(model.nodes) == n
    @test !isconnected(
        getnode(model, br.nodepair.first).component.output[br.indexpair.first],
        getnode(model, br.nodepair.second).component.input[br.indexpair.second]
        )

    # Investigation of algebrraic loops 
    function contruct_model_with_loops()
        model = Model() 
        for (comp, label) in zip(
            [SinewaveGenerator(), Adder(signs=(+, +, +)), Gain(), Writer()],
            [:gen, :adder, :gain, :writer]
            )
            addnode!(model, comp, label=label)
        end
        addbranch!(model, :gen => :adder, 1 => 1)
        addbranch!(model, :adder => :gain, 1 => 1)
        addbranch!(model, :gain => :adder, 1 => 2)
        addbranch!(model, :adder => :adder, 1 => 3)
        addbranch!(model, :gain => :writer, 1 => 1)
        model 
    end
    model = contruct_model_with_loops()
    loops = getloops(model)
    @test length(loops) == 2
    @test [2] ∈ loops
    @test [2, 3] ∈ loops

    # Breaking algebrraic loops 
    loop = filter(loop -> loop == [2], loops)[1]
    loopcomp = getnode(model, :adder).component
    @test isconnected(loopcomp.output[1], loopcomp.input[3])
    nn = length(model.nodes)
    nb = length(model.branches)
    breakernode = breakloop!(model, loop)
    @test typeof(breakernode.component) <: Jusdl.LoopBreaker
    @test breakernode.idx == nn + 1
    @test breakernode.label === nothing
    @test !isconnected(loopcomp.output[1], loopcomp.input[3])
    @test length(model.nodes) == nn + 1
    @test length(model.branches) == nb
    loops = getloops(model)
    @test length(loops) == 1 
    @test loops[1] == [2, 3]
    nn = length(model.nodes)
    nb = length(model.branches)
    comp1 = getnode(model, 2).component
    comp2 = getnode(model, 3).component
    @test isconnected(comp2.output[1], comp1.input[2])
    newbreakernode = breakloop!(model, loops[1])
    @test typeof(newbreakernode.component) <: Jusdl.LoopBreaker
    @test !isconnected(comp2.output[1], comp1.input[2])

    # Initializing Model 
    model = Model()
    addnode!(model, SinewaveGenerator())
    addnode!(model, Writer())
    addbranch!(model, 1 => 2)
    Jusdl.initialize!(model)
    @test !isempty(model.taskmanager.pairs)
    @test checktaskmanager(model.taskmanager) === nothing
    @test length(model.taskmanager.pairs) == 2
    @test getnode(model, 1).component in keys(model.taskmanager.pairs)
    @test getnode(model, 2).component in keys(model.taskmanager.pairs)

    # Running Model 
    ti, dt, tf =  0., 0.01, 10.
    set!(model.clock, ti, dt, tf)
    run!(model)
    @test isoutoftime(model.clock)
    @test isapprox(read(getbranch(model, 1 => 2).links[1].buffer), sin(2 * pi * tf))
    @test read(getnode(model, 2).component.timebuf) == tf

    # Terminating Model 
    @test !any(istaskdone.(values(model.taskmanager.pairs)))
    Jusdl.terminate!(model)
    @test all(istaskdone.(values(model.taskmanager.pairs)))

    # Simulating Model
    model = Model()  
    addnode!(model, FunctionGenerator(readout=t -> [sin(t), cos(t)], output=Outport(2)), label=:gen)
    addnode!(model, Adder(), label=:adder)
    addnode!(model, Writer(), label=:writer)
    addbranch!(model, :gen => :adder)
    addbranch!(model, :adder => :writer)
    sim = simulate!(model)
    @test typeof(sim) <: Simulation 
    @test sim.model === model
    @test sim.retcode == :success
    @test sim.state == :done
    @test isoutoftime(model.clock)
    @test all(istaskdone.(values(model.taskmanager.pairs)))

    @info "Done ModelTestSet."
end # testset