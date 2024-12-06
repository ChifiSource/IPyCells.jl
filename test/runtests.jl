using IPyCells
using IPyCells: Cell
using Test
testbooks::String = "testbooks/"

@testset "ipy cells" verbose = true begin
    @testset "cells" begin
        newcell = Cell{:code}()
        @test typeof(newcell) == Cell{:code}
        @test length(newcell.id) > 2
        other_cell = Cell("markdown", "# hello")
        @test typeof(other_cell) == Cell{:markdown}
        @test other_cell.source == "# hello"
        cell_id = newcell.id
        vs = [newcell, other_cell]
        @test typeof(vs[cell_id]) == Cell{:code}
        newcell.source = "5 + 5"
        t = string(vs[cell_id])
        @test contains(t, "5 + 5") 
    end
    @testset "reading" verbose = true begin
        @testset "julia" begin
            newcells = IPyCells.read_jl(testbooks * "raw_nb.jl")
            @test typeof(newcells[1]) == Cell{:code}
            @test contains(newcells[1].source, """function my_function(x::Int64)""")
            @test contains(newcells[1].source, """end""")
        end
        @testset "olive" begin
            newcells = IPyCells.read_olive(testbooks * "olive_nb.jl")
            @test typeof(newcells[1]) == Cell{:code}
            @test typeof(newcells[2]) == Cell{:markdown}
            @test contains(newcells[1].source, """function my_function(x::Int64)""")
            @test contains(newcells[1].source, """end""")
            @test contains(newcells[2].source, """# hello""")
        end
        @testset "pluto" begin
            newcells = IPyCells.read_pluto(testbooks * "pluto_nb.jl")
            @test typeof(newcells[1]) == Cell{:code}
            @test typeof(newcells[2]) == Cell{:markdown}
            @test contains(newcells[1].source, """function my_function(x::Int64)""")
            @test contains(newcells[1].source, """end""")
            @test contains(newcells[2].source, """# hello""")
        end
        @testset "ipython" begin
            newcells = IPyCells.read_ipynb(testbooks * "ip_nb.ipynb")
            @test typeof(newcells[1]) == Cell{:code}
            @test typeof(newcells[2]) == Cell{:markdown}
            @test contains(newcells[1].source, """function my_function(x::Int64)""")
            @test contains(newcells[1].source, """end""")
            @test contains(newcells[2].source, """# hello""")
        end
    end
    @testset "writing" verbose = true begin
        @testset "olive" begin

        end
        @testset "ipython" begin

        end
    end
    @testset "reread" verbose = true begin
        @testset "olive" begin

        end
        @testset "ipython" begin

        end
    end
end