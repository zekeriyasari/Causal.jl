# This file includes the test set for busses.

@testset "BussesTestSet" begin

    # Bus construction 
    b = Bus(Int, 5)
    @test eltype(b) == Link{Int}
    @test length(b) == 5
    @test size(b) == (5,)
    @test isa(b, AbstractVector)  # Bus is a vector of links
    @test !isreadable(b)
    @test !iswritable(b)

    b = Bus(5)
    @test length(b) == 5
    @test eltype(b) == Link{Float64}
    
    b = Bus()
    @test eltype(b) == Link{Float64}
    @test length(b) == 1

    # Putting values into busses. 
    b = Bus(2)
    gettask(l) = @async while true 
       take!(l) === NaN && break 
    end
    t = gettask.(b)
    sleep(1)
    @test typeof(t) == Vector{Task}
    @test iswritable(b)  
    for i in 1 : 5
        put!(b, [i, i + 1])
        @test read(b[1].buffer) == i
        @test read(b[2].buffer) == i + 1
    end
    close(b) 
    foreach(wait, t)
    @test all(istaskdone.(t))
    @test !any(isopen.(b))

    # Taking values from busses
    b = Bus(2)
    constructtask(l, valrange) = @async for val in valrange
        put!(l, val)
    end
    t = constructtask.(b, [[i for i = 1 : 10] for j = 1 : 2])
    sleep(1.)  # Wait for the task
    @test isreadable(b)  
    val = take!(b)
    @test val == [1., 1.]
    for i = 2 : 10
        @test take!(b) == [i, i]
    end
    close(b) 
    foreach(wait, t)
    @test all(istaskdone.(t))
    @test !any(isopen.(b))

    # Interconnection of Busses 
    b1 = Bus(2)
    b2 = Bus(2)
    b3 = Bus(2)
    @test !isconnected(b1, b2)
    @test !isconnected(b1, b3)
    connect(b1, b2)
    connect(b1, b3)
    @test isconnected(b1, b2)
    @test isconnected(b1, b3)
    t1 = gettask.(b1)
    t2 = gettask.(b2)
    t3 = gettask.(b3)
    val = [1, 2]
    put!(b1, val)
    @test b1[1].buffer.data[1] == 1     # First link of first bus buffer data
    @test b1[2].buffer.data[1] == 2     # Second link of first bus buffer data
    @test b2[1].buffer.data[1] == 1     # First link of second bus buffer data
    @test b2[2].buffer.data[1] == 2     # Second link of second bus buffer data
    @test b3[1].buffer.data[1] == 1     # First link of second bus buffer data
    @test b3[2].buffer.data[1] == 2     # Second link of second bus buffer data
    disconnect(b1, b2)
    @test !isconnected(b1, b2)
    put!(b1, val*2)
    @test b1[1].buffer.index == 3
    @test b1[2].buffer.index == 3
    @test b2[1].buffer.index == 2   # Since b2 is disconnected, `val*2` is not put into b2
    @test b2[2].buffer.index == 2   # Since b2 is disconnected, `val*2` is not put into b2
    @test b3[1].buffer.index == 3   # Since b3 is connected, `val*2` is put into b3
    @test b3[2].buffer.index == 3   # Since b3 is connected, `val*2` is put into b3
    foreach(close, [b1, b2, b3])
    @test all(map(t -> all(istaskdone.(t)), [t1, t2, t3]))
end  # testset