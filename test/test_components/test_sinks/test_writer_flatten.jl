@testset "WriterFlattenChunksTestSet" begin
    mktempdir() do dir
        # FileIO returns Dict{String,Any}; classification must inspect actual
        # chunks rather than SortedDict's inferred (possibly Any) value type.
        vectorpath = joinpath(dir,"vector.jld2")
        jldopen(vectorpath,"w") do file
            fwrite!(file,[2.0,1.0],[20.0,10.0])
            fwrite!(file,[4.0,3.0],[40.0,30.0])
        end
        @test valtype(typeof(load(vectorpath))) == Any
        t,x=fread(vectorpath;flatten=true)
        @test t == [1.0,2.0,3.0,4.0]
        @test x == [10.0,20.0,30.0,40.0]

        matrixpath = joinpath(dir,"matrix.jld2")
        jldopen(matrixpath,"w") do file
            fwrite!(file,[2.0,1.0],[20.0 10.0;200.0 100.0])
            fwrite!(file,[4.0,3.0],[40.0 30.0;400.0 300.0])
        end
        @test valtype(typeof(load(matrixpath))) == Any
        t,x=fread(matrixpath;flatten=true)
        @test t == [1.0,2.0,3.0,4.0]
        @test x == [10.0 100.0;20.0 200.0;30.0 300.0;40.0 400.0]

        mixedpath = joinpath(dir,"mixed.jld2")
        jldopen(mixedpath,"w") do file
            fwrite!(file,[1.0],[10.0])
            fwrite!(file,[2.0],reshape([20.0],1,1))
        end
        @test_throws ErrorException fread(mixedpath;flatten=true)
    end
end
