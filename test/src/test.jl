include("../../src/IpyJL.jl")
using Main.IpyJL
using Test
    # Doesn't properly test now, ideally this will
    #    read the file after and test output, but I am lazy.
ipynbjl("ipynbtestbook.ipynb", "example.jl")
