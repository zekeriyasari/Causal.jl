# This file includes the printers

import Base.print


mutable struct Printer{DB, TB, P} <: AbstractSink
    @generic_sink_fields
    function Printer(input, buflen, plugin, callbacks, name)
        # Construct the buffers
        timebuf = Buffer(buflen)
        databuf = length(input) == 1 ? Buffer(buflen) : Buffer(buflen, length(input))
        trigger = Link()
        printer = new{typeof(databuf), typeof(timebuf), typeof(plugin)}(input, databuf, timebuf, 
            plugin, trigger, callbacks, name)
        add_callback(printer, print)
    end
end
Printer(input; buflen=64, plugin=nothing, callbacks=Callback[], name=string(uuid4())) =  
    Printer(input, buflen, plugin, callbacks, name)

##### Printer reading and writing
print(printer::Printer, td, xd) = print("For time", "[", td[1], " ... ", td[end], "]", " => ", xd, "\n")

open(printer::Printer) = printer
close(printer::Printer) =  printer
