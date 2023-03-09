<div align="center" style = "box-pack: start;">
  </br>
  <img width = 300 src="https://github.com/ChifiSource/image_dump/blob/main/ipyjl/logo.png" >
  
  
  [![version](https://juliahub.com/docs/Lathe/version.svg)](https://juliahub.com/ui/Packages/Lathe/6rMNJ)
[![deps](https://juliahub.com/docs/Lathe/deps.svg)](https://juliahub.com/ui/Packages/Lathe/6rMNJ?t=2)
[![pkgeval](https://juliahub.com/docs/Lathe/pkgeval.svg)](https://juliahub.com/ui/Packages/Lathe/6rMNJ)
  </br>
  </br>
  <h1>IPyCells</h1>
  </div>

`IPyCells` provides parametric cell-based functionality, as well as readers and writers for different cell formats (Ipynb, JL), as well as offering the option to extend the cells via parametric typing. This module provides
###### cells
- `AbstractCell`
- `Cell(n::Int64, type::String, content::String, outputs::Any = ""; id::String = "")`
- `string(Cell{<:Any})`
- `string(cell::Cell{:md})`
- `string(cell::Cell{:doc})`
- `getindex(v::Vector{Cell{<:Any}}, s::String)`
###### read/write
- `read_plto(uri::String)`
- `read_jlcells(uri::String)`
- `read_jl(uri::String)`
- `save(cells::Vector{<:AbstractCell}, path::String)`
- `save_ipynb(cells::Vector{<:AbstractCell}, path::String)` (this **does not** work just right yet) cells are readable by Olive, not jupyter post-save.
- `read_ipynb(f::String)`
- `ipyjl(ipynb_path::String, output_path::String)`
###### (internal)
- `plto_cell_lines(uri::String)`
- `sep(content::Any)`
### Adding
```julia
julia> ]
pkg> add IPyCells
```
### Usage
There are many ways to use `IPyCells` -- This package could be used to convert Pluto notebooks into Olive notebooks, IPython notebooks into Julia notebooks. Currently, the ipynb save method will break your `.ipynb` files where IJulia cannot read them, [Olive](https://github.com/ChifiSource/Olive.jl) eventually this is planned to be fixed. Anyway, this package could be used to read any package and save it into (currently) ipynb or julia.
```julia
ipynbjl("ipynbtestbook.ipynb", "example.jl")
```
```julia
cells = read_ipynb
save_jl(cells)
```
This preserves both the output and markdown. Alternatively, you could write functions around cells enabling for different cell types to be read by this reader.
