# # This file includes testset for SubSystem 

# @testset "SubSystemTestSet" begin 
#     @info "Running SubSystemTestSet ..."

#     # Subsystem construction 
#     adder = Adder((+,+))
#     gain = Gain()
#     gen = ConstantGenerator()
#     subsys = SubSystem([adder, gen, gain], nothing, gain.output)  # Input nothing, output bus.
#     @test subsys.input === nothing
#     @test all(subsys.output .=== gain.output)
#     subsys = SubSystem([adder, gen, gain], adder.input, nothing)  # Input vector of links, output bus.
#     @test all(subsys.input .=== adder.input)
#     @test subsys.output === nothing
#     subsys = SubSystem([adder, gen, gain], adder.input[1, :], gain.output)  # Input vector of links, output bus.
#     @test subsys.input[1] === adder.input[1]
#     @test all(subsys.output .=== gain.output)
#     subsys = SubSystem([adder, gain], adder.input, gain.output)  # Input bus, output bus
#     @test all(subsys.input .=== adder.input)
#     @test all(subsys.output .=== gain.output)
    
#     # Drive SubSystem
#     adder = Adder((+,+))
#     gain = Gain()
#     gen = ConstantGenerator()
#     subsys = SubSystem([adder, gen, gain], adder.input[2,:], gain.output)
#     @test typeof(subsys.trigger) == Inpin{Float64}
#     @test typeof(subsys.handshake) == Outpin{Bool}
#     @test length(subsys.input) == 1
#     @test length(subsys.output) == 1
#     connect!(gen.output, adder.input[1])
#     connect!(adder.output, gain.input)
#     oport, iport, trg, hnd, tsk, tsk2 = prepare(subsys)
#     # comptsk = ComponentTask.(launch(subsys))
#     put!(trg, 1.)
#     u = [5.]
#     put!(oport, u)
#     take!(hnd)
#     @test read(iport[1].link.buffer) == (5 + 1) * 1
#     put!(trg, NaN)
#     sleep(0.1)
#     @test all(istaskdone.(tsk))

#     @info "Done SubSystemTestSet."
# end # testset 