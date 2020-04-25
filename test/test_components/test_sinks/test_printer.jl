# This file constains testset for Printer 

@testset "PrinterTestSet" begin 
    # Printer construction 
    printer = Printer(Inport(2), buflen=100)
    @test typeof(printer.trigger) == Inpin{Float64}
    @test typeof(printer.handshake) == Outpin{Bool}
    @test size(printer.timebuf) == (100,)
    @test size(printer.databuf) == (2, 100)
    @test isa(printer.input, Inport)
    @test printer.plugin === nothing
    @test typeof(printer.callbacks) <: Callback

    # Driving Printer 
    oport, iport, trg, hnd, tsk, tsk2 = prepare(printer)
    for t in 1 : 200
        put!(trg, t)
        put!(oport, ones(2) * t)
        take!(hnd)
        @test read(printer.timebuf) == t
        @test [read(pin.links[1].buffer) for pin in oport] == ones(2) * t
    end 
    put!(trg, NaN)
    sleep(0.1)
    @test istaskdone(tsk)
end  # testset 