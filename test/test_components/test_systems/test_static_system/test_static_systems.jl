# # This file includes testset for StaticSystems

# @testset "StaticSystems" begin
    
#     # StaticSystem construction
#     ofunc(u, t) = [u[1] + u[2], u[1] - u[2], u[1] * u[2]]
#     ss = StaticSystem(Bus(2), Bus(3), ofunc)
#     @test isimmutable(ss)
#     @test length(ss.input) == 2
#     @test length(ss.output) == 3
#     @test typeof(ss.input) == Bus{Link{Float64}}
#     @test typeof(ss.output) == Bus{Link{Float64}}
#     @test typeof(ss.trigger) == Link{Float64}
#     @test typeof(ss.handshake) == Link{Bool}
    
#     ofunc2(u, t) = nothing
#     ss = StaticSystem(nothing, nothing, ofunc2)  # Input or output may be nothing
#     @test ss.input === nothing
#     @test ss.output === nothing

#     # Driving of StaticSystem
#     ofunc3(u, t) = u[1] + u[2] 
#     ss = StaticSystem(Bus(2), Bus(1), ofunc3)
#     tsk = launch(ss)
#     for t in 1. : 10.
#         drive(ss, t)
#         put!(ss.input, [t, t])
#         approve(ss)
#         @test read(ss.output[1].buffer) == t + t
#     end
#     @test !any(istaskdone.(tsk))
#     terminate(ss)
#     sleep(0.1)
#     @test all(istaskdone.(tsk))

#     # Adder tests
#     ss = Adder(Bus(2))
#     @test isimmutable(ss)
#     @test ss.signs == (+, +)
#     @test length(ss.output) == 1

#     ss = Adder(Bus(3), (+, +, -))
#     @test ss.signs == (+, +, -)
#     tsk = launch(ss)
#     drive(ss, 1.)
#     put!(ss.input, [1, 3, 5])
#     approve(ss)
#     @test read(ss.output[1].buffer) == 1 + 3 - 5
#     terminate(ss) 
#     sleep(0.1)
#     @test all(istaskdone.(tsk))

#     # Multiplier tests
#     ss = Multiplier(Bus(2))
#     @test isimmutable(ss)
#     @test ss.ops == (*, *)
#     @test length(ss.output) == 1

#     ss = Multiplier(Bus(4), (*, *, /,*))
#     @test ss.ops == (*, *, /, *)
#     tsk = launch(ss)
#     drive(ss, 1.)
#     put!(ss.input, [1, 3, 5, 6])
#     approve(ss)
#     @test read(ss.output[1].buffer) == 1 * 3 / 5 * 6
#     terminate(ss)
#     sleep(0.1)
#     @test all(istaskdone.(tsk))

#     # Gain tests 
#     ss = Gain(Bus(3))
#     @test isimmutable(ss)
#     @test ss.gain == 1.
#     @test length(ss.output) == 3
#     K = rand(3, 3)
#     ss = Gain(Bus(3), gain=K)
#     tsk = launch(ss)
#     u = rand(3)
#     drive(ss, 1.)
#     put!(ss.input, u)
#     approve(ss)
#     @test [read(link.buffer) for link in ss.output] == K * u
#     terminate(ss)
#     sleep(0.1)
#     @test all(istaskdone.(tsk))

#     # Terminator tests 
#     ss = Terminator(Bus(3))
#     @test isimmutable(ss)
#     @test ss.outputfunc === nothing
#     @test ss.output === nothing
#     @test typeof(ss.trigger) == Link{Float64}
#     @test typeof(ss.handshake) == Link{Bool}
#     tsk = launch(ss)
#     drive(ss, 1.)
#     put!(ss.input, [1., 2., 3.])
#     approve(ss)
#     @test [read(link.buffer) for link in ss.input] == [1., 2., 3.]
#     terminate(ss)
#     sleep(0.1)
#     @test all(istaskdone.(tsk))

#     # Memory tests
#     ss = Memory(Bus(3), 10, initial=zeros(3))
#     ss = Memory(Bus(3), 10)
#     @test isimmutable(ss)
#     @test size(ss.buffer) == (3, 10)
#     @test isfull(ss.buffer)
#     @test mode(ss.buffer) == Fifo
#     @test typeof(ss.trigger) == Link{Float64}
#     @test typeof(ss.handshake) == Link{Bool}
#     @test typeof(ss.input) == Bus{Link{Float64}}
#     @test typeof(ss.output) == Bus{Link{Float64}}
#     @test ss.buffer.data == zeros(3, 10)
#     tsk = launch(ss)
#     drive(ss, 1.)
#     put!(ss.input, [10, 20, 30])
#     approve(ss)
#     @test [read(link.buffer) for link in ss.output] == zeros(3)
#     @test ss.buffer[:, end] == [10, 20, 30]
#     terminate(ss)
#     sleep(0.1)
#     @test all(istaskdone.(tsk))

#     # Coupler test
#     conmat =  [-1 1; 1 -1]
#     cplmat = [1 0 0; 0 0 0; 0 0 0]
#     ss = Coupler(conmat, cplmat)
#     @test isimmutable(ss)
#     @test typeof(ss.trigger) == Link{Float64}
#     @test typeof(ss.handshake) == Link{Bool}
#     @test typeof(ss.input) == Bus{Link{Float64}}
#     @test typeof(ss.output) == Bus{Link{Float64}}
#     @test length(ss.input) == 6
#     @test length(ss.output) == 6 
#     tsk = launch(ss)
#     drive(ss, 1.)
#     u = rand(6)
#     put!(ss.input, u)
#     approve(ss)
#     @test [read(link.buffer) for link in ss.output] == kron(conmat, cplmat) * u
#     terminate(ss)
#     sleep(0.1)
#     @test all(istaskdone.(tsk))

# end # testset