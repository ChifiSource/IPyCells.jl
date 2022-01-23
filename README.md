# IpyJL.jl
A simple IPython notebook to Julia code parser.
### Adding
```julia
julia> ]
pkg> add https://github.com/emmettgb/IpyJL.jl.git
```
### Usage
The usage of this little module is pretty simple, just call the ipynbjl() method with the first argument being the notebook file path, second being the Julia file path.
```julia
ipynbjl("ipynbtestbook.ipynb", "example.jl")
```
### Other stuff (?(other_thing))
- read_ipynb
- Cell
- cells_to_string
- sep
