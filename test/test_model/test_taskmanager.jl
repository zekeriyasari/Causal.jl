# This file includes testset for TaskManager

@testset "TaskManager" begin 
    @info "Running TaskManagerTestSet ..."

    # Preliminaries.
    gettask(ch) = @async while true 
        val = take!(ch)
        val === NaN && break 
        val == 0 && error("The task failed.")
        println("Took val" * string(val))
    end

    # TaskManager construction 
    struct Mytype1
        x::Int
    end 
    comps = [Mytype1(i) for i = 1 : 5]
    chpairs = [Channel(0) for i = 1 : 5]
    comptasks = [gettask(chpair)  for chpair in chpairs]
    ps = Dict(zip(comps, comptasks))
    tm = TaskManager(ps)
    @test checktaskmanager(tm) === nothing  # All tasks are running, nothing is thrown.
    put!(chpairs[1], 0.)     # Fail the trigger task first Mytype1
    put!(chpairs[2], 0.)     # Fail the output task first Mytype1
    @test_throws Exception checktaskmanager(tm) 

    @info "Done TaskManagerTestSet."
end # testset
