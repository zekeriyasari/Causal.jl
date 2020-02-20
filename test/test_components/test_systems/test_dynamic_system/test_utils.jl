# This file includes tests for utilis in DynamicSystems module 

@testset "UtilsInDynamicSystems" begin 
    # Interpolation construction 
    u = Interpolant(0., 1., [1., 2., 3.], [2, 4, 6])
    u = Interpolant(0., 1., 1:3, 2:2:6)
    u = Interpolant(0., 1., [1.], [2.])

    # Calling interpolations.
    for val in 3. : 10. 
        u.coeffinal = [val]
        @test isapprox(u[1](0.5), (u.coefinit[1] + u.coeffinal[1]) / 2) 
    end
end 
