
## introduction
functions are postfix, i.e. `xF` represents calling *F* with *x* as an argument.
```
3-    .. -3
4%    .. 1/4
4.2_  .. 4   (floor)
5!    .. { 0 1 2 3 4 }
```
application is left associative, so you can chain functions easily
```
4.2-_-  .. 5
5!-     .. { 0 -1 -2 -3 -4 }
```
boil uses currying for functions with multiple arguments. `1+` is a function that adds one to the argument, and you can call it like this:

```
1 1+     .. 2
3 4+ 5+  .. 12
5 3+ 4-+ .. 4
```
see that boil uses whitespace to separate expressions visually. we could also use parentheses, like `5(3+)(4-+)`. but that looks very ugly.

you can use `;` (concatenate) or `!` (iota) to build lists. strings are lists of codepoints.

```
1 2; 3; 4; 5; .. { 1 2 3 4 5 }
5!            .. { 0 1 2 3 4 }
"hello"       .. { 72 69 76 76 79 }
```
or use list literals! `,` takes all expressions in the same depth and puts them in a list. lists can be nested, and `x$` wraps x in a 1-element list.

```
1 2 3 ,                 .. { 1 2 3 }
1 2 3 ,  4 5 6 ,  ,     .. { { 1 2 3 } { 4 5 6 } }
1 2; 3; $  4; 5; 6; $ ; .. { { 1 2 3 } { 4 5 6 } }
```

mathematical operations pervade into lists:
```
5! 1+              .. { 1 2 3 4 5 }
5!  1 1 0 2 1 , *  .. { 0 1 0 6 5 }
```
there is also `x F/` fold, that builds up a value by calling the function F between every element in x.
```
4 5+ 6+ 2+ 1+   .. 18
4 5 6 2 1 , +/  .. 18
```
all integers are functions that index into lists. these indices are cylic, so `1-` is a function that gets the last element.
```
0 1 4 9 16 25 , 4   .. 16
3 9 ,  5 4 ,  , 1 0 .. 5
4 3 2 , 1-          .. 2
```
there are no character literals, but `"$"0` does the job fine
```
"bees" 4  .. "b"0
"bees" 1- .. "s"0
```
and when lists are called, they call each element with the same argument:
```
4  1+ - 2* ,  .. { 5 -4 8 }
```
combining both of these properties, by applying a list of integers, we can select those indices to the array. if the list has the same length as the argument and the indices are unique, this is the same as applying a permutation.
```
"catnip"  4 5 6 1 2 3 ,  .. "nipcat"
```
with this we can implement many useful list operations. rotating a list is as easy as adding a number to the domain (`x#` is length), and calling it with the original array:
```
"catnip"  "catnip"#! 2+  .. "tnipca"
```
we can even use lambdas (closures) to turn this into a function. `x. y` is a function that binds the argument to the name `x` and calls `y`.
```
"catnip"   l.  l  l#! 2+   .. "tnipca"
```
because of currying, you can just have multiple `x. y.`s to take multiple arguments.
```
"catnip" 2  n. l.  l  l#! n+  .. "tnipca"
"catnip" 2n.l.  l  l#! n+     .. or this
"catnip" 2n.l.l(l#! n+)       .. or this. you pick
```
still, boil has a bunch of combinators you can use to avoid writing lambdas. here's a list! they also have letters if you're that kind of nerd

| name | usage | result | letter |
| --: | --: | --- | ---
| id | `x]` | `x` | I
| thrush | `F x[` | `xF` | T = CI
| swap | `` x  y F` `` | `y xF` | C
| self | `x F^` | `x xF` | W
| compose | `x  F G:` | `xFG` | B
| const | `x y@` | `y` | K

we can turn `l # ! n+` into a single function call by composing `:` all the functions together:
```
"catnip" 2n.l.(l   l  # !: n+:)
```
and remove the two mentions of `l` using self `^`:
```
"catnip" 2n.l.(l  # !: n+: ^)
```
a lambda that just consists of the argument being called with a constant function is the same as the function itself (this is called "eta reduction"), so we can reduce this into:
```
"catnip" 2n. # !: n+: ^  .. "tnipca"
```
we can still reduce this to not use any lambdas at all. if you play with the combinators for a bit, you might arrive to something like this. `` F  G :` `` is reverse compose ("prepose"), i think of it as adding a step to do before the function (get the domain _before_ we add)
```
"catnip" 2n.(n  +  # !: :`  ^)
```
turning this into a function just means composing all functions together (because of boil's syntax, this means adding a `:` to every function but the first one)
```
"catnip" 2(+  # !: :` :  ^:) .. "tnipca"
```

with these combinators you can build other combinators, if you feel like it. in fact, you can build all combinators. here is the infamous S combinator, for example (<code>x&nbsp;&nbsp;F&nbsp;GS&nbsp;=>&nbsp;xF&nbsp;xG</code>, or `λgfx.gx(fx)`)
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

and we can use like this! the syntax for lambdas also works for assignment:
```
` :: ^:: S.  4  ! ;S  .. { 0 1 2 3 4 }
                      .. 4  ! ;S  ===  4! 4;
```

that was a brief outline of how boil works. now you can play around with the things you know, look at the [list of primitives](../README.md#primitives), or [read more stuff](../README.md#more-words).