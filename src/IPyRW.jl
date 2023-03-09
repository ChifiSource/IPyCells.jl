
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

"""
## read_plto(path::String) -> ::Vector{<:AbstractCell}
Reads a pluto file into IPy cells.
### example
```julia
cells = read_plto("myfile.jl")
```
"""
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

"""
## read_jlcells(path::String) -> ::Vector{<:AbstractCell}
Reads in an `IPy.save` saved Julia file.
### example
```julia
cells = read_jlcells("myfile.jl")
```
"""
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
        elseif contains(s, "\"\"\"")
            rp = replace(s, "\n" => "")
            if contains(rp[1:3], "\"\"\"") && contains(rp[length(rp) - 4:length(rp)], "\"\"\"")
                inp = replace(s, "\"\"\"" => "")
                Cell(n, "markdown", string(inp))
            else
                Cell(n, "code", string(s))
            end
        else
            Cell(n, "code", string(s))
        end
    end for (n, s) in enumerate(lines)]::AbstractVector
end

"""
## read_jl(path::String) -> ::Vector{<:AbstractCell}
Reads in a Vector of cells from a Julia file. If the file is found to contain
IPy style output,  this function will promptly redirect to `read_jlcells`. If
the file is found to contain `Pluto` output, it will be redirected to
`read_plto`.
### example
```julia
cells = read_jl("myfile.jl")
```
"""
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
## save(cells::Vector{<:AbstractCell}, path::String) -> _
Saves cells as Julia file.
### example
```julia
cells = read_jl("myfile.jl")
save(cells, "myfile.jl")
```
"""
function save(cells::Vector{<:AbstractCell}, path::String)
    open(path, "w") do file
        output::String = join([string(cell) for cell in cells])
        write(file, output)
    end
end

"""
## save_ipynb(cells::Vector{<:AbstractCell}, path::String) -> _
Saves cells as IPython notebook file. **Note that as of right now, this currently
breaks the IJulia reading of the file -- this will (hopefully) be fixed in future
IPy releases**.
### example
```julia
cells = read_jl("myfile.jl")
save(cells, "myfile.jl")
```
"""
function save_ipynb(cells::Vector{<:AbstractCell}, path::String)
    newd = Dict{String, Any}("nbformat_minor" => 4, "nbformat" => 4)
    newcells = Dict{String, Any}()
    metadata = Dict{String, Any}()
    lang_info = Dict{String, Any}("file_extension" => ".jl",
    "mimetype" => "application/julia", "name" => "julia",
    "version" => string(VERSION))
    kern_spec = Dict{String, Any}("name" => "julia-$(split(string(VERSION), ".")[1:2])",
    "display_name" => "Julia $(string(VERSION))", "language" => "julia")
    push!(metadata, "language_info" => lang_info,
    "kernelspec" => kern_spec)
    ncells = Dict([begin
        cell.n = e
        outp = Dict{String, Any}("output_type" => "execute_result",
        "data" => Dict{String, Any}("text/plain" => Any["$(cell.outputs)"]),
        "metadata" => Dict{String, Any}(),
        "execution_count" => cell.n)
        cell.n => Dict(cell.n => Dict{String, Any}("execution_count" => cell.n,
        "metadata" => Dict{String, Any}(), "source" => Any[cell.source],
        "cell_type" => cell.type, "outputs" => outp))
    end for (e, cell) in enumerate(cells)])
    push!(newd, "metadata" => metadata, "cells" => ncells)
    open(path, "w") do io
        JSON.print(io, newd)
    end
    newd
end

"""
## read_ipynb(f::String) -> ::Vector{Cell}
Reads an IPython notebook into a vector of cells.
### example
```
cells = read_ipynb("helloworld.ipynb")
```
"""
function read_ipynb(f::String)
    file::String = read(f, String)
    j::Dict = JSON.parse(file)
    [begin
        outputs = ""
        ctype = cell["cell_type"]
        source = string(join(cell["source"]))
        if "outputs" in keys(cell)
        #==    if length(cell["outputs"][1]["data"]) > 0
                println(cell["outputs"][1]["data"])
                outputs = join([v for v in values(cell["outputs"][1]["data"])])
            end ==#
        end
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
    output = save(cells, output_path)
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
