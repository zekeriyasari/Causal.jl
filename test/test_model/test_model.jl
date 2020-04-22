# # This file includes testset for Model 

# @testset "ModelTestSet" begin 
#     # Model construction
#     model = Model(SinewaveGenerator(), Writer(Bus()))
#     @test length(model.blocks) == 2
#     model = Model() 
#     @test isempty(model.blocks) 
#     @test model.clk.t === NaN 
#     @test model.clk.dt === NaN 
#     @test model.clk.tf === NaN 
#     @test isempty(model.taskmanager.pairs)
#     gen = SinewaveGenerator()
#     writer = Writer(Bus())
#     adder = Adder(Bus(2))
#     addcomponent(model, gen)
#     @test model.blocks == [gen]
#     addcomponent(model, writer, adder)
#     @test model.blocks == [gen, writer, adder]

#     # Initializing Model 
#     gen = FunctionGenerator(sin)
#     writer = Writer(Bus())
#     connect(gen.output, writer.input)
#     model = Model(gen, writer) 
#     initialize(model)
#     @test !isempty(model.taskmanager.pairs)
#     @test checktaskmanager(model.taskmanager) === nothing
#     @test length(model.taskmanager.pairs) == 2
#     @test gen in keys(model.taskmanager.pairs)
#     @test writer in keys(model.taskmanager.pairs)

#     # Running Model 
#     ti, dt, tf =  0., 0.01, 10.
#     set!(model.clk, ti, dt, tf)
#     run(model)
#     @test isoutoftime(model.clk)
#     @test isapprox(read(gen.output[1].buffer), sin(tf))
#     @test read(writer.timebuf) == tf

#     # Releasing Model 
#     @test isconnected(gen.output, writer.input)
#     release(model)
#     @test !isconnected(gen.output, writer.input)

#     # Terminating Model 
#     @test !any(istaskdone.(values(model.taskmanager.pairs)))
#     terminate(model)
#     @test all(istaskdone.(values(model.taskmanager.pairs)))

#     # Simulating Model 
#     gen = FunctionGenerator(t -> [sin(t), cos(t)])
#     adder = Adder(Bus(2))
#     writer = Writer(Bus())
#     connect(gen.output, adder.input)
#     connect(adder.output, writer.input)
#     model = Model(gen, adder, writer)
#     sim = simulate(model, ti, dt, tf)
#     @test typeof(sim) <: Simulation 
#     @test sim.model === model
#     @test sim.retcode == :success
#     @test sim.state == :done
#     @test isoutoftime(model.clk)
#     @test all(istaskdone.(values(model.taskmanager.pairs)))

#     # Searching in Model 
#     for block in model.blocks 
#         @test findin(model, block.id) === block 
#     end
# end # testset