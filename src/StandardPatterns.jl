module StandardPatterns
# This module is designed for creating complex patterns from the primtive ones.

using MLStyle
using MLStyle.toolz.List: cons, nil
using MLStyle.Infras
using MLStyle.MatchCore

struct TypeVar
    t :: Symbol
end

struct Relation
    l :: Symbol
    op :: Symbol
    r
end


function any_constraint(t, forall)

    function is_rel(::Relation)
        true
    end

    function is_rel(::TypeVar)
        false
    end

    !(t isa Symbol) || any(is_rel, collect(extract_tvars(forall)))
end

macro type_matching(t, forall)
    quote
        NAME = mangle(mod)
        __T__ = $t
        __FORALL__ = $forall
        if !($any_constraint(__T__, __FORALL__))
            function (body)
                @format [body, tag, NAME, TARGET, __T__] quote
                    @inline __L__ function NAME(TARGET :: __T__) where {$(__FORALL__...)}
                        __T__ # if not put this here, an error would be raised : "local variable XXX cannot be used in closure declaration"
                        body
                    end
                    NAME(tag)
                end
            end
        else
            function (body)
                @format [body, tag, NAME, TARGET, __T__] quote
                    @inline __L__ function NAME(TARGET :: __T__) where {$(__FORALL__...)}
                        __T__
                        body
                    end
                    @inline __L__ function NAME(_)
                        failed
                    end
                    NAME(tag)
                end
            end
        end
    end |> esc
end

function extract_tvars(t :: AbstractArray)
    @match t begin
        [] => nil()
        [hd && if hd isa Symbol end, tl...] => cons(TypeVar(hd), extract_tvars(tl))
        [:($hd <: $r), tl...] =>  cons(Relation(hd, :<:, r), extract_tvars(tl))
        [:($hd >: $(r)), tl...] =>  cons(Relation(hd, Symbol(">:"), r), extract_tvars(tl))
        _ => @error "invalid tvars"
    end
end

defPattern(StandardPatterns,
        predicate = x -> x isa Expr && x.head == :(::),
        rewrite = (tag, case, mod) ->
                let args   = (case.args..., ),
                    TARGET = mangle(mod)
                    function for_type(t)
                        @match t begin
                            :($typ where {$(tvars...)}) => (@type_matching typ tvars)
                            _ => @typed_as t

                        end
                    end

                    function f(args :: NTuple{2, Any})
                        pat, t = args
                        for_type(t) ∘ mkPattern(TARGET, pat, mod)
                    end

                    function f(args :: NTuple{1, Any})
                        t = args[1]
                        for_type(t)
                    end
                    f(args)
                end
)
end