# This file includes the testset for links

@testset "LinkTestSet" begin
    @info "Running LinkTestSet ..."

    # Link construction.
    l = Link(5)
    @test eltype(l) == Float64
    @test eltype(l.channel) == Float64
    @test l.channel.sz_max == 0
    @test length(l.buffer) == 5
    @test mode(l.buffer) == Cyclic
    @test !iswritable(l)
    @test !isreadable(l)

    # Link construction that carries vectors 
    l = Link{Vector{Float64}}() 

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

    @info "Done LinkTestSet."
end  # testset
