using JSON

function plto_cell_lines(uri::String)
    # We need file lines for each cell UUID
    cellpos = Dict()
    first = 0
    ccount = 0
    for (count, line) in enumerate(readlines(uri))
        if occursin("# ╔═╡", line)
            if first == 0
                first = count
            else
                ccount += 1
                push!(cellpos, ccount => first:count - 1)
                first = count
            end
        end
    end
    return(cellpos)
end

function read_plto(uri::String)
    cells::Vector{Cell} = []
    cellpos = plto_cell_lines(uri)
    x = readlines(uri)
    for (n, cell) in enumerate(values(cellpos))
        unprocessed_uuid = x[cell[1]]
        text_data = x[cell[2:end]]
        cl = Cell(n, "code", text_data)
        push!(cells, cl)
    end
    return(cells)
end

function read_jl(uri::String)
    readin = read(uri, String)
    if contains("═╡", readin)
        return(read_plto(uri))
    end
end

"""
## cells_to_string(::Vector{Any}) -> ::String
Converts an array of Cell types into text.
"""
function save_jl(cells::Vector{AbstractCell}, path::String)
    open(path, "w") do file
            output::String = join([string(cell) for cell in cells])
           write(file, output)
    end
end

"""
## read_ipynb(f::String) -> ::Vector{Cell}
Reads an IPython notebook into a vector of cells.
### example
read_ipynb("helloworld.ipynb")
"""
function read_ipynb(f::String)
    file::String = read(f, String)
    j::Dict = JSON.parse(file)
    [begin
        outputs = cell["data"]["text/plain"]
        ctype = cell["cell_type"]
        source = cell["source"]
        n = cell["execution_count"]
        Cell(n, ctype, source, outputs)
    end for cell in j["cells"]]::Vector{Cell}
end



"""
## ipynbjl(ipynb_path::String, output_path::String)
Reads notebook at **ipynb_path** and then outputs as .jl Julia file to
**output_path**.
### example
ipynbjl("helloworld.ipynb", "helloworld.jl")
"""
function ipyjl(ipynb_path::String, output_path::String)
    cells = read_ipynb(ipynb_path)
    output = save_jl(cells)
end

"""
### sep(::Any) -> ::String
Separates and parses lines of individual cell content via an array of strings.
Returns string of concetenated text. Basically, the goal of sep is to ignore
n exit code inside of the document.
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

function save(cells::Vector{AbstractCell}, URI::String,
    file_types::Dict = Dict("ipynb" => save_ipynb, "jl" => save_jl,
     "pluto" => save_pluto);  as::String = "jl")
     file_types[as](cells, URI)::Nothing
end

function read(URI::String, file_types::Dict = Dict("ipynb" => read_ipynb,
    "jl" => read_jl, "pluto" => read_pluto); as::String = "jl")
    file_ext::String = split(URI, ".")[2]
    file_types[]
end
