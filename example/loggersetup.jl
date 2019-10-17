using Logging

function func()
    @info "In the function"
end

io = open("/tmp/log.txt", "w+")
logger = SimpleLogger(io)

with_logger(logger) do 
    global x = 0.
    for t in 1. : 10.
        global x
        x += t
    end
    func()
end
flush(io)