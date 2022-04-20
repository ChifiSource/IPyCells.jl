<div align="center" style = "box-pack: start;">
  </br>
  <img width = 300 src="https://github.com/ChifiSource/image_dump/blob/main/ipyjl/logo.png" >
  
  
  [![version](https://juliahub.com/docs/Lathe/version.svg)](https://juliahub.com/ui/Packages/Lathe/6rMNJ)
[![deps](https://juliahub.com/docs/Lathe/deps.svg)](https://juliahub.com/ui/Packages/Lathe/6rMNJ?t=2)
[![pkgeval](https://juliahub.com/docs/Lathe/pkgeval.svg)](https://juliahub.com/ui/Packages/Lathe/6rMNJ)
  </br>
  </br>
  <h1>Ipy.jl</h1>
  </div>

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
