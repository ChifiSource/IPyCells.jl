"""
```julia
plto_cell_lines(raw::String) -> ::Dict{Int64, UnitRange{Int64}}
```
Gets the cell positions from a `Pluto` `.jl` file. Used by `parse_pluto` to find lines to seek by.
"""
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
```julia
parse_pluto(raw::String) -> ::Vector{Cell}
```
Parses the raw `String` read from a `Pluto` file into a `Vector` of `Cells`.
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

"""
```julia
read_pluto(uri::String) -> ::Vector{Cell}
```
Reads a `.jl` `Pluto` file from its `URI` into a `Vector{Cell}`
"""
read_pluto(uri::String) = parse_pluto(read(uri, String))

"""
```julia
parse_olive(str::String) -> ::Vector{Cell}
```
Parses `Olive` cell source from a `String` into a `Vector` of `Cells`.
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
```julia
read_olive(uri::String) -> ::Vector{Cell}
```
Reads a `.jl` `Olive` file from its `URI` into a `Vector{Cell}`.
"""
read_olive(uri::String) = parse_olive(read(uri, String))

"""
```julia
parse_julia(uri::String) -> ::Vector{Cell}
```

"""
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
        return(parse_plto(readin))::Vector{Cell}
    # olive
    elseif contains(readin, "#==output[") && contains(readin, "#==|||==#")
        return(parse_olive(readin))::Vector{Cell}
    end
    parse_julia(readin)::Vector{Cell}
end


"""

"""
function save(cells::Vector{<:AbstractCell}, path::String; raw::Bool = false)
    output::String = ""
    open(path, "w") do file
        if raw
            output = join((cell.source for cell in cells), "\n")
        else
            output = join(string(cell) for cell in cells)
        end
        write(file, output)
    end
end

function save_ipynb(cells::Vector{<:AbstractCell}, path::String)
    cell_str = """{\n"cells": ["""
    cell_str = cell_str * join([begin
        """{
   "cell_type": "$(typeof(cell).parameters[1])",
   "execution_count": 1,
   "id": "$(UUIDs.uuid4())",
   "metadata": {},
   "outputs": [
    {
     "data": {
      "text/plain": [
       "$(cell.outputs)"
      ]
     },
     "execution_count": 1,
     "metadata": {},
     "output_type": "execute_result"
    }
   ],
   "source": [
    "$(cell.source)"
   ]
  }"""
    end for cell in cells], ",")
    open(path, "w") do o::IOStream
        write(o, cell_str * """ ],
 "metadata": {
  "kernelspec": {
   "display_name": "Julia 1.9.2",
   "language": "julia",
   "name": "julia-1.9"
  },
  "language_info": {
   "file_extension": ".jl",
   "mimetype": "application/julia",
   "name": "julia",
   "version": "1.9.2"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}""" )
    end
    return
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
            cell_outputs = cell["outputs"]
            if length(cell_outputs) > 0
                outputs = first(cell_outputs[1]["data"])[2][1]
            end
        end
        Cell(ctype, source, outputs)
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