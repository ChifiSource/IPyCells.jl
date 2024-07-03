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
module IPyCells
import Base: string, read, getindex
using JSON
using Random

__precompile__()

"""
### abstract type AbstractCell
An abstracted cell type, primarily used for the IPy.Cell constructor.
##### Consistencies
- id::String
- source::String
- outputs::Any
- n::Int64
"""
abstract type AbstractCell end

"""
## Cell(::Any, ::String, ::Any, ::Dict, ::Integer) <: AbstractCell
The cell type is just a Julian equivalent to the JSON data that is read in
for Jupyter cells.
### fields
- id::String
- outputs::Any - Output of the cell
- type::String - Cell type (code/md)
- source::String - The content of the cell
- n::Integer - The execution position of the cell.
### Constructors
- Cell(n::Int64, type::String, content::String, outputs::Any = "") Constructs cells from a dictionary of cell-data.
"""
mutable struct Cell{T <: Any} <: AbstractCell
    id::String
    source::String
    outputs::Any
    function Cell{T}(source::String = "", outputs::Any = ""; id::String = "") where {T <: Any}
        if id == ""
            Random.seed!(rand(1:100000))
            id = randstring(5)
        end
        new{Symbol(type)}(id, content, outputs)::Cell{type}
    end
end

"""
## string(cell::Cell{<:Any}) -> ::String
Converts a cell to a `String`, used by `IPy.save` to write different cell types.
### example
```julia
cells = read_plto("myfile.jl")
```
"""
function string(cell::Cell{<:Any})
    celltype::String = string(typeof(cell).parameters[1])
    return(*(cell.source, "\n#==output[$celltype]\n$(string(cell.outputs))\n==#\n#==|||==#\n"))::String
end

function string(cell::Cell{:markdown})
    "\"\"\"$(cell.source)\"\"\"\n#==|||==#\n"::String
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
