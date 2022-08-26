
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
            ctype::String = nb_cdict["cell_type"]
            new{Symbol(ctype)}(nb_cdict["cell_type"], nb_cdict["source"],
            nb_cdict["outputs"], n)
        end
end

function write(io::IO, c::Cell{:})

end
