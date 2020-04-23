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
    @test typeof(gen.trigger) == Inpin{Float64} 
    @test typeof(gen.handshake) == Outpin{Bool} 
    @test !hasfield(typeof(gen), :input)
    @test typeof(gen.output) == Outport{Outpin{Float64}}

    gen = FunctionGenerator(t -> [sin(t), cos(t)])
    @test length(gen.output) == 2

    # Driving FunctionGenerator
    gen = FunctionGenerator(t -> t)
    trg = Outpin()
    hnd = Inpin{Bool}()
    ip = Inport()
    connect(gen.output, ip)
    connect(trg, gen.trigger)
    connect(gen.handshake, hnd)
    task = launch(gen)
    task2 = @async while true 
        all(take!(ip) .=== NaN) && break 
    end
    for t in 1. : 10.
        put!(trg, t)
        take!(hnd)
    end
    @test content(ip[1].link.buffer) == collect(1:10)
    @test !istaskdone(task)
    put!(trg, NaN)
    @test istaskdone(task)
    put!(gen.output, [NaN])
    @test istaskdone(task2)

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