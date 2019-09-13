# This file includes the buffer test set 
# TODO: Complete Buffer testset.

@testset "BufferTestSet" begin
    @info "BufferTestSet started..."

    buf = Buffer(5)
    @test eltype(buf) == Float64
    @test length(buf) == 5
    @test mode(buf) == Cyclic
    @test buf.index == 1
    @test isempty(buf)
    @test buf.state == :empty
    @test size(buf) == (5,)

    write!(buf, 1.)
    @test !isempty(buf)
    @test !isfull(buf)
    @test buf.index == 2
    @test buf.state == :nonempty

    val = read(buf)
    @test val == 1.
    @test buf.index == 2
    @test !isempty(buf)

    buf = Buffer(5)
    for val in 1. : 10. 
        write!(buf, val)
        @show (buf.data, buf.index, buf.state)
    end

    buf = Buffer(Vector{Float64}, 4)
    @test eltype(buf) == Vector{Float64}
    @test mode(buf) == Cyclic
    @test length(buf) == 4
    @test size(buf) == (4,)
    for i = 1 : 10
        write!(buf, rand(5))
        @show (buf.data, buf.index, buf.state)
    end

    @info "BufferTestSet done..."
end  # testset