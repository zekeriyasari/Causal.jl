# This file includes the testset for links

@testset "LinkTestSet" begin

    # Link construction.
    l = Link(5)
    @test eltype(l) == Float64
    @test eltype(l.channel) == Float64
    @test l.channel.sz_max == 0
    @test length(l.buffer) == 5
    @test mode(l.buffer) == Cyclic
    @test !iswritable(l)
    @test !isreadable(l)

    # More on Buffer construction
    l = Link{Int}(5)
    @test size(l.buffer) == (5,)
    @test eltype(l) == Int
    l = Link{Bool}()
    @test size(l.buffer) == (64,)
    l = Link()
    @test eltype(l) == Float64
    @test size(l.buffer) == (64,)

    # Putting values to link
    l = Link()
    t = @async while true
        take!(l) === NaN && break
    end
    vals = collect(1:5)
    for i = 1 : length(vals)
        put!(l, vals[i])
        @test l.buffer[1] == vals[i]
    end
    close(l)
    @test istaskdone(t)
    @test !isopen(l.channel)

    # Taking values from the link
    l = Link()
    vals = collect(1 : 10)
    t = launch(l, vals)
    val = take!(l)
    @test val == 1.
    for i = 2 : 10
        @test take!(l) == vals[i]
    end
    close(l)
    wait(t)
    @test istaskdone(t)

    ### NOTE: Connection of links is deprecated in favor of connection of pins.
    ### See the connection of pins.

    # Connetion of links
    # l1 = Link()
    # l2 = Link()
    # @test !isconnected(l1, l2)
    # connect(l1, l2)
    # @test isconnected(l1, l2)
    # @test isconnected(l2, l1)
    # disconnect(l1, l2)
    # @test !isconnected(l1, l2)
    # @test !isconnected(l2, l1)

    ### NOTE: Driving of links by links is deprecated in favor of driving of pins
    ### bu pins.

    # # Driving links
    # l1 = Link()
    # l2 = Link()
    # t1 = @async while true
    #     take!(l1) === NaN && break
    # end
    # t2 = @async while true
    #     take!(l2) === NaN && break
    # end
    # connect(l1, l2)
    # val = 1.
    # put!(l1, val)  # Since l1 drives l2, any values put into l1 is written into l2.
    # @test l1.buffer[1] == val
    # @test l2.buffer[1] == val
    # disconnect(l1, l2)
    # put!(l1, 2*val)  # Since l1 and l2 is disconnected, l1 does not drive l2.
    # @test l1.buffer.index == 3
    # @test l2.buffer.index == 2  # Note that since disconnected, l1 does not write `2*val` is not put into l2.

end  # testset
