# This file includes testset to define new sink types 

@testset "NewSinkDefinitionTestset" begin 
    # New sink types must be of subtypes of `AbstractSink`.
    @test_throws Exception @eval @def_sink struct Mysink{T,S} 
        field1::T 
        field2::S
    end

    @test_throws Exception @eval @def_source struct Mysink{T,S} <: SomeDummyType
        readout::RO = t -> sin(t) 
        output::OP = Outport()
    end 
end