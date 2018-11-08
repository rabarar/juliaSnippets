using Printf
function foo(n::Int64, q::Channel{Bool})
	while true
		@printf("starting foo\n")
		if isready(q)
			@printf("quitting?\n")
			_ = take!(q)
			@printf("task %d ended\n", n)
			return (42, "ellow")
		end
		yield()
	end
end

n = 10
@printf("creating %d tasks\n", n)
ta = Array{Task}(undef,n)
qa = Array{Channel{Bool}}(undef,n)
for i in 1:(size(ta)[1])
	qa[i] = Channel{Bool}(1)
	ta[i] = @task foo(i, qa[i])
	if !istaskstarted(ta[i])
		schedule(ta[i])
	end
    	println("create foo")
end

# send quit
for i in 1:(size(qa)[1])
	@printf("sending quit to %d\n", i)
	put!(qa[i], true)
end

@printf("waiting on done!\n")
while true
	all_done = true
	
	for i = 1:(size(ta)[1])
		if !istaskdone(ta[i])
#			@printf("still waiting on %d\n", i)
			all_done = false
		else

			res_n, res_s = ta[i].result
			@printf("result for task %d was %d\n", i, res_n)
		end
	end
	if (all_done)
		sleep(2)
		@printf("done!\n")
		break
	end
end
