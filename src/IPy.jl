"""
Created in April, 2022 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
by team
[odd-data](https://github.com/orgs/ChifiSource/teams/odd-data)
This software is MIT-licensed.
### IPy.jl
IPy.jl is a consistent cell format amongst three different cell file-types. The
package combines .ipynb, .jl, and .jl pluto files together into one easy to
use module.
##### Module Composition
- [**IPy**]() - High-level API
- [IPyRW]() - Reading of cells into **Cell** and writing of **Cell** to file output.
- [IPyCells]() - Provides **Cell** structure.
"""
module IPy
__precompile__()
abstract type AbstractCell end
include("IPyCells")
using Main.IPyCells: Cell
include("IPyRW.jl")
using Main.IPyRW

export ipynbjl, open, save
end # module
