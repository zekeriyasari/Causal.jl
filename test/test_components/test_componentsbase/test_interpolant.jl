# This file includes the test for Interpolant types. 

@testset "InterpolantTestset" begin 
    # Test scalar interpolant 
    tbuf = Buffer(5)
    dbuf = Buffer(5) 
    interp = Interpolant(tbuf, dbuf)
    @test interp isa Causal.Components.ComponentsBase.ScalarInterpolant
    foreach(t -> write!(interp.timebuf, t), [0., 1.])
    foreach(t -> write!(interp.databuf, t), [0., 1.])
    update!(interp)
    interp(0.)
    
    # Test vector intepolant 
    tbuf = Buffer(5) 
    dbuf = Buffer(Vector{Float64}, 5) 
    interp = Interpolant(tbuf, dbuf)
    @test interp isa Causal.Components.ComponentsBase.VectorInterpolant
    foreach(t -> write!(interp.timebuf, t), [0., 1.])
    foreach(t -> write!(interp.databuf, t), [zeros(2), ones(2)])
    update!(interp)
    @test length(interp.itp) == 2
    interp[1](0.)
    interp[2](0.)
end