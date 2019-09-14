# This file includes the printers

import Base.print


mutable struct Printer{IB, DB, TB, P} <: AbstractSink
    @generic_sink_fields
end
function Printer(input; buflen=64, plugin=nothing)
    # Construct the buffers
    timebuf = Buffer(buflen)
    databuf = length(input) == 1 ? Buffer(buflen) : Buffer(buflen, length(input))
    trigger = Link()
    addplugin(Printer(input, databuf, timebuf, plugin, trigger, Callback[], uuid4()), print)
end

##### Printer reading and writing
print(printer::Printer, td, xd) = print("For time", "[", td[1], " ... ", td[end], "]", " => ", xd, "\n")

open(printer::Printer) = printer
close(printer::Printer) =  printer
