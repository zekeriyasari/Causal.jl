# This file constains testset for Scope 

@testset "ScopeTestSet" begin 
    @info "Running ScopeTestSet ..."

    # Scope construction 
    scope = Scope(input=Inport(1), buflen=100)
    @test typeof(scope.trigger) == Inpin{Float64}
    @test typeof(scope.handshake) == Outpin{Bool}
    @test size(scope.timebuf) == (100,)
    @test size(scope.databuf) == (100,)
    @test isa(scope.input, Inport)
    @test scope.plugin === nothing
    @test typeof(scope.callbacks) <: Nothing
    @test typeof(scope.sinkcallback) <: Callback

    # Driving Scope 
    open(scope)
    oport, iport, trg, hnd, tsk, tsk2 = prepare(scope)
    for t in 1 : 200
        put!(trg, t)
        put!(oport, ones(1) * t)
        take!(hnd)
        @test read(scope.timebuf) == t
        @test [read(pin.links[1].buffer) for pin in oport] == ones(1) * t
        @show t
    end 
    put!(trg, NaN)
    sleep(0.1)
    @test istaskdone(tsk)

    @info "Done ScopeTestSet ..."
end  # testset 