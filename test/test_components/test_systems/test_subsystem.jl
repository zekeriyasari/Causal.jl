# This file includes testset for SubSystem 

@testset "SubSystemTestSet" begin 
    # Subsystem construction 
    adder = Adder(Bus(2))
    gain = Gain(Bus())
    gen = ConstantGenerator()
    subsys = SubSystem([adder, gen, gain], nothing, gain.output)  # Input nothing, output bus.
    @test subsys.input === nothing
    @test all(subsys.output .=== gain.output)
    subsys = SubSystem([adder, gen, gain], adder.input, nothing)  # Input vector of links, output bus.
    @test all(subsys.input .=== adder.input)
    @test subsys.output === nothing
    subsys = SubSystem([adder, gen, gain], adder.input[1, :], gain.output)  # Input vector of links, output bus.
    @test subsys.input[1] === adder.input[1]
    @test all(subsys.output .=== gain.output)
    subsys = SubSystem([adder, gain], adder.input, gain.output)  # Input bus, output bus
    @test all(subsys.input .=== adder.input)
    @test all(subsys.output .=== gain.output)
    
    # Drive SubSystem
    adder = Adder(Bus(2))
    gain = Gain(Bus())
    gen = ConstantGenerator()
    subsys = SubSystem([adder, gen, gain], adder.input[2,:], gain.output)
    @test typeof(subsys.trigger) == Link{Float64}
    @test typeof(subsys.handshake) == Link{Bool}
    @test length(subsys.input) == 1
    @test length(subsys.output) == 1
    connect(gen.output, adder.input[1])
    connect(adder.output, gain.input)
    comptsk = ComponentTask.(launch(subsys))
    drive(subsys, 1.)
    u = [5.]
    put!(subsys.input, u)
    approve(subsys)
    @test read(subsys.output[1].buffer) == (5 + 1) * 1
    release(subsys)  # Release components of subsys
    terminate(subsys)
    sleep(0.1)
    @test all(istaskdone.(comptsk))
end # testset 