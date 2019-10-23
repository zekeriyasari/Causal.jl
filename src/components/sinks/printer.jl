# This file includes the printers

import Base.print


mutable struct Printer{IB, DB, TB, P, T, H} <: AbstractSink
    @generic_sink_fields
    function Printer(input::Bus{Union{Missing, T}}, buflen=64, plugin=nothing) where T
        # Construct the buffers
        timebuf = Buffer(buflen)
        databuf = Buffer(Vector{T}, buflen)
        trigger = Link()
        handshake = Link{Bool}()
        addplugin(
            new{typeof(input), typeof(databuf), typeof(timebuf), typeof(plugin), typeof(trigger),
            typeof(handshake)}(input, databuf, timebuf, plugin, trigger, handshake, Callback[], uuid4()), print)
    end
end

show(io::IO, printer::Printer) = print(io, "Printer(nin:$(length(printer.input)))")

##### Printer reading and writing
print(printer::Printer, td, xd) = print("For time", "[", td[1], " ... ", td[end], "]", " => ", xd, "\n")

open(printer::Printer) = printer
close(printer::Printer) =  printer
