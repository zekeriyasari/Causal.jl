# This file includes the testset for pins

@testset "PinTestSet" begin
    @info "Running PinTestSet ..."

    # Construction of Outpin
    op = Outpin()
    @test isa(op.links, Missing)
    @test !isbound(op)

    # Construction of Inpin
    ip = Inpin()
    @test !isbound(ip)

    # Connection of pins
    op, ip = Outpin(), Inpin()
    l = connect!(op, ip)
    @test isa(l, Link)
    @test isbound(op)
    @test isbound(ip)
    @test l.masterid == op.id
    @test l.slaveid == ip.id
    @test isconnected(op, ip)
    op2, ip2 = Outpin(), Inpin()
    @test_throws Exception connect!(op, op2)  # Outpin cannot be connected to Inpin
    @test_throws Exception connect!(ip, ip2)  # Inpin cannot be connected to Inpin
    @test_throws Exception connect!(ip, op)   # Inpin cannot be connected to Outpin

    op1 = Outpin() 
    op2 = Outpin() 
    ip = Inpin()
    @test_throws MethodError connect!(ip, op1)  # Inpin cannot drive and Outpin 
    @test_throws MethodError connect!(op1, op2) # Outpoin cannot drive and Outpin 
    @test !isbound(op1) 
    @test !isbound(op2) 
    @test !isbound(ip) 
    l = connect!(op1, ip)   # Outpin can drive Inpin 
    @test isbound(op1) 
    @test isbound(ip) 
    @test_throws ErrorException connect!(op1, ip)   # Reconnection is not possible 
    @test_throws ErrorException connect!(op2, ip)   # `ip` is bound. No new connections are allowed. 
    @test isconnected(op1, ip)
    disconnect!(op1, ip)
    @test !isconnected(op1, ip)
    l = connect!(op2, ip)
    @test isconnected(op2, ip)

    
    @test isbound(ip)
    # Connection of multiple Inpins to an Outpin
    op = Outpin()
    ips = [Inpin() for i in 1 : 5]
    ls = map(ip -> connect!(op, ip), ips)
    for (l, ip) in zip(ls, ips)
        @test l.masterid == op.id
        @test l.slaveid == ip.id
    end

    # Data transfer through pins
    op, ip = Outpin(), Inpin()
    @test_throws MethodError take!(op)  # Data cannot be read from Outpin
    @test_throws MethodError put!(ip, 1.)  # Data cannot be written into Inpin
    l = connect!(op, ip)
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
    l = connect!(op, ip)
    @test isconnected(op, ip)
    disconnect!(op, ip)
    @test !isconnected(op, ip)

    @info "Done PinTestSet."
end  # testset
