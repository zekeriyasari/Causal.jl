# This file constains testset for Writer 

@testset "WriterTestSet" begin 
    # Writer construction 
    writer = Writer(Bus(3), buflen=10)
    writer = Writer(Bus(3), buflen=10, path=joinpath(tempdir(), "myfile.jld2"))
    writer = Writer(Bus(3), path=joinpath(tempdir(), "myfile2.jld2"))
    @test typeof(writer.trigger) == Link{Float64}
    @test typeof(writer.handshake) == Link{Bool}
    @test isa(writer.input, Bus)
    @test length(writer.input) == 3
    @test size(writer.timebuf) == (64,)
    @test size(writer.databuf) == (3, 64)
    @test writer.file.path == joinpath(tempdir(), "myfile3.jld2")
    @test writer.plugin === nothing
    @test !isempty(printer.callbacks)

    # Reading and writing into Writer 
    writer = Writer(Bus())
    open(writer)
    for t in 1 : 10
        write!(writer, t, sin(t))
    end
    close(writer)
    t, x = read(writer, flatten=true)
    @test isapprox(x, sin.(t))
    t, x = fread(writer.file.path, flatten=true)
    @test isapprox(x, sin.(t))

    # Moving/Copying Writer file.
    mkdir(joinpath(tempdir(), "testdir1"))
    mkdir(joinpath(tempdir(), "testdir2"))
    mkdir(joinpath(tempdir(), "testdir3"))
    w = Writer(Bus(), path=joinpath(tempdir(), "testdir1/myfile.jld2"))
    mv(w, "/tmp/testdir2")
    @test w.file.path == joinpath(tempdir(), "testdir2/myfile.jld2")
    w = Writer(Bus(), path=joinpath(tempdir(), "testdir1/myfile.jld2"))
    mv(w, "/tmp/testdir2")
    @test w.file.path == joinpath(tempdir(), "testdir2/myfile.jld2")
    cp(w, "/tmp/testdir3")
    @test isfile(joinpath(tempdir(), "testdir3/myfile.jld2"))

    # Driving Writer 
    writer = Writer(Bus(3), buflen=10)
    open(writer)
    tsk = launch(writer)
    for t in 1 : 100 
        drive(writer, t)
        put!(writer.input, ones(3)*t)
        approve(writer)
        @test read(writer.timebuf) == t
        @test [read(link.buffer) for link in writer.input] == ones(3) * t
        @show t 
    end
    close(writer)
    t, x = read(writer, flatten=true)
    @test t == collect(1 : 100)
    @test x == [collect(1:100) collect(1:100) collect(1:100)]
    terminate(writer)
    sleep(0.1)
    @test all(istaskdone.(tsk))

end  # testset 