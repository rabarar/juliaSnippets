using Distributed

num_feeds = 25
num_procs =  2
proc_delay = 0.050

struct Ctrl
	n::Int64
	quit::Bool
end

for i in 1:num_procs
	println("started proc $(i)")
	sshflags=`-i /Users/robert/src/julia/juliaSnippets/distributed/ms-keys`
	addprocs(["robert@mbp2018.local"]; tunnel=false, sshflags=sshflags, max_parallel=10, dir="/Users/robert/src/julia/juliaSnippets//distributed", topology=:all_to_all)
end

println("loading echo() everywhere")
@everywhere function echo()
	println("echo() started on $(myid())")
	c = Channel{Int}(10)
	@async while true
		d = take!(c)
		println("$(myid()) received $(d)")
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
		put!(x[chan], i)
		sleep(proc_delay)
	end
	break
end

println("done, cleaning up.")
println("removing $(workers())")
t = rmprocs(workers()...)
wait(t)
println("done.")
