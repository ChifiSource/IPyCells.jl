using IPyCells
using Test

@testset "ipy cells" verbose = true begin
    @__DIR__
    @testset "cells" begin

    end
    @testset "reading" verbose = true begin
        @testset "julia" begin

        end
        @testset "olive" begin

        end
        @testset "pluto" begin

        end
        @testset "ipython" begin

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