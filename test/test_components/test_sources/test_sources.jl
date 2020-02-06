# This file includes testset for sources.

@testset "ClockTestSet" begin 
    # Clock construction 
    clk1 = Clock(0., 1., 10.)
    clk2 = Clock(0., 1, 10)
    clk3 = Clock(0, 1, 10)
    @test eltype(clk1.t) == Float64
    @test eltype(clk2.t) == Float64
    @test eltype(clk3.t) == Int

    # Check Clock defaults.
    clk = clk1
    @test clk.t == 0.
    @test clk.dt == 1.
    @test clk.tf == 10.
    @test typeof(clk.generator) == Channel{Float64}
    @test clk.generator.sz_max == 0
    @test !ispaused(clk) 
    @test !isrunning(clk)

    # Set Clock
    set!(clk)
    @test isrunning(clk)

    # Taking values from clk 
    clk = Clock(0., 1., 10.)
    set!(clk)
    @test [take!(clk) for i in 0 : 10] == collect(Float64, 0:10)
    @test isoutoftime(clk)

    # Pausing Clock 
    clk = set!(Clock(0., 1, 10))
    @test take!(clk) == 0
    @test take!(clk) == 1.
    pause!(clk)
    for i = 1 : 10
        @test take!(clk) == 1.
    end
end  # testset


@testset "GeneratorsTestSet" begin 
    # FunctionGenerator construction
    gen = FunctionGenerator(sin)
    @test typeof(gen.trigger) == Link{Float64} 
    @test typeof(gen.handshake) == Link{Bool} 
    @test !hasfield(typeof(gen), :input)
    @test typeof(gen.output) == Bus{Link{Float64}}

    gen = FunctionGenerator(t -> [sin(t), cos(t)])
    @test length(gen.output) == 2

    # Driving FunctionGenerator
    gen = FunctionGenerator(t -> t)
    task = launch(gen)
    for t in 1. : 10.
        drive(gen, t)
        approve(gen)
        @test read(gen.output[1].buffer) == t
    end
    @task !istaskdone(task)
    terminate(gen)
    @task istaskdone(task)

    # Construction of other generators 
    sinegen = SinewaveGenerator()
    dampedsinegen = DampedSinewaveGenerator()
    sqauregen = SquarewaveGenerator()
    trigen = TriangularwaveGenerator()
    congen = ConstantGenerator()
    rampgen = RampGenerator()
    stepgen = StepGenerator()
    expgen = ExponentialGenerator()
    dampedexpgen = DampedExponentialGenerator()

    # Mutaton of generators 
    sinegen.amplitude = 5.
    sqauregen.high = 10.
end  # testset