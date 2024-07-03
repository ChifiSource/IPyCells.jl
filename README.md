<div align="center" style = "box-pack: start;">
  </br>
  <img width = 300 src="https://github.com/ChifiSource/image_dump/blob/main/ipyjl/logo.png" >
  
  
  [![version](https://juliahub.com/docs/Lathe/version.svg)](https://juliahub.com/ui/Packages/Lathe/6rMNJ)
[![deps](https://juliahub.com/docs/Lathe/deps.svg)](https://juliahub.com/ui/Packages/Lathe/6rMNJ?t=2)
  </br>
  </br>
  <h1>IPyCells</h1>
  </div>

`IPyCells` provides parametric cell-based functionality, as well as readers and writers for different cell formats (Ipynb, JL), as well as offering the option to extend the cells via parametric typing.
- [adding](#adding)
- [usage](#usage)
- [contributing](#contributing)
  - [guidelines](#guidelines)
### Adding
```julia
julia> using Pkg; Pkg.add("IPyCells")
julia> ]
pkg> add IPyCells
```
### Usage
Either `.ipynb` or `.jl` files may be read with this API. When reading Julia files, the reader will delinate which type of julia it is -- whether [Pluto](https://github.com/fonsp/Pluto.jl) cells, [Olive](https://github.com/ChifiSource/Olive.jl) cells, or just plain julia.
```julia
read_jl(uri::String)
read_ipynb(f::String)
```
The different forms of Julia all have their own parsers, which may be used independently to parse text:
```julia
parse_pluto(raw::String)
parse_olive(str::String)
parse_julia(raw::String)
```
Cells can be saved with `save` for julia files and `save_ipynb` for ipynb files.
```julia
save(cells::Vector{<:AbstractCell}, path::String)
save_ipynb(cells::Vector{<:AbstractCell}, path::String)
```
For quick conversions from Julia to nbformat or nbformat to Julia, there are `ipyjl` and `jlipy` respectively.
```julia
ipyjl(ipynb_path::String, output_path::String)
jlipy(ipynb_path::String, output_path::String)
```
##### contributing
There are several ways to contribute to `IPyCells` while also contributing to the greater lot of [chifi](https://github.com/ChifiSource) software.
- simply using `IPyCells`
- starring this project
- forking this project [contributing guidelines](#guidelines)
- participating in the community 🔴🟢🟣
- supporting chifi creators
- helping with other chifi projects
#### guidelines
When submitting issues or pull-requests, it is important to make sure of a few things. We are not super strict, but making sure of these few things will be helpful for maintainers!
1. You have replicated the issue on `Unstable`
2. The issue does not currently exist... or does not have a planned implementation different to your own. In these cases, please collaborate on the issue, express your idea and we will select the best choice.
3. **Pull Request TO UNSTABLE**
4. If you have a new issue, **open a new issue**. It is not best to comment your issue under an unrelated issue; even a case where you are experiencing that issue, if you want to mention **another issue**, open a **new issue**.
5. Questions are fine, but **not** questions answered inside of this `README`.
