# This file constains sink tools for the objects of Jusdl.

function fasten(plugin, actionfunc, timebuf, databuf, callbacks, id)
    condition(sink) = isfull(sink.databuf) 
    if plugin === nothing
        action = sink -> actionfunc(sink, snapshot(timebuf), snapshot(databuf))
    else
        action = sink -> actionfunc(sink, snapshot(timebuf), process(plugin, snapshot(databuf)))
    end
    callback = Callback(condition, action)
    callback.id = id
    callbacks = callbacks === nothing ? 
        callback : (callbacks isa AbstractVector ? push!(callbacks,callback) : [callbacks, callback])
    callbacks
end

function unfasten(sink::AbstractSink)
    callbacks = sink.callbacks
    sid = sink.id
    typeof(callbacks) <: AbstractVector && disable!(callbacks[callback.id == sid for callback in callbacks])
    typeof(callbacks) <: Callback && disable!(callbacks)
end
