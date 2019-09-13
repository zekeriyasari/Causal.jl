# This file includes the testset for links 
# TODO: Complete links testset.

@testset "LinkTestSet" begin 
    # Constuction of links.
    l = Link(5)
    @test eltype(l) == Float64
    @test eltype(l.channel) == Union{Poison, Float64}
    @test l.channel.sz_max == 0
    @test_throws UndefRefError l.master[]
    @test isempty(l.slaves)
    @test length(l.buffer) == 5
    @test mode(l.buffer) == Cyclic

    # Putting values to link
    l = Link()
    t = launch(l)
    sleep(1.)  # Wait for the task
    @test istaskstarted(t) == true
    for val in 1. : 5.
        put!(l, val)
    end
    close(l)
    sleep(1)  # Wait for the task
    @test istaskdone(t)
    @test !isopen(l.channel)

    # Taking values from the link
    l = Link()
    t = launch(l, collect(1. : 10.))
    val = take!(l)
    @test typeof(val) == Float64  
    for i = 2 : 10
        @show take!(l)
    end
    close(l)
    sleep(1)
    @test istaskdone(t)

    # Constuction of links having Vector{Float64} data
    l = Link{Vector{Float64}}(5)
    @test eltype(l) == Vector{Float64}
    @test length(l.buffer) == 5
    @test size(l.buffer) == (5,)
    @test eltype(l.buffer) == Vector{Float64}

    # Putting values to links
    t = launch(l)
    for i = 1 : 5
        put!(l, ones(3) * i)
        @show l.buffer.data 
    end
    close(l)
    sleep(1)
    @test istaskdone(t) 
    @test !isopen(l.channel)

    # Reading from links 
    l = Link{Vector{Float64}}(5)
    t = launch(l, [rand(4) * i for i = 1 : 10])
    val = take!(l)
    @test typeof(val) == Vector{Float64}
    for i = 2 : 10
        @show take!(l)
    end
    close(l)
    sleep(1)
    @test istaskdone(t)
    @test !isopen(l.channel)

    # Connetion of links 
    l1 = Link()
    l2 = Link()
    @test !isconnected(l1, l2)
    connect(l1, l2)
    @test isconnected(l1, l2)
    @test isconnected(l2, l1)
    disconnect(l1, l2)
    @test !isconnected(l1, l2)
    @test !isconnected(l2, l1)

    # Driving links 
    l1 = Link{Vector{Float64}}()
    l2 = Link{Vector{Float64}}()
    t1 = launch(l1)
    t2 = launch(l2)
    connect(l1, l2)
    val = rand(4)
    put!(l1, val)  # Since l1 drives l2, any values put into l1 is written into l2.
    @test l1.buffer[1] == val
    @test l2.buffer[1] == val
    disconnect(l1, l2)
    put!(l1, 2*val)  # Since l1 and l2 is disconnected, l1 does not drive l2.
    @test l1.buffer.index == 3
    @test l2.buffer.index == 2  # Note that since disconnected, l1 does not write `2*val` is not put into l2.
end  # testset
