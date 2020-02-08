# This file constains testset for Writer 

@testset "WriterTestSet" begin
    # Preliminaries 
    randdirname() = randstring()
    randfilename() = randstring() * ".jld2"

    # Writer construction 
    writer = Writer(Bus(3), buflen=10)
    writer = Writer(Bus(3), buflen=10, path=joinpath(tempdir(), randfilename()))
    fname = randfilename()
    writer = Writer(Bus(3), path=joinpath(tempdir(), fname))
    @test typeof(writer.trigger) == Link{Float64}
    @test typeof(writer.handshake) == Link{Bool}
    @test isa(writer.input, Bus)
    @test length(writer.input) == 3
    @test size(writer.timebuf) == (64,)
    @test size(writer.databuf) == (3, 64)
    @test writer.file.path == joinpath(tempdir(), fname)
    @test writer.plugin === nothing
    @test !isempty(writer.callbacks)

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
    filename = randfilename()
    dirnames = [randdirname() for i = 1 : 3]
    mkdir(joinpath(tempdir(), dirnames[1]))
    mkdir(joinpath(tempdir(), dirnames[2]))
    mkdir(joinpath(tempdir(), dirnames[3]))
    w = Writer(Bus(), path=joinpath(tempdir(), dirnames[1], filename))
    mv(w, joinpath(tempdir(), dirnames[2]))
    @test w.file.path == joinpath(tempdir(), dirnames[2], filename)
    cp(w, joinpath(tempdir(), dirnames[3]))
    @test isfile(joinpath(tempdir(), dirnames[3], filename))

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
    end
    close(writer)
    t, x = read(writer, flatten=true)
    @test t == collect(1 : 100)
    @test x == [collect(1:100) collect(1:100) collect(1:100)]
    terminate(writer)
    sleep(0.1)
    @test all(istaskdone.(tsk))

end  # testset 