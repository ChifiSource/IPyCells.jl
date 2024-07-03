
function plto_cell_lines(raw::String)
    cellpos = Dict{Int64, UnitRange{Int64}}()
    first = 0
    ccount = 0
    for (count, line) in enumerate(split(raw, "\n"))
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
function parse_pluto(raw::String)
    cellpos = plto_cell_lines(uri)
    x = split(raw, "\n")
    [begin
        unprocessed_uuid = x[cell[1]]
        text_data = x[cell[2:end]]
        Cell("code", string(text_data))
    end for cell in values(cellpos)]::Vector
end

read_pluto(uri::String) = parse_pluto(read(uri, String))

read_olive(uri::String) = parse_olive(read(uri, String))

"""

"""
function parse_olive(str::String)
    lines = split(str, "#==|||==#")
    [begin
        if contains(s, "#==output")
            outpfirst = findfirst("#==output", s)
            ctypeend = findnext("]", s, maximum(outpfirst))[1]
            if isnothing(outpfirst) || isnothing(ctypeend)
                throw("")
            end
            celltype = s[maximum(outpfirst) + 2:ctypeend - 1]
            outpend = findnext("==#", s, outpfirst[1])
            outp = ""
            if ~(isnothing(outpend))
                outp = s[ctypeend + 2:outpend[1] - 1]
            end
            inp = s[1:outpfirst[1] - 2]
            Cell(string(celltype), string(inp), string(outp))
        elseif contains(s, "\"\"\"")
            rp = replace(s, "\n" => "")
            if contains(rp[1:3], "\"\"\"") && contains(rp[length(rp) - 4:length(rp)], "\"\"\"")
                Cell("markdown", replace(s, "\"\"\"" => ""))
            else
                Cell("code", string(s))
            end
        else
            Cell("code", string(s))
        end
    end for s in lines]::Vector{Cell}
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
    readin::String = read(uri, String)
    # pluto
    if contains(readin, "═╡")
        return(parse_plto(readin))::String
    # olive
    elseif contains(readin, "#==output[") && contains(readin, "#==|||==#")
        return(parse_olive(readin))::String
    end
    parse_julia(readin)::String
end

function parse_julia(raw::String)
    # regular Julia:
    at::Int64 = 1
    textpos::Int64 = 1
    cells::Vector{Cell} = Vector{Cell}()
    while true
        nextend = findnext("end", readin, at)
        if isnothing(nextend)
            n::Int64 = length(raw)
            if at != n && at - 1 != n
                push!(cells, Cell{:code}(raw[textpos:length(raw)]))
            end
            break
        end
        section::String = raw[at:nextend]
        at = maximum(nextend)
        if contains(section, "function") || contains(section, "do") || contains(section, "module") || contains(section, "else")
            continue
        elseif contains(section, "begin") || contains(section, "for") || contains(section, "if") || contains(section, "elseif")
            continue
        end
        ne_max::Int64 = maximum(nextend)
        push!(cells, Cell{:code}(raw[textpos:ne_max]))
        textpos = ne_max
    end
    cells::Vector{Cell}
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
    data::Dict = Dict{String, Dict}("cells" => [begin
        Dict("cell_type" => string(typeof(cell).parameters[1]), "execution_count" => string(e), 
        id => cell.id, "metadata" = Dict(), "outputs" => "", source => cell.source)
    end for (e, cell) in enumerate(cells)])
    open(path, "w") do o::IO
        write(o, JSON.print(data))
    end
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
