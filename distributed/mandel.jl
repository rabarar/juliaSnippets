function mandelbrot_set(cplane::Array{ComplexF64,1}, rmin,rmax,imin,imax,width,height,maxiter, epsilon)

    cartesian =  Array{Float64, 3}(undef, 3, height, width)   
    bs = 1
    total = width * height

    println("start computing pmap")
    if length(cplane) == width*height
	println("using mmap")
	zset =pmap(c->mandel(c,maxiter, total), distributed=true, batch_size=bs, cplane)
    else
	println("computing complex comprehension")
    	zset =pmap(c->mandel(c,maxiter), distributed=true, batch_size=bs, [Complex(r,i) for r in LinRange(rmin ,rmax , width) for i in LinRange(imin, imax, height)]) 
    end

    println("color zset")
    for y = 1:height, x = 1:width

        index = y + (((x-1) % width))*height
	point = zset[index]
	if point == maxiter
		point = 0
	else
		point /= convert(Float64, maxiter)

	end

 	#red_color, blue_color, green_color = 1.0, 1.0, 1.0
    	if point < epsilon
		red_color, blue_color, green_color = (1.0-point), (1.0 - point * 2), (1.0 - point * 3)
    	else
            red_color = point * 0.60
            blue_color = point * 0.80
            green_color = point * 0.35
    	end

	cartesian[1,y,x] = red_color
	cartesian[2,y,x] = blue_color
	cartesian[3,y,x] = green_color
    end

    return cartesian
end

# the mandelbrot iteration function
@everywhere count = 0
@everywhere start = time()
@everywhere delta = 0
@everywhere function mandel(c, maxiter::Int64, total::Int64)
    global count += 1
    if (count % convert(Int, total * 0.01) == 0)
	    global delta = time() - start
	    println("processed $(count*1.0/total*100.0) in $(delta) seconds")
    end
    z=0+0im
    for n = 1:maxiter
        if abs(z) > 2
            return n-1
        end
        z = z^2 + c
    end
    return maxiter
end
