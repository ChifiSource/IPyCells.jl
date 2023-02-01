
"""
## Cell(::Any, ::String, ::Any, ::Dict, ::Integer)
The cell type is just a Julian equivalent to the JSON data that is read in
for Jupyter cells.
### fields
- outputs::Any - Output of the cell
- ctype::String - Cell type (code/md)
- cont::Any - The content of the cell
- n::Integer - The execution position of the cell.
### Constructors
- Cell(::Dict) Constructs cells from a dictionary of cell-data.
"""
mutable struct Cell{T}
        id::String
        type::String
        source::String
        outputs::Any
        n::Integer
        function Cell(n::Int64, type::String, content::String,
                outputs::Any = ""; id::String = "")
            new{Symbol(type)}(id, type, content, outputs, n)::Cell{<:Any}
        end
end

function string(cell::Cell{:code})
        cell.source * "\n#==output$(cell.n)\n$(cell.outputs)\n==#\n"
end

function string(cell::Cell{:md})
        "\"\"\"\n$(cell.source)\n\"\"\""
end

function getindex(v::Vector{Cell}, s::String)
        v[findall(c::Cell -> c.id == s)]
end
