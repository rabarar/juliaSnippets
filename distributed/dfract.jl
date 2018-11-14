using Distributed
using Images
using FileIO


# calculate a distributed fractal
height = 1000
width = 2000

rmin = -2.5
rmax = 1.5

imin = -1.25
imax = 1.25

iter = 80

num_procs =  2

for i in 1:num_procs
	println("started proc $(i)")
	sshflags=`-i /Users/robert/src/julia/juliaSnippets/distributed/ms-keys`

	addprocs(["robert@mbp2018.local"];
		 tunnel=false,
		 sshflags=sshflags,
		 max_parallel=10,
		 dir="/Users/robert/src/julia/juliaSnippets//distributed",
		 topology=:all_to_all)
end

# define mandel everywhere
include("mandel.jl")

println("starting pmap on $(workers())")
#
#generate image from results
# time measurements
print("starting...\n")
tStart=time()
m_set = mandelbrot_set(rmin, rmax, imin, imax, width, height, iter)
tStop = time()
  
# write the image-file
img = colorview(RGB, m_set)
save("mandel.jpg", img)
  
print("done. took ", tStop-tStart, " seconds\n");
