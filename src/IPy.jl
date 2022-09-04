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
"""
module IPy
import Base: string, read

__precompile__()
abstract type AbstractCell end
include("IPyCells.jl")
include("IPyRW.jl")

export ipynbjl, open, save
end # module
