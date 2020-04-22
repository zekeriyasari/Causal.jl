# This file includes the testset for pins

@testset "PinTestSet" begin

    # Construction of Outpin
    op = Outpin()
    @test isa(op.links, AbstractVector)
    @test isempty(op.links)
    @test !isbound(op)

    # Construction of Inpin
    ip = Inpin()
    @test_throws UndefRefError ip.link
    @test !isbound(ip)

    # Connection of pins
    op, ip = Outpin(), Inpin()
    l = connect(op, ip)
    @test isa(l, Link)
    @test isbound(op)
    @test isbound(ip)
    @test l.masterid == op.id
    @test l.slaveid == ip.id
    @test isconnected(op, ip)
    op2, ip2 = Outpin(), Inpin()
    @test_throws Exception connect(op, op2)  # Outpin cannot be connected to Inpin
    @test_throws Exception connect(ip, ip2)  # Inpin cannot be connected to Inpin
    @test_throws Exception connect(ip, op)   # Inpin cannot be connected to Outpin

    # Connection of multiple Inpins to an Outpin
    op = Outpin()
    ips = [Inpin() for i in 1 : 5]
    ls = map(ip -> connect(op, ip), ips)
    for (l, ip) in zip(ls, ips)
        @test l.masterid == op.id
        @test l.slaveid == ip.id
    end

    # Data transfer through pins
    op, ip = Outpin(), Inpin()
    @test_throws MethodError take!(op)  # Data cannot be read from Outpin
    @test_throws MethodError put!(ip, 1.)  # Data cannot be written into Inpin
    l = connect(op, ip)
    t = @async while true
        take!(ip) === NaN && break  # Take from ip
    end
    for val in 1 : 5
        put!(op, val)   # Write into op.
        @test !istaskdone(t)
        @test read(l.buffer) == val
    end
    put!(op, NaN)
    @test istaskdone(t)

    # Disconnection of Outpin and Inpin
    op, ip = Outpin(), Inpin()
    l = connect(op, ip)
    @test isconnected(op, ip)
    disconnect(op, ip)
    @test !isconnected(op, ip)

end  # testset
