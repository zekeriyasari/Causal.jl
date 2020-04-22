# # This file includes the test set for ports

@testset "BussesTestSet" begin

    # Constructiokn of Outport and Inport
    op = Outport(5)
    @test length(op.pins) == 5
    @test all(.!isbound.(op))
    @test eltype(op) == Outpin{Float64}
    op = Outport{Int}(5)
    @test eltype(op) == Outpin{Int}
    op = Outport()
    @test length(op.pins) == 1

    # Construction of Inport
    ip = Inport(3)
    @test length(ip.pins) == 3
    @test all(.!isbound.(ip))
    @test eltype(ip) == Inpin{Float64}
    ip = Inport{Bool}(4)
    @test eltype(ip) == Inpin{Bool}
    ip = Inport()
    @test length(ip.pins) == 1

    # Connection of Outport and Inport
    op, ip = Outport(3), Inport(3)
    ls = connect(op, ip)
    @test typeof(ls) <: Vector{<:Link}
    @test length(ls) == 3
    for (l, _op, _ip) in zip(ls, op, ip)
        @test l.masterid == _op.id
        @test l.slaveid == _ip.id
    end
    @test isconnected(op, ip)

    # Partial connection of Outport and Inport
    op = Outport(5)
    ip1, ip2 = Inport(3), Inport(2)
    @test_throws DimensionMismatch connect(op, ip1) # Length of op and ip1 are not same
    ls1 = connect(op[1:3], ip1)
    ls2 = connect(op[4:5], ip2)
    @test isconnected(op[1], ip1[1])
    @test isconnected(op[4], ip2[1])
    @test !isconnected(op[3], ip2[1])

    # Data transfer through ports.
    op, ip = Outport(2), Inport(2)
    @test_throws MethodError take!(op)
    @test_throws MethodError put!(ip, zeros(2))
    ls = connect(op, ip)
    t = @async while true
        all(take!(ip) .=== NaN) && break
    end
    for val in 1 : 5
        put!(op, ones(2) * val)
        @test !istaskfailed(t)
    end
    put!(op, [NaN, NaN])
    @test istaskdone(t)

    # Disconnection of data port
    op, ip = Outport(), Inport()
    ls = connect(op, ip)
    @test isconnected(op, ip)
    disconnect(op, ip)
    @test !isconnected(op, ip)

end  # testset
