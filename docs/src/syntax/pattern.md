Pattern
=======================

- [Literal Pattern](#Literal-pattern-1)
- [Capturing pattern](#Capturing-pattern-1)
- [Type Pattern](#Type-pattern-1)
- [As-Pattern, And Pattern](#As-Pattern-1)
- [Guard](#Guard-1)
- [Predicate](#Predicate-1)
- [Rference Pattern](#Reference-pattern-1)
- [Custom Pattern, Dict, Tuple, Array](#Custom-pattern-1)
- [Or Pattern](#Or-pattern-1)
- [ADT destructing, GADTs](#ADT-destructing-1)
- [Advanced Type Pattern](#Advanced-type-pattern-1)
- [Side Effect](#Side-effect-1)
- [Ast Pattern](#Ast-Patrtern-1)

Patterns provide convenient ways to manipulate data.

Literal Pattern
------------------------

```julia


@match 10 {
    1  => "wrong!"
    2  => "wrong!"
    10 => "right!"
}

# => "right"
```
There are 3 distinct types whose literal data could be used as literal patterns:

- `Number`
- `AbstractString`
- `Symbol`

Capturing Pattern
--------------

```julia

@match 1 begin
    x => x + 1
end
# => 2
```

Type Pattern
-----------------

```julia

@match 1 begin
    ::Float  => nothing
    b :: Int => b
    _        => nothing
end
# => 1
```

There is an advanced version of `Type-Pattern`s, which you can destruct types with fewer limitations. Check [Advanced Type Pattern](#advanced-type-pattern).

However, when you use `TypeLevel Feature`, the behavious could change slightly. See [TypeLevel Feature](#type-level-feature).

As-Pattern
----------

`As-Pattern` can be expressed with `And-Pattern`. 

```julia
@match (1, 2) begin
    (a, b) && c => c[1] == a && c[2] == b
end
```


Guard
-----

```julia

@match x begin
    x && if x > 5 end => 5 - x # only succeed when x > 5
    _        => 1
end
```

Predicate
---------------

The following has the same semantics as the above snippet.

```julia

function pred(x)
    x > 5
end

@match x begin
    x && function pred end => 5 - x # only succeed when x > 5
    _        => 1
end

@match x begin
    x && function (x) x > 5 end => 5 - x # only succeed when x > 5
    _        => 1
end

```


Range Pattern
--------------------
```julia
@match 1 begin
    0:2:10 => 1
    1:10 => 2
end # 2
```

Reference Pattern
-----------------

This feature is from `Elixir` which could slightly extends ML pattern matching.

```julia
c = ...
@match (x, y) begin
    (&c, _)  => "x equals to c!"
    (_,  &c) => "y equals to c!"
    _        => "none of x and y equal to c"
end
```


Custom Pattern
--------------

Not recommend to do this for it's implementation specific.
If you want to make your own extensions, check `MLStyle/src/Pervasives.jl`.

Defining your own patterns using the low level APIs is quite easy, 
but exposing the implementations would cause compatibilities in future development.
 


Dict, Tuple, Array
---------------------

- Dict pattern(like `Elixir`'s dictionary matching or ML record matching)

```julia
dict = Dict(1 => 2, "3" => 4, 5 => Dict(6 => 7))
@match dict begin
    Dict("3" => four::Int,
          5  => Dict(6 => sev)) && if four < sev end => sev
end
# => 7
```

- Tuple pattern

```julia

@match (1, 2, (3, 4, (5, ))) begin
    (a, b, (c, d, (5, ))) => (a, b, c, d)

end
# => (1, 2, 3, 4)
```

- Array pattern(much more efficient than Python for taking advantage of array views)

```julia
julia> it = @match [1, 2, 3, 4] begin
         [1, pack..., a] => (pack, a)
       end
([2, 3], 4)

julia> first(it)
2-element view(::Array{Int64,1}, 2:3) with eltype Int64:  
 2
 3
julia> it[2]
4
```


Or patterns
-------------------

```julia
test(num) =
    @match num begin
       ::Float64 ||
        0        ||
        1        ||
        2        => true

        _        => false
    end

test(0)   # true
test(1)   # true
test(2)   # true
test(1.0) # true
test(3)   # false
test("")  # false
```

Tips: `Or Pattern`s could nested.

ADT Destructing
---------------

You can match `ADT` in following 3 means:

```julia

C(a, b, c) => ... # ordered arguments
C(b = b) => ...   # record syntax
C(_) => ...       # wildcard for destructing

``` 

Here is an example:

```julia

@data Example begin
    Natural(dimension :: Float32, climate :: String, altitude :: Int32)
    Cutural(region :: String,  kind :: String, country :: String, nature :: Natural)
end

神农架 = Cutural("湖北", "林区", "中国", Natural(31.744, "北亚热带季风气候", 3106))
Yellostone = Cutural("Yellowstone National Park", "Natural", "United States", Natural(44.36, "subarctic", 2357))

function my_data_query(data_lst :: Vector{Cutural})
    filter(data_lst) do data
        @match data begin
            Cutural(_, "林区", "中国", Natural(dim=dim, altitude)) &&
            if dim > 30.0 && altitude > 1000 end => true
            
            Cutural(_, _, "United States", Natural(altitude=altitude)) &&
            if altitude > 2000 end  => true
                
            _ => false

        end
    end
end
my_data_query([神农架, Yellostone])
...
```

- About GADTs

```julia
@use GADT

@data internal Example{T} begin
    A{T} :: (Int, T) => Example{Tuple{Int, T}}
end

@match A(1, 2) begin
    A{T}(a :: Int, b :: T) where T <: Number => (a == 1 && T == Int) 
end

```

Advanced Type Pattern
-------------------------

Instead of `TypeLevel` feature used in v0.1, an ideal type-stable way to destruct types now is introduced here.

```julia
@match 1 begin
    ::String => String
    ::Int => Int    
end
# => Int64

@match 1 begin
    ::T where T <: AbstractArray => 0
    ::T where T <: Number => 1
end

# => 0

struct S{A, B}
    a :: A
    b :: B
end

@match S(1, "2") begin
    S{A} where A => A
end
# => Int64

@match S(1, "2") begin
    S{A, B} where {A, B} => (A, B)
end
# => (Int64, String)

```


Side-Effect
-----------------------

To introduce side-effects into pattern matching, we provide a built-in pattern called `Do` pattern to achieve this.
Also, a pattern called `Many` can work with `Do` pattern in a perfect way.


Do-Pattern and Many-Pattern
--------------------

```julia

@match [1, 2, 3] begin
    Many(::Int) => true
    _ => false
end # true

@match [1, 2, 3,  "a", "b", "c", :a, :b, :c] begin
    Do(count = 0) &&
    Many(
        a::Int && Do(count = count + a) ||
        ::String                        ||
        ::Symbol && Do(count = count + 1)
    ) => count
end # 9
```

They may be not used very often but quite convenient for some specific domain.

Ast Pattern
--------------------------

This is the most important update since v0.2.

To be continue. Check `test/expr_template.jl` or `test/dot_expression.jl` to get more about this exciting features.
