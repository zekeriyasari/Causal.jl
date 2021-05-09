# This file includes testset for sources.

@testset "ClockTestSet" begin 
    @info "Running ClockTestSet ..."

    # Clock construction 
    Clock(0 : 1) 
    Clock(0. : 2. : 10.) 
    Clock(sort(rand(10)))
    Clock(
        Channel(0) do ch 
            for t in 1 : 10 
                put!(ch, t)
            end 
        end 
    )
    Clock(0, 2, 10)

    # Check Clock defaults.
    clk = Clock(0. : 5.)
    vals = Float64[]
    for val in clk 
        push!(vals, val) 
    end
    @test vals == collect(0. : 5.)

    # Pausing Clock 
    clk = Clock(0 : 1 : 10)
    item, state = iterate(clk) 
    @test (item, state) == (0, 0) 
    item, state = iterate(clk, state) 
    @test (item, state) == (1, 1) 
    pause!(clk) 
    iter = iterate(clk)
    @test iter === nothing

    @info "Done ClockTestSet."
end  # testset


@testset "GeneratorsTestSet" begin 
    @info "Running GeneratorsTestSet ..."
    # FunctionGenerator construction
    gen = SinewaveGenerator()
    @test typeof(gen.trigger) == Inpin{Float64} 
    @test typeof(gen.handshake) == Outpin{Bool} 
    @test !hasfield(typeof(gen), :input)
    @test typeof(gen.output) == Outport{Outpin{Float64}}

    @def_source struct  Mygen{OP, RO} <: AbstractSource 
        output::OP = Outport(2) 
        readout::RO = t -> [sin(t), cos(t)]
    end
    gen = Mygen()
    @test length(gen.output) == 2

    # Driving FunctionGenerator
    gen = Mygen(readout = t -> t, output=Outport(1))
    trg = Outpin()
    hnd = Inpin{Bool}()
    ip = Inport()
    connect!(gen.output, ip)
    connect!(trg, gen.trigger)
    connect!(gen.handshake, hnd)
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
    @test_throws Exception sinegen.amplitude = 5.
    @test_throws Exception sqauregen.high = 10.

    # Test redefining new source types. 
    @test_throws Exception @eval @def_source struct Mygen{RO,OP} 
        readout::RO = t -> sin(t) 
        output::OP = Outport()
    end

    @test_throws Exception @eval @def_source struct Mygen{RO,OP} <: SomeDummyType
        readout::RO = t -> sin(t) 
        output::OP = Outport()
    end

    @info "Done GeneratorsTestSet ..."
end  # testset
