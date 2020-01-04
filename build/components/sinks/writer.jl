# This file includes the writers


mutable struct Writer{IB, DB, TB, P, T, H, F} <: AbstractSink
    @generic_sink_fields
    file::F
    function Writer(input::Bus{Union{Missing, T}}; buflen=64, plugin=nothing, path=joinpath(tempdir(), string(uuid4()))) where T 
        # Construct the file
        endswith(path, ".jld2") || (path *= ".jld2")
        file = isfile(path) ? error("$path exists") :  jldopen(path, "w")
        close(file)     # Close file so that the file can be sent to remote Julia processes

        # Construct the buffers
        timebuf = Buffer(buflen)
        databuf = Buffer(Vector{T}, buflen)
        trigger = Link()
        handshake = Link{Bool}()
        addplugin(
            new{typeof(input), typeof(databuf), typeof(timebuf), typeof(plugin), typeof(trigger), typeof(handshake), 
            typeof(file)}(input, databuf, timebuf, plugin, trigger, handshake, Callback[], uuid4(), file), write!)
    end
end

show(io::IO, writer::Writer) = print(io, "Writer(path:$(writer.file.path), nin:$(length(writer.input)))")

##### Writer reading and writing
write!(writer::Writer, td, xd) = fwrite(writer.file, td, xd)
fwrite(file, td, xd) = file[string(td)] = xd

function read(writer::Writer; flatten=false) 
    content = fread(writer.file.path)
    if flatten
        t = vcat(collect(keys(content))...)
        x = collect(hcat(vcat(collect(values(content))...)...)')
        return t, x
    else
        return content
    end
end

function fread(path::String)
    content = load(path)
    SortedDict([(eval(Meta.parse(key)), val) for (key, val) in zip(keys(content), values(content))])
end

flatten(content) = (collect(vcat(keys(content)...)), collect(vcat(values(content)...)))

##### Writer controls
function mv(writer::Writer, dst; force::Bool=false)
    id = writer.id
    dstpath = joinpath(dst, string(id))
    srcpath = writer.file.path
    mv(srcpath, dstpath, force=force)
    writer.file.path = dstpath  # Update the file path
    writer
end

function cp(writer::Writer, dst, force=false, follow_symlinks=false)
    id = writer.id
    dstpath = joinpath(dst, string(id))
    cp(writer.file.path, dstpath, force=force, follow_symlinks=follow_symlinks)
    writer
end

open(writer::Writer) = (writer.file = jldopen(writer.file.path, "a"); writer)
close(writer::Writer) =  (close(writer.file); writer)
