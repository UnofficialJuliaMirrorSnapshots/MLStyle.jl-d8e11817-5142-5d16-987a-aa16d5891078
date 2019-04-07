module TestModule

using Test
using MLStyle

MODULE = TestModule

@use GADT
include("MQuery/test.jl")
include("modules/cond.jl")
include("modules/ast.jl")
include("as_record.jl")
include("adt.jl")
include("when.jl")
include("active_patterns.jl")
include("exception.jl")
include("render.jl")
include("pervasive.jl")
include("expr_template.jl")
include("gallery/simple.jl")
include("match.jl")
include("pattern.jl")
include("dot_expression.jl")
include("typelevel.jl")
include("untyped_lam.jl")
include("nothing.jl")

end