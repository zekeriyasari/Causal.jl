# This file includes the buffer test set

@testset "BufferTestSet" begin
    @info "Running BufferTestSet ..."

    # Simple Buffer construction
    buf = Buffer(5)
    @test eltype(buf) == Float64
    @test length(buf) == 5
    @test size(buf) == (5,)
    @test mode(buf) == Cyclic
    @test buf.index == 1
    @test isempty(buf)
    @test buf.state == :empty
    @test size(buf) == (5,)
    @test isa(buf, AbstractVector)

    # No multidimensional Buffer construction 
    @test_throws MethodError Buffer(2, 5)

    # # Buffer data length -> `datalength` deprecated.
    # buf = Buffer(5)
    # @test datalength(buf) == 5
    # buf = Buffer(3, 10)
    # @test datalength(buf) == 10

    # Writing values into Buffers
    buf = Buffer(5)
    write!(buf, 1.)
    @test !isempty(buf)
    @test !Utilities.isfull(buf)
    @test buf.index == 2
    @test buf.state == :nonempty

    # Reading from buffers
    val = read(buf)
    @test val == 1.
    @test buf.index == 2
    @test !isempty(buf)

    # More on buffer construction
    buf = Buffer{Fifo}(Float64, 5)
    buf = Buffer{Fifo}(Vector{Float64}, 5)
    buf = Buffer{Fifo}(5)
    buf = Buffer{Normal}(5)
    buf = Buffer(5)

    # # Filling buffers
    # buf = Buffer{Cyclic}(5)
    # fill!(buf, 1.)
    # @test outbuf(buf) == ones(5)
    # buf = Buffer{Normal}(2,5)
    # fill!(buf, [1, 1])
    # @test buf.data == ones(2, 5)

    # Writing into Buffers with different modes
    for bufmode in [Normal, Lifo, Fifo]
        buf = Buffer{bufmode}(Vector{Float64}, 5)
        for item in 1 : 5
            write!(buf, [item, item])
        end
        @test buf.output == [[item, item] for item in 5. : -1 : 1.]
        @test Utilities.isfull(buf)
        @test buf.index == 6
        @test_throws Exception write!(buf, [1., 2.])  # When full, data cannot be written into buffers.
    end

    buf = Buffer{Cyclic}(Vector{Float64}, 5)
    for item in 1 : 5
        write!(buf, [item, item])
    end
    @test buf.output == [[item, item] for item in 5. : -1 : 1.]
    @test Utilities.isfull(buf)
    @test buf.index == 6
    temp = copy(buf.output)
    write!(buf, [6., 6.])  # When full, data can be written into Cyclic buffers.
    @test buf.output == [[[6., 6.]]; temp[1 : end - 1]]

    # Reading from Buffers with different modes
    for bufmode in [Normal, Cyclic]
        bufn = Buffer{bufmode}(5)
        foreach(item -> write!(bufn, item), 1 : 5)
        for i = 1 : 5
            @test read(bufn) == 5
        end
        @test !isempty(bufn)
    end

    bufm = Buffer{Fifo}(5)
    foreach(item -> write!(bufm, item), 1 : 5)
    for i = 1 : 5
        @test read(bufm) == i
    end
    @test isempty(bufm)
    @test_throws Exception read(bufm)  # When buffer is empty, no more reads.

    buf = Buffer{Lifo}(5)
    foreach(item -> write!(buf, item), 1 : 5)
    vals = collect(5:-1:1)
    for i = 1 : 5
        @test read(buf) == vals[i]
    end
    @test isempty(buf)
    @test_throws Exception read(buf)  # When buffer is empty, no more reads.

    @info "Done BufferTestSet."
end  # testset
