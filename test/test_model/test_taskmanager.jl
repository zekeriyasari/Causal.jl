# This file includes testset for TaskManager

@testset "TaskManager" begin 
    # Preliminaries.
    gettask(ch) = @async while true 
        val = take!(ch)
        val === NaN && break 
        val == 0 && error("The task failed.")
        println("Took val" * string(val))
    end

    # ComponentTask construction
    ch1 = Channel(0) 
    ch2 = Channel(0) 
    comptask = ComponentTask((gettask(ch1), gettask(ch2)))
    @test istaskrunning(comptask)
    put!(ch1, 1.)
    put!(ch2, 1.)
    @test istaskrunning(comptask)
    put!(ch1, NaN)
    put!(ch2, NaN)
    @test istaskdone(comptask)
    ch1 = Channel(0) 
    ch2 = Channel(0) 
    comptask = ComponentTask((gettask(ch1), gettask(ch2)))
    put!(ch1, 0.)
    put!(ch2, 0.)
    @test istaskfailed(comptask)

    # TaskManager construction 
    struct Object
        x::Int
    end 
    comps = [Object(i) for i = 1 : 5]
    chpairs = [(Channel(0), Channel(0)) for i = 1 : 5]
    comptasks = [ComponentTask((gettask(chpair[1]), gettask(chpair[2])) ) for chpair in chpairs]
    ps = Dict(zip(comps, comptasks))
    tm = TaskManager(ps)
    @test checktaskmanager(tm) === nothing  # All tasks are running, nothing is thrown.
    put!(chpairs[1][1], 0.)     # Fail the trigger task first Object
    put!(chpairs[1][2], 0.)     # Fail the output task first Object
    @test_throws Exception checktaskmanager(tm) 

end # testset
