here are the arithmetic primitives in boil. i also figured out how to use latex look

| name | usage | result |
| --: | --: | :-:
| add | `x y+` | $x+y$
| multiply | `x y*` | $x\cdot y$
| negate | `x-` | $-x$
| reciprocal | `x%` | $\frac 1 x$
| floor | `x_` | $\lfloor x \rfloor$
| min | `x y{` | $\min(x,y)$
| max | `x y}` | $\max(x,y)$

doesnt that look cool? so academic

## arithmetic
it might seem weird that there's no division or subtracton. instead there are functions for negation `-` and reciprocals `%`. the way you subtract is by writing `x y-+`, and division is `x y%*`. or, if it's more convenient, like `y- x+` and `y% x*`.

i forgot why i did it like this! probably because i realized both subtraction and negation wouldn't fit in the character set, and i would have to figure out how negative number literals work. it's not that bad though. i also like that $1-x$ is `x- 1+` instead of something like ``x  1 -` ``. 1-argument functions compose better! i like composition

but if you do want them as tacit functions, you'll have to write `- +:` and `% *:`.

so, the 2-argument arithmetic functions are addition `+` and multiplication `*`. it's also neat that these have neat properties: they are both _commutative_ (`x y+` = `y x+`) which can be useful for rearranging stuff around. they are also _associative_ (`x y* z*` and `x  y z* *`). this one is fun! the former is shorter in explicit style, the latter is easy to [compose](combinators.md#composition) like `x  y z(* *::)`.

## floor (`_`)

the other maybe weirder thing is. what is floor `_` doing there?
```
    4.2_
4
    4.5_
4
    4.8_
4
```

seems like a weird choice. i dont need it too often, and there are a lot of other more mathy things missing from the primitives list

well have you seen? the glyph looks like a floor. an underscore. a low dash. floors are flat. floors are low. in the floor

but it can also be used for implementing useful operations with integers, like integer division, by flooring the result afterwards:
```
    72 20%* _
3
```
which made tacit is `% *: _::`. we can also write modulo, though it's a bit unwieldy. knowing that $\text{mod}(a,b) = a - b\left\lfloor\frac a b\right\rfloor$:
```
    72 20b.a.  a  a b%* _ b* - +
12
```
we can make this shallower by swapping the direction of addition:
```
    72 20b.a. a b%* _ b* - a+
12
```
or you can make the earlier one tacit:
```
b.a.  a  a b%* _ b* - +
b.a.  a  a b(% *: _::) b* - +
b.a.   a   a  b(% *: _::) b*: -: +:
b.a.   a   a  b(% *: _::) b(* ::) -: +:
b.a.   a   a  b(% *: _::  * :: ` :  ^) -: +:
b.a.  a  a b(% *: _::  * :: ` :  ^  -::  +::)
b.a.  a b(% *: _::  * :: ` :  ^  -::  +::  ^:)
% *: _::  * :: ` :  ^  -::  +::  ^:
% *: _::  * :: ` :  ^  -: +:: ^: :
% *: _::  * :: ` :  ^  - +: : ^: :
```
, if you can make sense of that

if you want ceiling $\lceil x\rceil$, that's just the same as negating before and after flooring (`- _: -:`).
```
    4.2-_-
5
```
and rounding a number is the same as adding 0.5 (or `2%`) before flooring:
```
    4.2 2%+ _
4
    4.7 2%+ _
5
```
except this always rounds up when the decimal part is exactly `.5`. which you might want or maybe not. another one that rounds down instead is `- 2%+: _: +:`. if you really care about it being ieee754 round to even then use `Round`.

## min (`{`) and max (`}`)
these are also weird additions. you can implement them with the comparison operators pretty easily. most of the reason for them to be there is that when restricted to arguments that are only 0 and 1,

|x|y|$\min(x,y)$|$\max(x,y)$|
|:-:|:-:|:-:|:-:|
|0|0|**0**|**0**
|0|1|**0**|**1**
|1|0|**0**|**1**
|1|1|**1**|**1**

huh. familiar. min is 1 when both arguments are 1s, and max is 1 when any argument is 1. in other words, min `{` is the AND gate, max `}` is the OR gate.

the symbols for min `{` and max `}` are confusing to tell apart, but the direction of the pointy bit corresponds to the less than `<` and greater than `>` symbols. as in, you are choosing which argument is lesser or greater.

getting the minimum `{/` and maximum `}/` of an array is pretty common, and these have the same glyph as all `{/` and any `}/`.

using these in boolean arrays with scan `\` gives what i call the "smear vectors": `}\` marks with ones after the first 1, and `{\` marks with ones until the first 0:
```
    1 1 1 0 1 0 1 1 ,{\
..{ 1 1 1 0 0 0 0 0 }
    0 0 0 1 0 1 1 0 1 0 ,}\
..{ 0 0 0 1 1 1 1 1 1 1 }
```

## number types

i did not think about the number representation format at all when designing the language. and the implementation is in factor, so it almost inherited its number system: bignums for integer literals, bigrats when dividing stuff, floats for decimal literals and math functions. then i realized that i was really close to having the "base" language work always with rationals, so i made decimal literals always return rationals and `_` always return an integer.

so here's a description of the number system how it exists now. there are two types of numbers: _rationals_ and _floats_. _rationals_ are a fraction $a/b$, where $a$ and $b$ are coprime arbitrary-precision integers, and $b>0$. floats are 64-bit floating point numbers from IEEE-754.

the following values are always rationals:
* number literals `12`, `3.45` (345/100)
* elements of string literals `"string"`
* the result of `x y+`, `x y*`, `x-`, `x%`, when all arguments are rationals
* the result of `x_`, when x is a number
* scalars returned by `!` `?` `#` `~`
* results of boolean functions `<` `=` `>` `&`

but `+` `*` `-` `%` return floating point numbers when any of their arguments are floating point. as well, the mathematical functions that are written with words (`Pow`, `Sin`) always return floats.

actually, that's a good reason to have floor `_` as a primitive but not `Pow`. exponentiation can return a irrational number even when both arguments are rationals, `2 2%Pow` is $2^\frac 1 2 = \sqrt 2$, which cannot be represented as a rational.

## the other mathematical functions
all of these pervade into lists. these return an error when their arguments are outside the domain (or, would return a complex number).
|function|math|
|-:|:-:|
|`xSin`|$\sin x$
|`xCos`|$\cos x$
|`xTan`|$\tan x$
|`xAsin`|$\sin^{-1}x$
|`xAcos`|$\cos^{-1}x$
|`xAtan`|$\tan^{-1}x$
|`xSqrt`|$\sqrt x$
|`xRound`|$\text{round}(x)$
|`xExp`|$e^x$
|`xLn`|$\ln x$
|`x yPow`|$x^y$

there is also `xDeco`, which takes a rational x and returns a 2-argument list `{ numerator denominator }`.