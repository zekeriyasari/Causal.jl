# This file constains testset for Scope 

@testset "ScopeTestSet" begin 
    # Scope construction 
    scope = Scope(Bus(1), buflen=100)
    @test typeof(scope.trigger) == Link{Float64}
    @test typeof(scope.handshake) == Link{Bool}
    @test size(scope.timebuf) == (100,)
    @test size(scope.databuf) == (1, 100)
    @test isa(scope.input, Bus)
    @test scope.plugin === nothing
    @test !isempty(scope.callbacks)

    # Driving Scope 
    open(scope)
    tsk = launch(scope)
    for t in 1 : 200
        drive(scope, t)
        put!(scope.input, ones(1) * t)
        approve(scope)
        @test read(scope.timebuf) == t
        @test [read(link.buffer) for link in scope.input] == ones(1) * t
        @show t
    end 
    terminate(scope)
    sleep(0.1)
    @test all(istaskdone.(tsk))
end  # testset 