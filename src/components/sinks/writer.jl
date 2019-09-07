# This file includes the writers


mutable struct Writer{DB, TB, P, F} <: AbstractSink
    @generic_sink_fields
    file::F
end
function Writer(input; buflen=64, plugin=nothing, path="/tmp/"*string(uuid4()))
    # Construct the file
    endswith(path, ".jld2") || (path *= ".jld2")
    file = isfile(path) ? error("$path exists") :  jldopen(path, "w")
    close(file)     # Close file so that the file can be sent to remote Julia processes

    # Construct the buffers
    timebuf = Buffer(buflen)
    databuf = length(input) == 1 ? Buffer(buflen) : Buffer(buflen, length(input))
    trigger = Link()
    addplugin(Writer(input, databuf, timebuf, plugin, trigger, Callback[], uuid4(), file), write!)
end

##### Writer reading and writing
write!(writer::Writer, td, xd) = fwrite(writer.file, td, xd)
fwrite(file, td, xd) = file[string(td)] = xd

read(writer::Writer) = fread(writer.file.path)
function fread(path::String)
    content = load(path)
    SortedDict([(eval(Meta.parse(key)), val) for (key, val) in zip(keys(content), values(content))])
end

flatten(content) = (collect(vcat(keys(content)...)), collect(vcat(values(content)...)))

##### Writer controls
function mv(writer::Writer, dst; force::Bool=false)
    name = writer.name
    dstpath = joinpath(dst, name)
    srcpath = writer.file.path
    mv(srcpath, dstpath, force=force)
    writer.file.path = dstpath  # Update the file path
    writer
end

function cp(writer::Writer, dst, force=false, follow_symlinks=false)
    name = writer.name
    dstpath = joinpath(dst, name)
    cp(writer.file.path, dstpath, force=force, follow_symlinks=follow_symlinks)
    writer
end

open(writer::Writer) = (writer.file = jldopen(writer.file.path, "a"); writer)
close(writer::Writer) =  (close(writer.file); writer)
