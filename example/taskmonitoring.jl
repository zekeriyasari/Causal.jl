
function taker5(ch, chr)
    while true 
        val = take!(ch)
        @info "In $(objectid(ch)). Took $val"
        val === missing && (@info "Breaking out of $(objectid(ch))"; break)
        sleep(5)
        @info "Slept 5 seconds in $(objectid(ch)) for $val"
        put!(chr, true)
    end
end

function taker20(ch, chr)
    while true 
        val = take!(ch)
        @info "In $(objectid(ch)). Took $val"
        val === missing && (@info "Breaking out of $(objectid(ch))"; break)
        sleep(20)
        @info "Slept 20 seconds in $(objectid(ch)) for $val"
        put!(chr, true)
    end
end

chn1 = Channel(0)
chn2 = Channel(0)
chr1 = Channel(0)
chr2 = Channel(0)
@info objectid(chn1)
@info objectid(chn2)
t1 = @async taker5(chn1, chr1)
t2 = @async taker20(chn2, chr2)
for t in 1. : 2.
    foreach(chn -> put!(chn, t), [chn1, chn2])
    foreach(take!, [chr1, chr2])
end
@info "Out of loop"
# foreach(chn -> put!(chn, missing), [chn1, chn2])