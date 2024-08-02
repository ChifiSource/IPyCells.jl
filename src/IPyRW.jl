
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

read_olive(uri::String) = parse_olive(read(uri, String))

function parse_julia(raw::String)
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


"""

"""
function save(cells::Vector{<:AbstractCell}, path::String; raw::Bool = false)
    output::String = ""
    open(path, "w") do file
        if raw
            output::String = join((cell.source for cell in cells), "\n")
        else
            output::String = join(string(cell) for cell in cells)
        end
        write(file, output)
    end
end

"""

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

function jlipy(jl_path::String, output_path::String)
    cells = read_jl(jl_path)
    save_ipynb(cells, output_path)
end