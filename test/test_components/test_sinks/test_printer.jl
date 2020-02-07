# This file constains testset for Printer 

@testset "PrinterTestSet" begin 
    # Printer construction 
    printer = Printer(Bus(2), buflen=100)
    @test typeof(printer.trigger) == Link{Float64}
    @test typeof(printer.handshake) == Link{Bool}
    @test size(printer.timebuf) == (100,)
    @test size(printer.databuf) == (2, 100)
    @test isa(printer.input, Bus)
    @test printer.plugin === nothing
    @test !isempty(printer.callbacks)

    # Driving Printer 
    tsk = launch(printer)
    for t in 1 : 200
        drive(printer, t)
        put!(printer.input, ones(2) * t)
        approve(printer)
        @test read(printer.timebuf) == t
        @test [read(link.buffer) for link in printer.input] == ones(2) * t
    end 
    terminate(printer)
    sleep(0.1)
    @test all(istaskdone.(tsk))
end  # testset 