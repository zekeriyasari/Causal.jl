# # This file includes the test set for busses.

# @testset "BussesTestSet" begin
#     @info "BussesTestSet started..."

#     # Construction of bus 
#     b = Bus(5)
#     @test length(b) == 5
#     @test eltype(b) == Float64

#     # Putting values into busses. 
#     b = Bus()
#     t = launch(b)
#     sleep(1.)
#     @test typeof(t) == Vector{Task}
#     @test all(istaskstarted.(t))
#     for val in 1. : 5.
#         put!(b, [val])
#     end
#     close(b) 
#     sleep(1.)
#     @test all(istaskdone.(t))
#     @test all([!isopen(l.channel) for l in b])

#     # Taking values from busses
#     b = Bus(2)
#     t = launch(b, [[rand() for i = 1 : 10] for m = 1 : length(b)])
#     sleep(1.)  # Wait for the task
#     @test all(istaskstarted.(t))
#     val = take!(b)
#     @test typeof(val) == Vector{Float64}
#     for i = 2 : 10
#         @show take!(b)
#     end
#     close(b) 
#     sleep(1.)  # Wait for the task
#     @test all(istaskdone.(t))
#     @test all([!isopen(l.channel) for l in b])

#     # Putting into Bus{Vector{Float64}}
#     b = Bus{Vector{Float64}}(3)
#     t = launch(b)
#     for val in 1. : 10. 
#         put!(b, [rand(6) for i = 1 : length(b)])
#     end
#     close(b) 
#     sleep(1.)  # Wait for the task
#     @test all(istaskdone.(t))
#     @test all([!isopen(l.channel) for l in b])

#     # Taking from Bus{Vector{Float64}}
#     b = Bus{Vector{Float64}}(3)
#     t = launch(b, [[rand(7) for i = 1 : 20] for j = 1 : length(b)])
#     sleep(1.)
#     @test all(istaskstarted.(t))
#     val = take!(b)
#     @test typeof(val) == Vector{Vector{Float64}}
#     for i in 2 : 20
#         @show take!(b)
#     end
#     close(b) 
#     sleep(1.)  # Wait for the task
#     @test all(istaskdone.(t))
#     @test all([!isopen(l.channel) for l in b])

#     # Interconnection of Busses 
#     b1 = Bus{Vector{Float64}}(2)
#     b2 = Bus{Vector{Float64}}(2)
#     @test !isconnected(b1, b2)
#     connect(b1, b2)
#     @test isconnected(b1, b2)
#     @test isconnected(b2, b1)
#     l1 = launch(b1)
#     l2 = launch(b2)
#     val = [zeros(3), ones(4)]
#     put!(b1, val)
#     @test b1[1].buffer.data[1] == zeros(3)  # First link of first bus buffer data
#     @test b1[2].buffer.data[1] == ones(4)   # Second link of first bus buffer data
#     @test b2[1].buffer.data[1] == zeros(3)  # First link of second bus buffer data
#     @test b2[2].buffer.data[1] == ones(4)   # Second link of second bus buffer data
#     disconnect(b1, b2)
#     @test !isconnected(b1, b2)
#     put!(b1, val*2)
#     @test b1[1].buffer.index == 3
#     @test b1[2].buffer.index == 3
#     @test b2[1].buffer.index == 2  # Since b2 is disconnected, `val*2` is not put into b2
#     @test b2[2].buffer.index == 2  # Since b2 is disconnected, `val*2` is not put into b2

#      @info "BussesTestSet done..."
# end  # testset