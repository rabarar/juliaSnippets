using Printf
using Logging
io = open("log.txt", "w+")
logger = SimpleLogger(io)
global_logger(logger)


# Given Channels source and sink,
source = Channel(32)
sink = Channel(32)

struct Ctrl
	q::Channel{Bool}
	t::Float64
end

# and a function `worker` which reads items from from source, processes the item read
# and writes a result to sink,
function worker(n::Int64, done::Ctrl)
	@info(@sprintf("worker[%d] starting -> %f ms\n", n, done.t))
    while true
	if isready(done.q)
		_ = take!(done.q)
		return 42
	end

	if isready(source)
        	data = take!(source)
		#@info(@sprintf("sending %d to sink\n", data))
        	put!(sink, data*2)    # write out result
    	end

	sleep(done.t)
	yield()

    end
    @info(@sprintf("worker [%d] ending \n", n))
end

# we can schedule `n` instances of `worker` to be active concurrently.
num_workers = 10
num_jobs = 10

qc = Array{Ctrl}(undef, num_workers)
for i = 1:size(qc)[1]
	qc[i]=Ctrl(Channel{Bool}(1), convert(Int64, floor(rand()*5)))
end

@info(@sprintf("creating %d tasks\n", num_workers))
ta = Array{Task}(undef,num_workers)
for i in 1:num_workers
	ta[i] = @task(worker(i, qc[i]))

	if !istaskstarted(ta[i])
		schedule(ta[i])
	end
end

@info(@sprintf("filling pipe...\n"))
for i = 1:num_jobs

	put!(source, i)
end

@info(@sprintf("draining  pipe...\n"))
for i = 1:num_jobs
	info = take!(sink)
	@info(@sprintf("received: %d\n", info))
end

@info(@sprintf("quiting..\n"))
# quit all workers
for i=1:num_workers
	@info(@sprintf("signal worker %d to quit\n", i))
	put!(qc[i].q, true)
end

@info(@sprintf("waiting on done!\n"))
while true
        all_done = true
   
	yield()
        for i = 1:(size(ta)[1])
                if !istaskdone(ta[i])
			#@info(@sprintf("task %d isn't done\n", i))
                        all_done = false
                end
        end

        if (all_done)
		@info(@sprintf("done!\n"))
                break
        end
end 

for i in 1:num_workers
	@info(@sprintf("worker %d quit, returned result: %d\n", i, ta[i].result))
end

close(io)
