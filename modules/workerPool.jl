module WorkerPool

using Printf
using Logging

export setLoggerFile, pool
 
struct WorkerState
	name::String
	job_count::Int64
	errors::Int64
end

struct WorkPkg{T}
	name::String
	work::T
end

struct Ctrl
	q::Channel{Bool}
	t::Float64
end


show(io::IO, a::WorkPkg) = print(io, "WorkPkg $(a.name)")

function setLoggerFile(fn::String)
	io = open(fn, "w+")
	logger = SimpleLogger(io)
	global_logger(logger)
end

mutable struct Pool{T,E}
	num_workers::Int64
	channel_size::Int64
	workercb::Function ## function worker(work::T, result::E, done::Ctrl) where {T <: Any, E <: Any}

	source::Channel{WorkPkg{T}}
	sink::Channel{WorkPkg{E}}
	qc::Array{Ctrl}
	ta::Array{Task}
	started::Bool

	Pool{T,E}(num_workers, channel_size, workercb) where {T <: Any, E <: Any} = new(num_workers, channel_size, workercb, Channel{WorkPkg{T}}(channel_size), Channel{WorkPkg{E}}(channel_size), Array{Ctrl}(undef, num_workers), Array{Task}(undef, num_workers), false)

end

alreadyStartedException = ErrorException("Pool Already Started");
notStartedException = ErrorException("Pool NotStarted");

function startPool(p::Pool)

	if p.started
		throw(alreadyStartedException)
	else
		p.started = true
	end

	for i = 1:size(p.qc)[1]
		p.qc[i]=Ctrl(Channel{Bool}(1), convert(Int64, floor(rand()*5)))
	end

	@info(@sprintf("creating %d tasks\n", p.num_workers))
	for i in 1:p.num_workers
		ws = WorkerState(@sprintf("worker-%d",i), 0,0)
		p.ta[i] = @task(worker(ws, p.source, p.sink, p.workercb, p.qc[i]))

		if !istaskstarted(p.ta[i])
			schedule(p.ta[i])
		end
	end

end

# and a function `worker` which reads items from from source, processes the item read
# and writes a result to sink,
function worker(ws::WorkerState, source::Channel{WorkPkg{T}}, sink::Channel{WorkPkg{E}}, cb::Function, done::Ctrl) where {T <: Any, E <: Any}
    @info(@sprintf("worker[%s] startings\n", ws.name))
    while true
	if isready(done.q)
		_ = take!(done.q)
    		@info(@sprintf("worker [%s] ending \n", ws.name))
		return 42
	end

	if isready(source)
        	data = take!(source)
		@info(@sprintf("Worker[%s] received [%s] from source\n", ws.name, data.name))
		res = cb(data.work)
		put!(sink, WorkPkg{E}(@sprintf("%s-processed", data.name), res))
		@info(@sprintf("Worker[%s] sent [%s] to sink\n", ws.name, data.name))
    	end

	sleep(done.t)
	yield()

    end
end


function push(p::Pool, w::WorkPkg{T}) where {T <: Any}

	if !p.started
		throw(notStartedException)
	end
	@info(@sprintf("sending job: %s\n", w.name))
	put!(p.source, w)
end

function pop(p::Pool)

	if !p.started
		throw(notStartedException)
	end

	if isready(p.sink)
		info = take!(p.sink)
		@info(@sprintf("received\n"))
		return info
	else
		@info(@sprintf("nothing to receive\n"))
		return nothing
	end
end

function shutdownPool(p::Pool)

	if !p.started
		throw(notStartedException)
	end

	for i=1:p.num_workers
		@info(@sprintf("signal worker %d to quit\n", i))
		put!(p.qc[i].q, true)
	end

	@info(@sprintf("waiting on done!\n"))
	while true
		all_done = true
	   
		yield()
		for i = 1:(size(p.ta)[1])
			if !istaskdone(p.ta[i])
				#@info(@sprintf("task %d isn't done\n", i))
				all_done = false
			end
		end

		if (all_done)
			@info(@sprintf("done!\n"))
			break
		end
	end 
	p.started = false
	return

end

function results(p::Pool)
	for i in 1:p.num_workers
		@info(@sprintf("worker %d quit, returned result: %d\n", i, p.ta[i].result))
	end
end

end
