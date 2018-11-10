using Printf

include("workerPool.jl")

function cb(x::Int64)::Float64
        return 2.0
end

p = WorkerPool.Pool{Int64,Float64}(10,10,cb)

WorkerPool.startPool(p)
WorkerPool.push(p, WorkerPool.WorkPkg{Int}("job1", 1))
sleep(2)
d = WorkerPool.pop(p)
@info(@sprintf("job[%s] received %f\n", d.name, d.work))
WorkerPool.shutdownPool(p)
