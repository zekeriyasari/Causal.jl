# This file constains testset for Writer 

@testset "WriterTestSet" begin
    # Preliminaries 
    randdirname() = string(uuid4())
    randfilename() = join([string(uuid4()), ".jld2"], "")
    testdir = tempdir()

    # Writer construction 
    writer = Writer(Bus(3), buflen=10)
    writer = Writer(Bus(3), buflen=10, path=joinpath(testdir, randfilename()))
    path = joinpath(testdir, randfilename())
    writer = Writer(Bus(3), path=path)
    @test typeof(writer.trigger) == Link{Float64}
    @test typeof(writer.handshake) == Link{Bool}
    @test isa(writer.input, Bus)
    @test length(writer.input) == 3
    @test size(writer.timebuf) == (64,)
    @test size(writer.databuf) == (3, 64)
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
    dirnames = map(i -> mkdir(joinpath(testdir, randdirname())), 1 : 3)
    paths = map(dname -> joinpath(dname, filename), dirnames)
    w = Writer(Bus(), path=paths[1])
    mv(w, dirnames[2])
    @test w.file.path == paths[2]
    cp(w, dirnames[3])
    @test isfile(paths[3])

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