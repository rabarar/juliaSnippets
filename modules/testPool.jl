using Printf

include("workerPool.jl")

function cb(x::Int64)::Float64
        return 2.0
end

struct Box
	name::String
end

struct Results
	name::String
end

function cb_p2(x::Box)::Results
	Results(@sprintf("results-%s", Box.name))
end


p = WorkPool.Pool{Int64,Float64}(10,10,cb)

p2 = WorkPool.Pool{Box,Results}(10,10,cb_p2)

WorkPool.startPool(p)
WorkPool.push(p, WorkPool.WorkPkg{Int}("job1", 1))
sleep(2)
d = WorkPool.pop(p)
@info(@sprintf("job[%s] received %f\n", d.name, d.work))
WorkPool.shutdownPool(p)


WorkPool.startPool(p2)
WorkPool.push(p2, WorkPool.WorkPkg{Box}("foo", Box("box")))
sleep(2)
d = WorkPool.pop(p2)
@info(@sprintf("job[%s] received %s\n", d.name, d.work.name))
WorkPool.push(p2, WorkPool.WorkPkg{Box}("foo", Box("box")))
sleep(2)
d = WorkPool.pop(p2)
@info(@sprintf("job[%s] received %s\n", d.name, d.work.name))
WorkPool.push(p2, WorkPool.WorkPkg{Box}("foo", Box("box")))
sleep(2)
d = WorkPool.pop(p2)
@info(@sprintf("job[%s] received %s\n", d.name, d.work.name))
WorkPool.shutdownPool(p2)
WorkPool.getFinalState(p2)
