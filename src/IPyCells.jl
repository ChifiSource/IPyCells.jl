
"""
## Cell(::Any, ::String, ::Any, ::Dict, ::Integer)
The cell type is just a Julian equivalent to the JSON data that is read in
for Jupyter cells.
### feilds
- outputs::Any - Output of the cell
- ctype::String - Cell type (code/md)
- cont::Any - The content of the cell
- n::Integer - The execution position of the cell.
### Constructors
- Cell(::Dict) Constructs cells from a dictionary of cell-data.
"""
mutable struct Cell{T}
        ctype::String
        source::String
        outputs::Any
        n::Integer
        function Cell(n::Int64, type::String, content::String, outputs::Any)
            new{Symbol(ctype)}(type, content, outputs, n)
        end
end

function string(cell::Cell{:code})
        cell.source * "\n#==output$(cell.n)\n$(cell.outputs)\n==#\n"
end

function string(cell::Cell{:md})
        "\"\"\"\n$(cell.source)\n\"\"\""
end
