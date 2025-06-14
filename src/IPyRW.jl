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
    cellpos = plto_cell_lines(raw)
    x = split(raw, "\n")
    [begin
        unprocessed_uuid = x[cell[1]]
        text_data = x[cell[2:end]]
        text_data = join(text_data, "\n")
        if contains(text_data, "md\"")
            start_text = findfirst("md\"\"\"", text_data)
            nd_text = findnext("\"\"\"", text_data, maximum(start_text))
            Cell("markdown", text_data[maximum(start_text) + 1:minimum(nd_text) - 1])
        else
            Cell("code", text_data)
        end
    end for cell in reverse([values(cellpos) ...])]::Vector
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
    Vector{Cell{<:Any}}(filter(x -> ~(isnothing(x)), [begin
        if replace(s, " " => "", "\n" => "") == ""
            nothing::Nothing
        else
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
        end
    end for s in lines]))::Vector{Cell}
end

"""
```julia
read_olive(uri::String) -> ::Vector{Cell}
```
Reads a `.jl` `Olive` file from its `URI` into a `Vector{Cell}`.
"""
read_olive(uri::String) = parse_olive(read(uri, String))


julia_ndnames = ("begin", "module", "for", "if", "try", "function", "while", "struct", "abstract")

"""
```julia
parse_julia(raw::String) -> ::Vector{Cell}
```
Parses plain julia into a `Vector{Cell}`.
"""
function parse_julia(raw::String)
	cells::Vector{Cell} = Vector{Cell}()
    current_line::Int64 = 0
	current_section::String = ""
	block_depth::Int = 0
	in_string::Bool = false
	in_comment::Bool = false
    lines = split(raw, "\n")
    n::Int64 = length(lines)
	while true
        current_line += 1
        if current_line > n
            if current_section != ""
                push!(cells, Cell{:code}(current_section))
            end
            break
        end
        line::String = lines[current_line]
        if in_string
            if contains(line, "\"\"\"")
                in_string = false
                current_section = current_section * "\n" * line
            else
                current_section = current_section * "\n" * line
            end
            continue
        elseif in_comment
            if contains(line, "=#")
                in_comment = false
                current_section = current_section * "\n" * line
            else
                current_section = current_section * "\n" * line
            end
            continue
        end
        if contains(line, "\"\"\"")
            current_section = current_section * "\n" * line
            in_string = true
            continue
        end
        if contains(line, "#=")
            current_section = current_section * "\n" * line
            in_comment = true
            continue
        end

        contains_open = ~isnothing(findfirst(ndname -> contains(line, ndname), julia_ndnames))
        contains_end = contains(line, "end")
        if contains_open && ~contains_end
            current_section = current_section * "\n" * line
            block_depth += 1
        elseif contains_open && contains_end && block_depth == 0
            current_section = current_section * "\n" * line
            push!(cells, Cell{:code}(current_section))
            current_section = ""
        elseif contains_end && block_depth == 0
            current_section = current_section * "\n" * line
            push!(cells, Cell(current_section))
            current_section = ""
        elseif contains_end && block_depth != 0
            block_depth -= 1
            current_section = current_section * "\n" * line
        else
            current_section = current_section * "\n" * line
        end
    end
    cells::Vector{Cell}
end

"""
```julia
read_jl(uri::String) -> ::Vector{Cell}
```
Reads a `.jl` file into a `Vector{Cell}`, whether or not that file is in 
`Pluto` or `Olive` format or in plain Julia. All formats are distinguished 
and read with this reader.
"""
function read_jl(uri::String)
    readin::String = read(uri, String)
    # pluto
    if contains(readin, "═╡")
        return(parse_pluto(readin))::Vector{Cell}
    # olive
    elseif contains(readin, "#==output[") && contains(readin, "#==|||==#")
        return(parse_olive(readin))::Vector{Cell}
    end
    parse_julia(readin)::Vector{Cell}
end

"""
```julia
save(cells::Vector{<:AbstractCell}, path::String; raw::Bool = false) -> ::Nothing
```
Saves a `Vector{Cell}` as a new Julia file. By default, this will save into the 
`Olive` format most readable by `IPyCells`; providing `raw` as `true` will 
save as plain Julia text.
- See also: `save_ipynb`, `read_jl`, `parse_olive`
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

function jsonify_output(output::Any)
    replace(string(output), "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n")::String
end

function jsonify_output(output::String)
    replace(output, "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n")::String
end

"""
```julia
save_ipynb(cells::Vector{<:AbstractCell}, path::String) -> ::Nothing
```
Saves a `Vector{Cell}` as an `IPython` notebook for `IJulia`.
- See also: `save`, `read_jl`, `parse_olive`, `ipyjl`
"""
function save_ipynb(cells::Vector{<:AbstractCell}, path::String)
    cell_str::String = """{\n"cells": ["""
    cell_str = cell_str * join([begin
        new_outputs = jsonify_output(cell.outputs)
        new_source = jsonify_output(cell.source)
        """{
   "cell_type": "$(typeof(cell).parameters[1])",
   "execution_count": 1,
   "id": "$(UUIDs.uuid4())",
   "metadata": {},
   "outputs": [
    {
     "data": {
      "text/plain": [
       "$(new_outputs)"
      ]
     },
     "execution_count": 1,
     "metadata": {},
     "output_type": "execute_result"
    }
   ],
   "source": [
    "$(new_source)"
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
```julia
read_ipynb(path::String) -> ::Vector{Cell}
```
Reads a `Vector{Cell}` in from a `.ipynb` notebook file.
- See also: `save`, `read_jl`, `parse_olive`, `read_olive`, `save_ipynb`, `ipyjl`
"""
function read_ipynb(f::String)
    file::String = read(f, String)
    j::Dict = JSON.parse(file)
    Vector{Cell}([begin
        outputs = ""
        ctype = cell["cell_type"]
        source = string(join(cell["source"]))
        if "outputs" in keys(cell)
            cell_outputs = cell["outputs"]
            if length(cell_outputs) > 0 && haskey(cell_outputs[1], "data")
                outputs = first(cell_outputs[1]["data"])[2][1]
            end
        end
        Cell(ctype, source, outputs)
    end for (n, cell) in enumerate(j["cells"])])::Vector{Cell}
end

"""
```julia
ipynbjl(ipynb_path::String, output_path::String) -> ::Nothing
```
Reads notebook at **ipynb_path** and then outputs as .jl Julia file to
**output_path**. The inverse of `jlipy`.
### example
```julia
ipynbjl("helloworld.ipynb", "helloworld.jl")
```
"""
function ipyjl(ipynb_path::String, output_path::String)
    cells = read_ipynb(ipynb_path)
    output = save(cells, output_path)
    nothing::Nothing
end

"""
```julia
ipynbjl(jl_path::String, output_path::String) -> ::Nothing
```
Reads a Julia file at **jl_path** and then outputs as .ipynb notebook file to
**output_path**. The inverse of `ipyjl`.
### example
```julia
jlipy("helloworld.jl", "helloworld.ipynb")
```
"""
function jlipy(jl_path::String, output_path::String)
    cells = read_jl(jl_path)
    save_ipynb(cells, output_path)
    nothing::Nothing
end