# This file constains testset for Printer 

@testset "PrinterTestSet" begin 
    @info "Running PrinterTestSet ..."
    
    # Printer construction 
    printer = Printer(input=Inport(2), buflen=100)
    @test typeof(printer.trigger) == Inpin{Float64}
    @test typeof(printer.handshake) == Outpin{Bool}
    @test size(printer.timebuf) == (100,)
    @test size(printer.databuf) == (2, 100)
    @test isa(printer.input, Inport)
    @test printer.plugin === nothing
    @test typeof(printer.callbacks) <: Nothing
    @test typeof(printer.sinkcallback) <: Callback

    # Driving Printer 
    oport, iport, trg, hnd, tsk, tsk2 = equip(printer)
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

    @info "Done PrinterTestSet ..."
end  # testset 