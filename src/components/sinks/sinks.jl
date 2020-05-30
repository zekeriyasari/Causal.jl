# This file constains sink tools for the objects of Jusdl.

"""
    @def_sink 

Used to define sinks
"""
macro def_sink(ex) 
    fields = quote
        trigger::TR = Inpin()
        handshake::HS = Outpin{Bool}()
        callbacks::CB = nothing
        name::Symbol = Symbol()
        id::ID = Jusdl.uuid4()
        input = Inport(1)
        buflen::Int = 64
        plugin::PL = nothing
        timebuf::TB = Buffer(buflen) 
        databuf::DB = length(input) == 1 ? Buffer(buflen) :  Buffer(length(input), buflen)
        sinkcallback::SCB = plugin === nothing ? 
            Callback(sink->ishit(databuf), sink->action(sink, outbuf(timebuf), outbuf(databuf)), true, id) :
            Callback(sink->ishit(databuf), sink->action(sink, outbuf(timebuf), plugin.process(outbuf(databuf))), true, id)
    end, [:TR, :HS, :CB, :ID, :PL, :TB, :DB, :SCB]
    _append_common_fields!(ex, fields...)
    deftype(ex)
end


##### Define sink library

# ----------------------------- Writer -------------------------------- 

@def_sink mutable struct Writer{A, FL} <: AbstractSink
    action::A = write!
    path::String = joinpath(tempdir(), string(uuid4()))
    file::FL = (f = jldopen(path, "w"); close(f); f)
end

"""
    write!(writer, td, xd)

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
    read(writer::Writer, flatten=false)

Read the contents of the file of `writer` and returns the sorted content of the file. If `flatten` is `true`, the content is also flattened.
"""
read(writer::Writer; flatten=true) = fread(writer.file.path, flatten=flatten)

"""
    fread(path::String)

Reads the content of `jld2` file and returns the sorted file content. 
"""
function fread(path::String; flatten=false)
    content = load(path)
    data = SortedDict([(eval(Meta.parse(key)), val) for (key, val) in zip(keys(content), values(content))])
    if flatten
        t = vcat(reverse.(keys(data), dims=1)...)
        if typeof(data) <: SortedDict{T1, T2, T3} where {T1, T2<:AbstractVector, T3}
            x = vcat(reverse.(values(data), dims=1)...)
        elseif typeof(data) <: SortedDict{T1, T2, T3} where {T1, T2<:AbstractMatrix, T3}
            x = collect(hcat(reverse.(values(data), dims=2)...)')
        end
        return t, x
    else
        return data
    end
end

"""
    flatten(content)

Returns a tuple of keys and values of `content`.
"""
flatten(content) = (collect(vcat(keys(content)...)), collect(vcat(values(content)...)))

"""
    mv(writer::Writer, dst; force::Bool=false)

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
    cp(writer::Writer, dst; force=false, follow_symlinks=false)

Copies the file of `writer` to `dst`. If `force` is `true`, the if `dst` is not a valid path, it is forced to be constructed. If `follow_symlinks` is `true`, symbolinks are followed.

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
    open(writer::Writer)

Opens `writer` by opening the its `file` in  `read/write` mode. When `writer` is not openned, it is not possible to write data in `writer`. See also [`close(writer::Writer)`](@ref)
"""
open(writer::Writer) = (writer.file = jldopen(writer.file.path, "a"); writer)

"""
    close(writer::Writer)

Closes `writer` by closing its `file`. When `writer` is closed, it is not possible to write data in `writer`. See also [`open(writer::Writer)`](@ref)
"""
close(writer::Writer) =  (close(writer.file); writer)


# ----------------------------- Printer --------------------------------

@def_sink mutable struct Printer{A} <: AbstractSink 
    action::A = print 
end

import Base.print

"""
    print(printer::Printer, td, xd)

Prints `xd` corresponding to `xd` to the console.
"""
print(printer::Printer, td, xd) = print("For time", "[", td[1], " ... ", td[end], "]", " => ", xd, "\n")

"""
    open(printer::Printer)

Does nothing. Just a common interface function ot `AbstractSink` interface.
"""
open(printer::Printer) = printer

"""
    close(printer::Printer)

Does nothing. Just a common interface function ot `AbstractSink` interface.
"""
close(printer::Printer) =  printer

# ----------------------------- Scope --------------------------------

@def_sink mutable struct Scope{A, PA, PK, PLT} <: AbstractSink
    action::A = update!
    pltargs::PA = () 
    pltkwargs::PK = NamedTuple()
    plt::PLT = plot(pltargs...; pltkwargs...)
end

"""
    update!(s::Scope, x, yi)

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
    close(sink::Scope)

Closes the plot window of the plot of `sink`.
"""
close(sink::Scope) = closeall()

"""
    open(sink::Scope)

Opens the plot window for the plots of `sink`.
"""
open(sink::Scope) = Plots.isplotnull() ? (@warn "No current plots") : gui()


##### Pretty printing 

show(io::IO, writer::Writer) = print(io, "Writer(path:$(writer.file.path), nin:$(length(writer.input)))")
show(io::IO, printer::Printer) = print(io, "Printer(nin:$(length(printer.input)))")
show(io::IO, scp::Scope) = print(io, "Scope(nin:$(length(scp.input)))")

##### Deprecated

# function unfasten!(sink::AbstractSink)
#     callbacks = sink.callbacks
#     sid = sink.id
#     typeof(callbacks) <: AbstractVector && disable!(callbacks[callback.id == sid for callback in callbacks])
#     typeof(callbacks) <: Callback && disable!(callbacks)
#     sink
# end
