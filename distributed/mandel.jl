function mandelbrot_set(rmin,rmax,imin,imax,width,height,maxiter)

    cartesian =  Array{Float64, 3}(undef, 3, height, width)   
    println("start computing pmap")
    zset =pmap(c->mandel(c,maxiter), distributed=true, batch_size=1000, [Complex(r,i) for r in LinRange(rmin ,rmax , width) for i in LinRange(imin, imax, height)]) 

    println("color zset")
    for y = 1:height, x = 1:width

        index = y + (((x-1) % width))*height
	point = zset[index]
	if point == maxiter
		point = 0
	else
		point /= convert(Float64, maxiter)

	end

 	red_color, blue_color, green_color = 1.0, 1.0, 1.0
    	if point < 0.01
            red_color, blue_color, green_color = 1.0, 1.0, 1.0
    	else
            red_color = point * 0.80
            blue_color = point * 0.80
            green_color = point * 0.15
    	end

	cartesian[1,y,x] = red_color
	cartesian[2,y,x] = blue_color
	cartesian[3,y,x] = green_color
    end

    return cartesian
end

# the mandelbrot iteration function
@everywhere function mandel(c, maxiter::Int64)
    z=0+0im
    for n = 1:maxiter
        if abs(z) > 2
            return n-1
        end
        z = z^2 + c
    end
    return maxiter
end
