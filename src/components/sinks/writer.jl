# This file includes Writer type.

export Writer, write!, fwrite!, fread

"""
    $(TYPEDEF) 

`Writer` whose input bus is `input`. `buflen` is the length of the internal buffer of `Writer`. If not nothing, `plugin` is used to processes the incomming data. `path` determines the path of the file of `Writer`.

# Fields

    $(TYPEDFIELDS)

!!! note 
    The type of `file` of `Writer` is [`JLD2`](https://github.com/JuliaIO/JLD2.jl).    

!!! warning 
    When initialized, the `file` of `Writer` is closed. See [`open(writer::Writer)`](@ref) and [`close(writer::Writer)`](@ref).
"""
@def_sink mutable struct Writer{A, FL} <: AbstractSink
    action::A = write!
    path::String = joinpath(tempdir(), string(uuid4()))
    file::FL = (f = jldopen(path, "w"); close(f); f)
end

show(io::IO, writer::Writer) = print(io, "Writer(path:$(writer.file.path), nin:$(length(writer.input)))")

"""
    $(SIGNATURES)

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

"""
    $(SIGNATURES)

Writes `xd` corresponding to `td` to the `file`.
"""
fwrite!(file, td, xd) = file[string(td)] = xd

"""
    $(SIGNATURES)

Read the contents of the file of `writer` and returns the sorted content of the file. If `flatten` is `true`, the content is also flattened.
"""
read(writer::Writer; flatten=true) = fread(writer.file.path, flatten=flatten)

"""
    $(SIGNATURES)

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

flatten(content) = (collect(vcat(keys(content)...)), collect(vcat(values(content)...)))

"""
    $(SIGNATURES)

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
    $(SIGNATURES)

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
    $(SIGNATURES)

Opens `writer` by opening the its `file` in  `read/write` mode. When `writer` is not openned, it is not possible to write data in `writer`. See also [`close(writer::Writer)`](@ref)
"""
open(writer::Writer) = (writer.file = jldopen(writer.file.path, "a"); writer)

"""
    $(SIGNATURES)

Closes `writer` by closing its `file`. When `writer` is closed, it is not possible to write data in `writer`. See also [`open(writer::Writer)`](@ref)
"""
close(writer::Writer) =  (close(writer.file); writer)
