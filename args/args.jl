#!/usr/local/bin/julia


using ArgParse

function parse_commandline()
    settings = ArgParseSettings()

    @add_arg_table settings begin
        "--alpha"
            help = "begin with alpha"
        "--omega", "-o"
	    help = "end with omega"
            arg_type = Bool
            default = true
	"--end"
	    help = "end the universe"
	    action = :store_true
        "arg"
            help = "positional arguments"
            required = true
    end

    return parse_args(settings)
end

"""
./args.jl --alpha A -o true goof

"""
function main()
    parsed_args = parse_commandline()
    println("args:")
    for (arg,val) in parsed_args
	    println("  [$arg]  =>  [$val]")
    end
end

main()
