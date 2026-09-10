# combinators

the set of combinators that boil provides are shown here:

| name | usage | result | letter |
| --: | --: | --- | ---
| id | `x]` | `x` | I
| thrush | `F x[` | `xF` | T = CI
| swap | `` x  y F` `` | `y xF` | C
| self | `x F^` | `x xF` | W
| compose | `x  F G:` | `xFG` | B
| const | `x y@` | `y` | K

identity is the most fundamental combinator! or the most boring one. your choice. applying it to something at 0 depth is useless:

```
1]]]]]]]]]]]]]]]] 1]]]]]]]]]+]]]]]]]]  .. 2
```
it is somewhat useful when not directly applied to something. because of currying, `x]` _identity_ also means `x y]` _apply_ when used with two arguments. self-application `]^` is [pretty useful for recursion](control_flow.md). you can use self-zip `]|` for applying different functions to each element in a list:
```
    "09"  <>, ]|
{ ( '0' < ) ( '9' > ) }
```
`]/` almost feels like the inverse of `,`, evaluating the expression that was "quoted" by the comma.
```
    3 1+ 3* 2-+ 2%*
5
    3 1+ 3* 2-+ 2%* ,
{ 3 ( 1 + ) ( 3 * ) ( -2 + ) ( 1/2 * ) }
    3 1+ 3* 2-+ 2%* , ]/
5
```
`]\` is neat for progressively applying functions. maybe it could be useful for debugging?
```
    3 1+ 3* 2-+ 2%* , ]\
{ 3 4 12 10 5 }
```
still, eh. it can be written as a combination of the other combinators, i like `@^`: `^` duplicates the argument, and `@` ignores it, so it just ends up doing nothing.
```
   x @^
-> x x@
-> x
```
most of the reason why it's a single character is because it is quite convenient to have inside of list literals. we do this usually in order to conditionally apply a function:
```
    5 -],
{ -5 5 }
```
## thrush
if `]` is application, then `[` is swapped application. `[` is `` ]` ``. the symbol is flipped! i think that makes sense.

another reason for that symbol is that it is nice to think of it as indexing:
```
2 1+ "words"[   .. "d"0
2 1+ "words"[]  .. the same, ] does nothing
```
like this, it just looks like some strange reversal of the indexing syntax you would find in languages like python: `"words"[2+1]`. of course, you could write it like this:
```
"words"  2 1+   .. "d"0
```
but then you need to introduce more whitespace. if the index is a complex expression, and the array a constant or a variable, this can be much more convenient.

this is the general pattern of the thrush. you can always do away with it. but it's convenient to rearrange stuff around! sometimes removing it is unwieldy.

with `[/` you can almost pretend that you are using ordinary combinatory logic:
```
` ; 2 3 ,[/  .. { 2 3 }
```
thrush is closely related to swap. we can use thrush a lot of the time we might want to use swap:
```
    2  3 ;`
{ 3 2 }
    2 ; 3[
{ 3 2 }
```
now this is some kind of.. weird backwards infix syntax? fine i guess

a thing you might come across while converting stuff to a tacit form is `x[:` or `[ ::`.
```
   y  F x[:
-> y F x[
-> x yF
```
this is the same as `` x F` ``:
```
   y  x F`
-> x  y F
-> x yF
```
but if `x` is a constant, and `F` a complex function, `F x[:` will be shorter! and maybe even easier to understand.

## composition

`:` compose is the most basic way of composing two functions, but not the only one. look at this way of getting the mean of two numbers:
```
2 8+ 2%* .. 5
```
pretty simple! how do we turn it into a function? well, just compose the two functions!
```
    2 8(+ 2%*:)
Error in primitive : being called with arguments ( 1/2 * ) + 8:
Error in primitive * being called with arguments 1/2 ( 8 + ):
function-unexpected
```
whoops. `2 8(+ 2%*:)` is the same as `2  8+ 2%*:`, not `2 8+ 2%*:`. we need a composition that passes on two arguments. luckily, this isn't too hard:

```
   y.x. x y+ 2%*
-> y.     y+ 2%*:
->         + 2%*::
```
this works for three or four arguments as well. for every argument that we compose over, we just need to add another colon!

another example is making a function that concatenates three arguments. as a lambda, `z.y.x. x y; z;` is the shortest way of doing this, but it's actually a lot easier to compose when written as `z.y.x.  x  y z; ;`, knowing that list concatenation is associative:
```
..messy:
   z.y.x.  x y; z;
-> z.y.      y; z;:
-> z.         ; z;::
-> z.           z;:  ; :`
->              ; ::  ; :`

..better:
   z.y.x.  x  y z; ;
-> z.y.       y z; ;
-> z.           z; ;:
->               ; ;::
```

function composition is also associative: `x y: z:` is the same as `x  y z: :`. equivalently, `a b: c: d: :` is the same as `a: b:: c:: d::`, which reads neatly: applying `:` compose to a composed function is the same as applying `:` compose to each of its parts.

another composition that is very common is `` F G`: ` ``, applying two different functions to two different arguments:
```
   x   y  F G`: `
-> y   x  F G`:
-> y   x F G`
-> xF yG
```

## S combinator
one of the most famous combinators is the S combinator, `λgfx.gx(fx)`, which in boil looks like <code>x&nbsp;&nbsp;F&nbsp;GS&nbsp;=>&nbsp;xF&nbsp;xG</code>. it's a little tough to define 
```
G.F.x. xF xG        .. note how the args are listed backwards
G.F.x.  x  x F G`   .. x yF => y  x F`
G.F.x.  x  x  F G`: .. xFG => x  F G:
G.F.x.  x  F G`: ^  .. x xF => x F^
G.F. F G`: ^        .. η reduction
G.F. F  G`: ^:      .. xFG => x  F G:
G. G`: ^:           .. η reduction
G. G ` : ^:         .. (space things out)
G. G  ` :: ^::      .. xFGH => x  F G: H:
` :: ^::            .. yay
```

take as an example `! ;S`, which is `x. x! x;`. defining `S`:
```
` :: ^:: S.  4  ! ;S  .. { 0 1 2 3 4 }
```
or using it tacitly, as we saw before that `` G F`: `` = `F GS`:
```
4  ! ;`: ^  .. { 0 1 2 3 4 }
```

## minimal basis?

S is used in the [SKI combinator calculus](https://en.wikipedia.org/wiki/SKI_combinator_calculus): we already have the K = `@` and I = `]` combinators. it is a minimal set of combinators, with which you can write any lambda calculus term and really do any arbitrary computation (without using any numbers or lists!)

we don't need to define S to have the power of SKI calculus. a well known equivalent system is the [BCKW system](https://en.wikipedia.org/wiki/B,_C,_K,_W_system) which matches with the combinators we already have: B = `:`, C = `` ` ``, K = `` @ ``, W = `^`. i like the BCKW set better because the individual combinators are simpler, so all of them are in boil.

interestingly, replacing swap by thrush, ``: [ @ ^``, also yields a minimal system. to prove this we need to redefine swap using these combinators. we can do this using `:` compose and `[` thrush using a trick we've seen earlier:

```
   x  y F`
-> x F y[
-> x (F y[:)
-> x (y[: F[)
-> x y([ :: F[:)
-> x y(F[ ::  [ :: [)
-> x  y F([ ::  [ :: [ :)
```
huh. wait i think i can factor some stuff out. lemme give the name `R` to `[ ::`,
```
-> x  y F([ :: R. R RR)
```
huh??? ok so if i apply the combinator `[ ::` to itself, and then do that again, i get `` ` `` swap??

```
.. remember:  x  y zR
..        ->  z  x y
   x    y   F  R RR
-> x    y   R  F R
-> x   y  R FR
-> x   y  R FR
-> x   F  y R
-> x  F yR
-> x  F yR
-> y  x F
-> y xF
```
ok. fine. so you can write `` ` `` as `[ ::  [ :: [ :`. or, if you prefer, `[ :: [^^`, where `[^^` is self-self-application and does the same thing as `]^^` or `X. X XX`.
