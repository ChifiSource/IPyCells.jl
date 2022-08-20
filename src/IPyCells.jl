
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
mutable struct Cell
        cont::Any
        outputs::Any
        ctype::String
        n::Integer
        ctref::Dict
        function Cell(nb_cdict::Dict;
            ctref = Dict("markdown" => create_markdown,
                    "code" => create_code,
                    "hidden" => create_hidden))
            n = 0
            outputs = ""
            new(outputs, nb_cdict["cell_type"], nb_cdict["source"], n)
        end
end

function create_markdown(content::String, n::Integer ... = 1)
        content = sep(content)
        if length(count) != 1
                        #==
                # If someone for some reason provides too many arguments to N,
                #    (Because it is an optional argument) We will pass all
                arguments
                All the time, that way if we ever miss any and the adder of the
                function can reference
                ==#
                n = [count = count for count in count][1]::Array{Integer}
        end
        for line in content
                line = line * string("cellmd$n = md\"\"\"")
                line = line * string(content) * "\"\"\"\n"
        end
        return(content)
end

function create_code(content::String)

end


function create_hidden(content::String, n::Any ...)

end
