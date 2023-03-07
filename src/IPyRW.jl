
function plto_cell_lines(uri::String)
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
    [begin
        unprocessed_uuid = x[cell[1]]
        text_data = x[cell[2:end]]
        Cell(n, "code", string(text_data))
    end for (n, cell) in enumerate(values(cellpos))]
end

function read_jlcells(uri::String)
    lines = split(read(uri, String), "#==|||==#")
    [begin
        if contains(s, "#==output")
            outpfirst = findfirst("#==output", s)
            ctypeend = findnext("]", s, maximum(outpfirst))[1]
            celltype = s[maximum(outpfirst) + 2:ctypeend - 1]
            outpend = findnext("==#", s, outpfirst[1])
            outp = ""
            if ~(isnothing(outpend))
                outp = s[ctypeend + 2:outpend[1] - 1]
            end
            inp = s[1:outpfirst[1] - 2]
            Cell(n, string(celltype), string(inp), string(outp))
        else
            Cell(n, "code", string(s))
        end
    end for (n, s) in enumerate(lines)]::AbstractVector
end

function read_jl(uri::String)
    readin = read(uri, String)
    if contains(readin, "═╡")
        return(read_plto(uri))
    end
    if contains(readin, "#==output[") && contains(readin, "#==|||==#")
        return(read_jlcells(uri))
    end
    lines = split(readin, "\n\n")
    [Cell(n, "code", string(s)) for (n, s) in enumerate(lines)]::AbstractVector
end

"""
## cells_to_string(::Vector{Any}) -> ::String
Converts an array of Cell types into text.
"""
function save(cells::Vector{<:AbstractCell}, path::String)
    open(path, "w") do file
        output::String = join([string(cell) * "\n" for cell in cells])
        write(file, output)
    end
end

function save_ipynb(cells::Vector{<:AbstractCell}, path::String)
    file::String = read(path, String)

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
        outputs = ""
        ctype = cell["cell_type"]
        source = string(join(cell["source"]))
        Cell(n, ctype, source, outputs)
    end for (n, cell) in enumerate(j["cells"])]::AbstractVector
end

"""
## ipynbjl(ipynb_path::String, output_path::String)
Reads notebook at **ipynb_path** and then outputs as .jl Julia file to
**output_path**.
### example
```
ipynbjl("helloworld.ipynb", "helloworld.jl")
```
"""
function ipyjl(ipynb_path::String, output_path::String)
    cells = read_ipynb(ipynb_path)
    output = save_jl(cells)
end

"""
### sep(::Any) -> ::String
---
Separates and parses lines of individual cell content via an array of strings.
Returns string of concetenated text. Basically, the goal of sep is to ignore
n exit code inside of the document.
### example
```
```
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
