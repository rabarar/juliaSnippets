using Distributed

num_feeds = 50
num_procs =  2
proc_delay = 0.01


for i in 1:num_procs
	println("started proc $(i)")
	sshflags=`-i /Users/robert/src/julia/juliaSnippets/distributed/ms-keys`
	addprocs(["robert@mbp2018.local"]; tunnel=false, sshflags=sshflags, max_parallel=10, dir="/Users/robert/src/julia/juliaSnippets//distributed", topology=:all_to_all)
end

println("defining struct everywhere")
@everywhere struct Ctrl
	n::Int64
	quit::Bool
end

println("loading echo() everywhere")
@everywhere function echo()
	println("echo() started on $(myid())")
	c = Channel{Ctrl}(10)
	@async while true
		d = take!(c)
		if d.quit == true
			println("$(myid()) received quit, exitting, closing channel")
			close(c)
			return
		end
		println("$(myid()) received $(d.n)")
	end
	println("echo() on $(myid()) returning RemoteChannel")
	return c
end


# create an array of remote channels
x = Array{RemoteChannel,1}(undef, num_procs + 1)

# create a remote Int channel in pid 2 
for i in 1:num_procs + 1
	x[i]= RemoteChannel(echo, i)
end


println("there are $(procs())")
for i in procs()
	println("starting echo on $(i)")
	remotecall(echo, i)
end

println("feeding...")
while true
	for i=1:num_feeds
		chan = 1 + (i % size(x)[1])
		println("sending value $(i) to $(chan)")
		try
			if (i % 13 == 0)
				put!(x[chan], Ctrl(i, true))
			else
				put!(x[chan], Ctrl(i, false))
			end
		catch e
			if isa(e, InvalidStateException)
				println("channel $(i) is closed, nothing sent")
				deleteat!(x,chan)
			end
		end
		sleep(proc_delay)
	end
	break
end

println("done, cleaning up.")
println("removing $(workers())")
t = rmprocs(workers()...)
wait(t)
println("done.")
