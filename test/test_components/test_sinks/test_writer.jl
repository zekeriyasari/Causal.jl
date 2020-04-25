# This file constains testset for Writer 

@testset "WriterTestSet" begin
    # Preliminaries 
    randdirname() = string(uuid4())
    randfilename() = join([string(uuid4()), ".jld2"], "")
    testdir = tempdir()

    # Writer construction 
    writer = Writer(Inport(3), buflen=10)
    writer = Writer(Inport(3), buflen=10, path=joinpath(testdir, randfilename()))
    path = joinpath(testdir, randfilename())
    writer = Writer(Inport(3), path=path)
    @test typeof(writer.trigger) == Inpin{Float64}
    @test typeof(writer.handshake) == Outpin{Bool}
    @test isa(writer.input, Inport)
    @test length(writer.input) == 3
    @test size(writer.timebuf) == (64,)
    @test size(writer.databuf) == (3, 64)
    @test writer.plugin === nothing
    @test typeof(writer.callbacks) <: Callback

    # Reading and writing into Writer 
    writer = Writer(Inport())
    open(writer)
    for t in 1 : 10
        write!(writer, t, sin(t))
    end
    close(writer)
    data = read(writer, flatten=false)
    for (t, u) in data
        @test sin(t) == u
    end
    data = fread(writer.file.path, flatten=false)
    for (t, u) in data
        @test sin(t) == u
    end

    # Moving/Copying Writer file.
    filename = randfilename()
    dirnames = map(1:3) do i 
        path = joinpath(testdir, randdirname())
        ispath(path) || mkdir(path)
        path
    end
    paths = map(dname -> joinpath(dname, filename), dirnames)
    w = Writer(Inport(), path=paths[1])
    mv(w, dirnames[2], force=true)
    @test w.file.path == paths[2]
    cp(w, dirnames[3], force=true)
    @test isfile(paths[3])

    # Driving Writer 
    writer = Writer(Inport(3), buflen=10)
    open(writer)
    oport, iport, trg, hnd, comptask, outtask = prepare(writer)
    for t in 1 : 100 
        put!(trg, t)
        put!(oport, ones(3)*t)
        take!(hnd)
        @test read(writer.timebuf) == t
        @test [read(pin.links[1].buffer) for pin in oport] == ones(3) * t
    end
    close(writer)
    t, x = read(writer, flatten=true)
    @test t == collect(1 : 100)
    @test x == [collect(1:100) collect(1:100) collect(1:100)]
    put!(trg, NaN)
    sleep(0.1)
    @test istaskdone(comptask)

end  # testset 