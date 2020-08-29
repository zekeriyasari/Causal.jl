# This file inludes Printer type 

export Printer

"""
    $(TYPEDEF) 

# Fields 

    $(FIELDS)

`Printer` with input bus `input`. `buflen` is the length of its internal `buflen`. `plugin` is data proccessing tool.
"""
@def_sink mutable struct Printer{A} <: AbstractSink 
    action::A = print 
end

show(io::IO, printer::Printer) = print(io, "Printer(nin:$(length(printer.input)))")

"""
    $(SIGNATURES)

Prints `xd` corresponding to `xd` to the console.
"""
print(printer::Printer, td, xd) = print("For time", "[", td[1], " ... ", td[end], "]", " => ", xd, "\n")

"""
    $(SIGNATURES)

Does nothing. Just a common interface function ot `AbstractSink` interface.
"""
open(printer::Printer) = printer

"""
    $(SIGNATURES)

Does nothing. Just a common interface function ot `AbstractSink` interface.
"""
close(printer::Printer) =  printer
