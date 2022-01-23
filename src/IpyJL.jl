module IpyJL
using JSON
"""
## Cell(::Any, ::String, ::Any, ::Dict, ::Integer)
The cell type is just a Julian equivalent to the JSON data that is read in
for Jupyter cells.
### Properties
- outputs::Any - Output of the cell
- ctype::String - Cell type (code/md)
- cont::Any - The content of the cell
- meta::Dict - Meta information for a given cell.
- n::Integer - The execution position of the cell.
### Constructors
- Cell(::Dict) Constructs cells from a dictionary of cell-data.
"""
mutable struct Cell
        outputs::Any
        ctype::String
        cont::Any
        meta::Dict
        n::Integer
        function Cell(nb_cdict::Dict)
            n = 0
            outputs = ""
            try
                n = nb_cdict["execution_count"]
            catch
                n = 0
            end
            if isnothing(n)
                n = 0
            end
            try
                outputs = nb_cdict["outputs"]
            catch
                outputs = ""
            end
            new(outputs, nb_cdict["cell_type"], nb_cdict["source"],
             nb_cdict["metadata"], n)
    end
end
"""
## read_ipynb(f::String) -> Vector{Cell}
Reads an IPython notebook into a vector of cells.
### example
read_ipynb("helloworld.ipynb")
"""
function read_ipynb(f::String)
    file = open(f)
    j = JSON.parse(file)
    [Cell(cell) for cell in j["cells"]]
end
"""
## ipynbjl(ipynb_path::String, output_path::String)
Reads notebook at **ipynb_path** and then outputs as .jl Julia file to
**output_path**.
### example
ipynbjl("helloworld.ipynb", "helloworld.jl")
"""
function ipynbjl(ipynb_path::String, output_path::String)
    cells = read_ipynb(ipynb_path)
    output = cells_to_string(cells)
    open(output_path, "w") do file
           write(file, output)
    end;
end
"""
## cells_to_string(::Vector{Any}) -> ::String
Converts an array of Cell types into text.
"""
function cells_to_string(cells::Any)
    f = ""
    for cell in cells
        line = ""
        header = string("# ", cell.n, "\n")
        if cell.ctype != "code"
            line = line * string("cellmd", string(cell.n), " = \"\"\"")
            line = line * string(sep(cell.cont)) * "\"\"\"\n"
        else
            line = ""
            line = line * string(sep(cell.cont)) * "\n"
        end
        f = f * header * line
    end
    return(f)
end

"""
## sep(::Any) -> ::String
Separates and parses lines of individual cell content via an array of strings.
Returns string of concetenated text.
"""
function sep(content::Any)
    total = string()
    if length(content) == 0
        return("")
    end
    for line in content
        total = total * string(line)
    end
    total
end
export ipynbjl
end # module
