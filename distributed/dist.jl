using Distributed 

println("Hello from Julia")
addprocs(2)
np = nprocs()
println("Number of processes: $np")

for i in workers()
    host, pid = fetch(@spawnat i (gethostname(), getpid()))
    println("Hello from process $(pid) on host $(host)!")
end

tasks = randn(np * 5)

@everywhere begin
    function foo(x)
        return x * 4
    end
end

results = pmap(foo, tasks)

println(results)

for i in workers()
    rmprocs(i)
end

np = nprocs()
println("Deleted all workers, Number of processes: $np")
