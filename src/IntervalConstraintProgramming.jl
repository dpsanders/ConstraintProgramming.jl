__precompile__(true)

module IntervalConstraintProgramming

using ValidatedNumerics
using MacroTools
using Compat
using FixedSizeArrays: setindex

import Base:
    show, ∩, ∪, !, ⊆, setdiff

import ValidatedNumerics: sqr

export
    @contractor,
    Separator, separator, @separator, @constraint,
    @function,
    SubPaving, Paving,
    pave, refine!,
    Vol,
    show_code


include("reverse_mode.jl")
include("ast.jl")
include("code_generation.jl")
include("contractor.jl")
include("separator.jl")
include("paving.jl")
include("setinversion.jl")
include("volume.jl")
include("functions.jl")


end # module
