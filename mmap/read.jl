using Mmap
using Printf

# Test by reading it back in
s = open("zset")   # default is read-only
n = read(s, Int)
println("size of zset is $n")
zs = Mmap.mmap(s, Array{ComplexF64,1}, n)
close(s)
f =  zs[1]
l = zs[n]
@printf("First = %f, %f  last = %f, %f\n", f.re, f.im, l.re, l.im)
