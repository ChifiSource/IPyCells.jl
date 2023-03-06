"""
Created in April, 2022 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
by team
[odd-data](https://github.com/orgs/ChifiSource/teams/odd-data)
This software is MIT-licensed.
### IPy.jl
IPy.jl is a consistent cell format amongst three different cell file-types. The
package combines .ipynb, .jl, and .jl pluto files together into one easy to
use module.
"""
module IPy
import Base: string, read, getindex
using JSON
using Random

__precompile__()


abstract type AbstractCell end

"""
## Cell(::Any, ::String, ::Any, ::Dict, ::Integer)
The cell type is just a Julian equivalent to the JSON data that is read in
for Jupyter cells.
### fields
- id::String
- outputs::Any - Output of the cell
- ctype::String - Cell type (code/md)
- cont::Any - The content of the cell
- n::Integer - The execution position of the cell.
### Constructors
- Cell(n::Int64, type::String, content::String, outputs::Any = "") Constructs cells from a dictionary of cell-data.
"""
mutable struct Cell{T} <: AbstractCell
        id::String
        type::String
        source::String
        outputs::Any
        n::Integer
        function Cell(n::Int64, type::String, content::String,
                outputs::Any = ""; id::String = "")
                if id == ""
                        Random.seed!(rand(1:100000))
                        id = randstring(10)::String
                end
            new{Symbol(type)}(id, type, content, outputs, n)::Cell{<:Any}
        end
end

function string(cell::Cell{:code})
        (cell.source * "\n#==output[$(cell.type)]\n$(string(cell.outputs))\n==#\n")::String
end

function string(cell::Cell{:md})
        "\"\"\"\n$(cell.source)\n\"\"\"\n"::String
end

function string(cell::Cell{:doc})
        "\"\"\"\n$(cell.source)\n\"\"\""
end

function getindex(v::Vector{Cell{<:Any}}, s::String)
        v[findall(c -> c.id == s, v)[1]]
end

include("IPyRW.jl")

export ipynbjl
end # module
