# This file includes testset for TaskManager

# NOTE: Do not mutate task state !. Use the methodology below: 
# l = Link()
# t = @async while true 
#     val = take!(l)
#     val === NaN && break
#     val == 0. && error("This error")
#     @show val 
# end
# put!(l, 1.)   # To continue to the task.
# put!(l, 0.)   # To fail task.
# put!(l, NaN)  # To terminate task.

# @testset "TaskManager" begin 
#     # ComponentTask construction 
#     t1 = @async sleep(5)
#     t2 = @async sleep(5) 
#     t3 = @async sleep(5) 
#     t4 = @async sleep(5)
#     comptask = ComponentTask([(t1, t2), (t3, t4)])
#     comptask = ComponentTask((t1, t2))
#     @test !istaskdone(comptask)
#     foreach(wait, [comptask.triggertask, comptask.outputtask])
#     @test istaskdone(comptask)

#     t1 = @async sleep(5)
#     t2 = @async sleep(5)
#     comptask = ComponentTask((t1, t2))
#     @test istaskrunning(comptask)
#     foreach(wait, [comptask.triggertask, comptask.outputtask])
#     @test istaskdone(comptask)
#     t1 = @async nothing
#     t2 = @async nothing
#     comptask = ComponentTask((t1, t2))
#     @test !istaskfailed(comptask)
#     t1.state = :failed
#     t2.state = :failed
#     @test istaskfailed(comptask)

#     # TaskManager construction 
#     struct Object
#         x::Int
#     end 
#     comps = [Object(i) for i = 1 : 5]
#     tasks = [@async(sleep(5)) for i = 1 : 5] 
#     ps = Dict(zip(comps, tasks))
#     tm = TaskManager(ps)
#     foreach(t -> t.state = :failed, tasks)
#     @test_throws Exception checktaskmanager(tm)
# end # testset