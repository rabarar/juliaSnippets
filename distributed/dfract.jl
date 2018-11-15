using Distributed
using Images
using FileIO
using Mmap


# calculate a distributed fractal
width = 40000
height = 20000

rmin = -2.5
rmax = 1.5

imin = -1.25
imax = 1.25

iter = 500
epsilon = 0.25

mapfile = "zset-$(width)-$(height)"
s = open(mapfile)
n = read(s, Int)
println("size of zset is $n")
if n != (width * height)
	@warn("zset doesn't match dims")
	exit()
end

zset = Mmap.mmap(s, Array{ComplexF64,1}, n)
close(s)

num_procs =  0
hosts = ["robert@mbp2018.local"]

for i in 1:num_procs
	println("started proc $(i)")
	sshflags=`-i /Users/robert/src/julia/juliaSnippets/distributed/ms-keys`

	addprocs(hosts, tunnel=false, sshflags=sshflags, max_parallel=10, dir="/Users/robert/tmp", topology=:all_to_all)

end

# define mandel everywhere
include("mandel.jl")

println("starting pmap on $(workers())")
#
#generate image from results
# time measurements
print("starting...\n")
tStart=time()
#zset = Array{ComplexF64,1}(undef,0)
m_set = mandelbrot_set(zset, rmin, rmax, imin, imax, width, height, iter, epsilon)
tStop = time()
  
# write the image-file
img = colorview(RGB, m_set)
save("mandel.jpg", img)
  
print("done. took ", tStop-tStart, " seconds\n");
