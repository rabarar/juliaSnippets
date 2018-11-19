using Mmap

rmin = -2.50
rmax = 2.50
imin = -1.5
imax = 1.5

height = 200_000
width = 400_000

tStart=time()
cset= [ComplexF64(r,i) for r in LinRange(rmin ,rmax , width) for i in LinRange(imin, imax, height)]
tStop=time()
print("done. took ", tStop-tStart, " seconds\n");

# Create a file for mmapping
s = open("zset-$(width)-$(height).bin", "w+")
write(s, size(cset,1))
# Now write the data
write(s, cset)
close(s)

# Test by reading it back in
s = open("zset-$(width)-$(height).bin")   # default is read-only
n = read(s, Int)
println("size of zset is $n")
zs = Mmap.mmap(s, Array{ComplexF64,1}, n)
close(s)


