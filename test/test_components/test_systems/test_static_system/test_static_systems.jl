# This file includes testset for StaticSystems

@testset "StaticSystems" begin
    @info "Running StaticSystemTestSet ..."

    # StaticSystem construction
    @def_static_system struct Mysystem{IP, OP, RO} <: AbstractStaticSystem 
        input::IP = Inport(2)
        output::OP = Outport(3)
        readout::RO = (u, t) -> [u[1] + u[2], u[1] - u[2], u[1] * u[2]]
    end
    # ofunc(u, t) = [u[1] + u[2], u[1] - u[2], u[1] * u[2]]
    ss = Mysystem()
    @test isimmutable(ss)
    @test length(ss.input) == 2
    @test length(ss.output) == 3
    @test typeof(ss.input) == Inport{Inpin{Float64}}
    @test typeof(ss.output) == Outport{Outpin{Float64}}
    @test typeof(ss.trigger) == Inpin{Float64}
    @test typeof(ss.handshake) == Outpin{Bool}
    
    # ofunc2(u, t) = nothing
    ss = Mysystem(readout=nothing, input=nothing, output=nothing)  # Input or output may be nothing
    @test ss.input === nothing
    @test ss.output === nothing

    # Driving of StaticSystem
    ofunc3(u, t) = u[1] + u[2] 
    ss = Mysystem(readout = ofunc3, input=Inport(2), output=Outport(1))
    iport, oport, ipin, opin = Inport(1), Outport(2), Inpin{Bool}(), Outpin()
    connect!(oport, ss.input)
    connect!(ss.output, iport)
    connect!(opin, ss.trigger)
    connect!(ss.handshake, ipin)
    tsk = launch(ss)
    tsk2 = @async while true 
        all(take!(iport) .=== NaN) && break 
    end
    for t in 1. : 10.
        put!(opin, t)
        put!(oport, [t, t])
        take!(ipin)
    end
    @test content(iport[1].link.buffer) == collect(1 : 10) * 2
    @test !istaskdone(tsk)
    put!(opin, NaN)
    sleep(0.1)
    @test istaskdone(tsk)
    put!(ss.output, [NaN])
    sleep(0.1) 
    @test istaskdone(tsk2)

    # Adder tests
    ss = Adder()
    @test isimmutable(ss)
    @test ss.signs == (+, +)
    @test length(ss.output) == 1

    ss = Adder(signs=(+, +, -))
    @test ss.signs == (+, +, -)
    oport, iport, opin, ipin = Outport(3), Inport(1), Outpin(), Inpin{Bool}()
    connect!(opin, ss.trigger)
    connect!(oport, ss.input)
    connect!(ss.handshake, ipin)
    connect!(ss.output, iport)
    tsk = launch(ss)
    tsk2 = @async while true 
        all(take!(iport) .=== NaN) && break 
    end
    put!(opin, 1.)
    put!(oport, [1, 3, 5])
    take!(ipin)
    @test read(iport[1].link.buffer) == 1 + 3 - 5
    put!(opin, NaN)
    sleep(0.1)
    @test istaskdone(tsk)
    put!(ss.output, [NaN])
    sleep(0.1)
    @test istaskdone(tsk2)

    # Multiplier tests
    ss = Multiplier(ops=(*, *))
    @test isimmutable(ss)
    @test ss.ops == (*, *)
    @test length(ss.output) == 1

    ss = Multiplier(ops=(*, *, /,*))
    @test ss.ops == (*, *, /, *)
    oport, iport, opin, ipin = Outport(4), Inport(1), Outpin(), Inpin{Bool}()
    connect!(opin, ss.trigger)
    connect!(oport, ss.input)
    connect!(ss.handshake, ipin)
    connect!(ss.output, iport)
    tsk = launch(ss)
    tsk2 = @async while true 
        all(take!(iport) .=== NaN) && break 
    end
    put!(opin, 1.)
    put!(oport, [1, 3, 5, 6])
    take!(ipin)
    @test read(iport[1].link.buffer) == 1 * 3 / 5 * 6
    put!(opin, NaN)
    sleep(0.1)
    @test istaskdone(tsk)
    put!(ss.output, [NaN])
    sleep(0.1) 
    @test istaskdone(tsk2)

    # Gain tests 
    ss = Gain(input=Inport(3))
    @test isimmutable(ss)
    @test ss.gain == 1.
    @test length(ss.output) == 3
    K = rand(3, 3)
    ss = Gain(input=Inport(3), gain=K)
    oport, iport, opin, ipin = Outport(3), Inport(3), Outpin(), Inpin{Bool}()
    connect!(oport, ss.input)
    connect!(opin, ss.trigger)
    connect!(ss.handshake, ipin)
    connect!(ss.output, iport)
    tsk = launch(ss)
    tsk2 = @async while true 
        all(take!(iport) .=== NaN) && break 
    end
    u = rand(3)
    put!(opin, 1.)
    put!(oport, u)
    take!(ipin)
    @test [read(pin.link.buffer) for pin in iport] == K * u
    put!(opin, NaN)
    sleep(0.1)
    @test istaskdone(tsk)
    put!(ss.output, NaN * ones(3))
    sleep(0.1)
    @test istaskdone(tsk2)

    # Terminator tests 
    ss = Terminator(input=Inport(3))
    @test isimmutable(ss)
    @test ss.readout === nothing
    @test ss.output === nothing
    @test typeof(ss.trigger) == Inpin{Float64}
    @test typeof(ss.handshake) == Outpin{Bool}
    oport, opin, ipin = Outport(3), Outpin(), Inpin{Bool}()
    connect!(oport, ss.input)
    connect!(opin, ss.trigger)
    connect!(ss.handshake, ipin)
    tsk = launch(ss)
    put!(opin, 1.)
    put!(oport, [1., 2., 3.])
    take!(ipin)
    @test [read(pin.link.buffer) for pin in ss.input] == [1., 2., 3.]
    put!(opin, NaN)
    sleep(0.1)
    @test istaskdone(tsk)

    # Memory tests
    ss = Memory(delay=1., numtaps=10, initial=zeros(3))
    @test isimmutable(ss)
    @test size(ss.databuf) == (3, 10)
    @test size(ss.timebuf) == (10,)
    @test mode(ss.databuf) == Cyclic
    @test mode(ss.timebuf) == Cyclic
    @test typeof(ss.trigger) == Inpin{Float64}
    @test typeof(ss.handshake) == Outpin{Bool}
    @test typeof(ss.input) == Inport{Inpin{Float64}}
    @test typeof(ss.output) == Outport{Outpin{Float64}}
    @test outbuf(ss.databuf) == zeros(3, 10)
    oport, iport, opin, ipin = Outport(3), Inport(3), Outpin(), Inpin{Bool}()
    connect!(oport, ss.input)
    connect!(opin, ss.trigger)
    connect!(ss.handshake, ipin)
    connect!(ss.output, iport)
    tsk = launch(ss)
    tsk2 = @async while true 
        all(take!(iport) .=== NaN) && break 
    end
    put!(opin, 1.)
    put!(oport, [10, 20, 30])
    take!(ipin)
    @test [read(pin.link.buffer) for pin in iport] == zeros(3)
    @test ss.databuf[:, 1] == [10, 20, 30]
    put!(opin, NaN)
    sleep(0.1)
    @test istaskdone(tsk)
    put!(ss.output, NaN * ones(3))
    sleep(0.1)
    @test istaskdone(tsk2)

    # Coupler test
    conmat =  [-1 1; 1 -1]
    cplmat = [1 0 0; 0 0 0; 0 0 0]
    ss = Coupler(conmat=conmat, cplmat=cplmat)
    @test isimmutable(ss)
    @test typeof(ss.trigger) == Inpin{Float64}
    @test typeof(ss.handshake) == Outpin{Bool}
    @test typeof(ss.input) == Inport{Inpin{Float64}}
    @test typeof(ss.output) == Outport{Outpin{Float64}}
    @test length(ss.input) == 6
    @test length(ss.output) == 6 
    oport, iport, opin, ipin = Outport(6), Inport(6), Outpin(), Inpin{Bool}()
    connect!(oport, ss.input)
    connect!(opin, ss.trigger)
    connect!(ss.handshake, ipin)
    connect!(ss.output, iport)
    tsk = launch(ss)
    tsk2 = @async while true 
        all(take!(iport) .=== NaN) && break 
    end
    put!(opin, 1.)
    u = rand(6)
    put!(oport, u)
    take!(ipin)
    @test [read(pin.link.buffer) for pin in iport] == kron(conmat, cplmat) * u
    put!(opin, NaN)
    sleep(0.1)
    @test istaskdone(tsk)
    put!(ss.output, NaN * ones(6))
    sleep(0.1)
    @test istaskdone(tsk2)

    # Test defining new statik systems 
    # The type must be a subtype of AbstractStaticSystem
    @test_throws Exception @eval @def_static_system struct MyStaticSystem{RO, OP} 
        reaout::RO = (u, t) -> u 
        output::OP = Outport()
    end 

    # The type must be a subtype of AbstractStaticSystem
    @test_throws Exception @eval @def_static_system struct MyStaticSystem{RO, OP} <: MyDummyAbstractStaticSystem
        reaout::RO = (u, t) -> u 
        output::OP = Outport()
    end 

    @info "Done StaticSystemTestSet ..."
end # testset