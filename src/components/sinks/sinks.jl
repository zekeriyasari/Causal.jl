# This file constains sink tools for the objects of Causal.

import Base.print

"""
    @def_sink ex 

where `ex` is the expression to define to define a new AbstractSink component type. The usage is as follows:
```julia
@def_sink struct MySink{T1,T2,T3,...,TN, A} <: AbstractSink
    param1::T1 = param1_default     # optional field 
    param2::T2 = param2_default     # optional field 
    param3::T3 = param3_default     # optional field
        ⋮
    paramN::TN = paramN_default     # optional field 
    action::A = action_function     # mandatory field
end
```
Here, `MySink` has `N` parameters and `action` function

!!! warning `action` function must have a method `action(sink::MySink, t, u)` where `t` is the time data and `u` is the data
    flowing into the sink.

!!! warning New static system must be a subtype of `AbstractSink` to function properly.

# Example 
```julia 
julia> @def_sink struct MySink{A} <: AbstractSink 
       action::A = actionfunc
       end

julia> actionfunc(sink::MySink, t, u) = println(t, u)
actionfunc (generic function with 1 method)

julia> sink = MySink();

julia> sink.action(sink, ones(2), ones(2) * 2)
[1.0, 1.0][2.0, 2.0]
```
"""
macro def_sink(ex) 
    ex.args[2].head == :(<:) && ex.args[2].args[2] == :AbstractSink || 
        error("Invalid usage. The type should be a subtype of AbstractSink.\n$ex")
    foreach(nex -> appendex!(ex, nex), [
        :( trigger::$TRIGGER_TYPE_SYMBOL = Inpin() ),
        :( handshake::$HANDSHAKE_TYPE_SYMBOL = Outpin{Bool}() ),
        :( callbacks::$CALLBACKS_TYPE_SYMBOL = nothing ),
        :( name::Symbol = Symbol() ),
        :( id::$ID_TYPE_SYMBOL = Causal.uuid4() ),
        :( input::$INPUT_TYPE_SYMBOL = Inport() ),
        :( buflen::Int = 64 ), 
        :( plugin::$PLUGIN_TYPE_SYMBOL = nothing ), 
        :( timebuf::$TIMEBUF_TYPE_SYMBOL = Buffer(buflen)  ), 
        :( databuf::$DATABUF_TYPE_SYMBOL = length(input) == 1 ? Buffer(buflen) :  Buffer(length(input), buflen) ), 
        :( sinkcallback::$SINK_CALLBACK_TYPE_SYMBOL = plugin === nothing ? 
            Callback(sink->ishit(databuf), sink->action(sink, outbuf(timebuf), outbuf(databuf)), true, id) :
            Callback(sink->ishit(databuf), sink->action(sink, outbuf(timebuf), plugin.process(outbuf(databuf))),true, id) ), 
        ])
    quote 
        Base.@kwdef $ex 
    end |> esc 
end

# function construct_sink_buffers(input, buflen) T = datatype(input) n = length(input) n == 1 ? Buffer(T, buflen) :
#     [Buffer(T, buflen) for i in 1 : n] end

# construct_sink_callback(databuf::Buffer, timebuf, plugin::Nothing, action, id) = Callback(sink->ishit(timebuf),
#     sink->action(sink, reverse(timebuf.output), reverse(databuf.output)), true, id)

# construct_sink_callback(databuf::AbstractVector{<:Buffer}, timebuf, plugin::Nothing, action, id) =
#     Callback(sink->ishit(timebuf), sink->action(sink, reverse(timebuf.output), hcat([reverse(buf.output) for buf in
#     databuf]...)), true, id)

# construct_sink_callback(databuf::Buffer, timebuf, plugin::AbstractPlugin, action, id) = Callback(sink->ishit(timebuf),
#     sink->action(sink, reverse(timebuf.output), plugin.process(reverse(databuf.output))), true, id) 

# construct_sink_callback(databuf::AbstractVector{<:Buffer}, timebuf, plugin::AbstractPlugin, action, id) =
#     Callback(sink->ishit(timebuf), sink->action(sink, reverse(timebuf.output), plugin.process(hcat([reverse(buf.output) for
#     buf in databuf]...))), true, id) 


##### Define sink library

# ----------------------------- Writer -------------------------------- 
"""
    $TYPEDEF

Constructs a `Writer` whose input bus is `input`. `buflen` is the length of the internal buffer of `Writer`. If not nothing,
`plugin` is used to processes the incomming data. `path` determines the path of the file of `Writer`.

# Fields 

    $TYPEDFIELDS

!!! note 
    The type of `file` of `Writer` is [`JLD2`](https://github.com/JuliaIO/JLD2.jl).    

!!! warning 
    When initialized, the `file` of `Writer` is closed. See [`open(writer::Writer)`](@ref) and
    [`close(writer::Writer)`](@ref).
"""
@def_sink mutable struct Writer{A, FL} <: AbstractSink
    "Writer action to write data to file"
    action::A = write!
    "File path of the writer"
    path::String = joinpath(tempdir(), string(uuid4()) * ".jld2") 
    "File in which data is recorded"
    file::FL = (
        endswith(path,".jld2") || error("Currenly only jld2 file format is used.");
        f = jldopen(path, "w"); 
        close(f); 
        f
    )
end

"""
    $SIGNATURES

Writes `xd` corresponding to `xd` to the file of `writer`.

# Example 
```julia 
julia> w = Writer(Inport(1))
Writer(path:/tmp/e907d6ad-8db2-4c4a-9959-5b8d33d32156.jld2, nin:1)

julia> open(w)
Writer(path:/tmp/e907d6ad-8db2-4c4a-9959-5b8d33d32156.jld2, nin:1)

julia> write!(w, 0., 10.)
10.0

julia> write!(w, 1., 20.)
20.0

julia> w.file
JLDFile /tmp/e907d6ad-8db2-4c4a-9959-5b8d33d32156.jld2 (read/write)
 ├─🔢 0.0
 └─🔢 1.0

julia> w.file[string(0.)]
10.0
```
"""
write!(writer::Writer, td, xd) = fwrite!(writer.file, td, xd)
fwrite!(file, td, xd) = file[string(td)] = xd

"""
    $SIGNATURES

Read the contents of the file of `writer` and returns the sorted content of the file. If `flatten` is `true`, the content is
also flattened.
"""
read(writer::Writer; flatten=true) = fread(writer.file.path, flatten=flatten)

"""
    $SIGNATURES

Reads the content of `jld2` file and returns the sorted file content. 
"""
function fread(path::String; flatten=false)
    content = load(path)
    data = SortedDict([(eval(Meta.parse(key)), val) for (key, val) in zip(keys(content), values(content))])
    if flatten
        t = vcat(reverse.(keys(data), dims=1)...)
        T = _getelytpe(data)
        if T <: AbstractVector
            x = vcat(reverse.(values(data), dims=1)...)
            return t, x 
        elseif T <: AbstractMatrix
            x = collect(hcat(reverse.(values(data), dims=2)...)')
            return t, x
        else 
            msg = "Data cannot be read from the file."
            msg *= "Expected element type AbstractVector or AbstractMatrix, "
            msg *= "got $T instead." 
            error(msg)
        end
    else
        return data
    end
end

_getelytpe(data::SortedDict{T1, T2, T3}) where {T1, T2, T3} = T2

flatten(content) = (collect(vcat(keys(content)...)), collect(vcat(values(content)...)))

"""
    $SIGNATURES

Moves the file of `writer` to `dst`. If `force` is `true`, the if `dst` is not a valid path, it is forced to be constructed.

# Example 
```julia
julia> mkdir(joinpath(tempdir(), "testdir1"))
"/tmp/testdir1"

julia> mkdir(joinpath(tempdir(), "testdir2"))
"/tmp/testdir2"

julia> w = Writer(Inport(), path="/tmp/testdir1/myfile.jld2")
Writer(path:/tmp/testdir1/myfile.jld2, nin:1)

julia> mv(w, "/tmp/testdir2")
Writer(path:/tmp/testdir2/myfile.jld2, nin:1)
```
"""
function mv(writer::Writer, dst; force::Bool=false)
    # id = writer.id
    id = basename(writer.file.path)
    dstpath = joinpath(dst, string(id))
    srcpath = writer.file.path
    mv(srcpath, dstpath, force=force)
    writer.file.path = dstpath  # Update the file path
    writer
end

"""
    $SIGNATURES

Copies the file of `writer` to `dst`. If `force` is `true`, the if `dst` is not a valid path, it is forced to be constructed.
If `follow_symlinks` is `true`, symbolinks are followed.

# Example 
```julia
julia> mkdir(joinpath(tempdir(), "testdir1"))
"/tmp/testdir1"

julia> mkdir(joinpath(tempdir(), "testdir2"))
"/tmp/testdir2"

julia> w = Writer(Inport(), path="/tmp/testdir1")
Writer(path:/tmp/testdir1.jld2, nin:1)

julia> cp(w, "/tmp/testdir2")
Writer(path:/tmp/testdir2/1e72bad1-9800-4ca0-bccd-702afe75e555, nin:1)
```
"""
function cp(writer::Writer, dst; force=false, follow_symlinks=false)
    # id = writer.id
    id = basename(writer.file.path)
    dstpath = joinpath(dst, string(id))
    cp(writer.file.path, dstpath, force=force, follow_symlinks=follow_symlinks)
    writer
end

""" 
    $SIGNATURES

Opens `writer` by opening the its `file` in  `read/write` mode. When `writer` is not openned, it is not possible to write
data in `writer`. See also [`close(writer::Writer)`](@ref)
"""
open(writer::Writer, mode::String="a") = (writer.file = jldopen(writer.file.path, mode); writer)

"""
    $SIGNATURES

Closes `writer` by closing its `file`. When `writer` is closed, it is not possible to write data in `writer`. See also
[`open(writer::Writer)`](@ref)
"""
close(writer::Writer) =  (close(writer.file); writer)


# ----------------------------- Printer --------------------------------
"""
    $TYPEDEF
  
Constructs a `Printer` with input bus `input`. `buflen` is the length of its internal `buflen`. `plugin` is data proccessing 
tool.

# Fields 

    $TYPEDFIELDS
"""
@def_sink mutable struct Printer{A} <: AbstractSink 
    "Action of the sink that prints data"
    action::A = print 
end

"""
    $SIGNATURES

Prints `xd` corresponding to `xd` to the console.
"""
print(printer::Printer, td, xd) = print("For time", "[", td[1], " ... ", td[end], "]", " => ", xd, "\n")

"""
    $SIGNATURES

Does nothing. Just a common interface function ot `AbstractSink` interface.
"""
open(printer::Printer) = printer

"""
    $SIGNATURES

Does nothing. Just a common interface function ot `AbstractSink` interface.
"""
close(printer::Printer) =  printer

# ----------------------------- Scope --------------------------------
"""
    $TYPEDEF

Constructs a `Scope` with input bus `input`. `buflen` is the length of the internal buffer of `Scope`. `plugin` is the
additional data processing tool. `args`,`kwargs` are passed into `plots(args...; kwargs...))`. See
(https://github.com/JuliaPlots/Plots.jl) for more information.

!!! warning When initialized, the `plot` of `Scope` is closed. See [`open(sink::Scope)`](@ref) and
    [`close(sink::Scope)`](@ref).

# Fields 

    $TYPEDFIELDS
"""
@def_sink mutable struct Scope{A, PA, PK, PLT} <: AbstractSink
    "Action of the component to update data"
    action::A = update!
    "Plottings arguments"
    pltargs::PA = () 
    "Plottings keyword arguments"
    pltkwargs::PK = NamedTuple()
    "Plot object of the component"
    plt::PLT = plot(pltargs...; pltkwargs...)
end

"""
    $SIGNATURES

Updates the series of the plot windows of `s` with `x` and `yi`.
"""
function update!(s::Scope, x, yi)
    y = collect(hcat(yi...)')
    plt = s.plt
    subplots = plt.subplots
    clear.(subplots)
    plot!(plt, x, y, xlim=(x[1], x[end]), label="")  # Plot the new series
    gui()
end

clear(sp::Plots.Subplot) = popfirst!(sp.series_list)  # Delete the old series 

""" 
    $SIGNATURES

Closes the plot window of the plot of `sink`.
"""
close(sink::Scope) = closeall()

"""
    $SIGNATURES

Opens the plot window for the plots of `sink`.
"""
open(sink::Scope) = Plots.isplotnull() ? (@warn "No current plots") : gui()


##### Pretty printing 

show(io::IO, writer::Writer) = print(io, "Writer(path:$(writer.file.path), nin:$(length(writer.input)))")
show(io::IO, printer::Printer) = print(io, "Printer(nin:$(length(printer.input)))")
show(io::IO, scp::Scope) = print(io, "Scope(nin:$(length(scp.input)))")
