
## introduction

you can write numbers like any language. symbols are functions: some simple ones are `-` (negate), `%` (reciprocal), `_` (floor) and `!` (iota).
```
3-    .. -3
4%    .. 1/4
4.2_  .. 4
5!    .. { 0 1 2 3 4 }
```
functions are written after what they apply to. `xF` is the result of calling *F* with *x* as an argument.

you can chain functions easily by writing them next to each other. in other words, application is left associative.
```
4.2-_-  .. 5
4%%     .. 4
5!-     .. { 0 -1 -2 -3 -4 }
```

functions in boil take only one argument and return only one value. our way of writing functions like `+` (add) is through [currying](https://en.wikipedia.org/wiki/Currying). `1+` is a function that adds one to the argument:

```
1 1+     .. 2
3 4+     .. 7
3 4+ 5+  .. 12
5 3+ 4-+ .. 4
```
so more precisely `+` (add) is a function that, given a number, makes a function that adds that number. `1+` is not a number yet, it needs another argument to be fulfilled, so we call it again with another argument like `3(1+)` or `3 1+` to get the result.

see that boil allows using whitespace to separate expressions visually. so expressions can be written with parentheses `5(3+)(4-+)` or spaces `5 3+ 4-+`, and the result is the same.

```
5(3+)(4-+)     .. 4 (with parentheses)
5 3+ 4-+       .. 4 (with spaces)
5  3 +  4 - +  .. 4 (with even more spaces)
```
but once you start using functions with several arguments, or using the results of functions as functions, you need some structure with spaces or parentheses. `5 3 +` doesn't work because it's going to try to call 3 with 5, instead of adding.

### lists

apart from numbers and functions, we also have lists. `!` (iota) takes a number and returns a list with that many numbers counting from zero. and `;` (concatenate) is another two argument function that can be used for building up lists.

```
1 2; 3; 4; 5; .. { 1 2 3 4 5 }
5!            .. { 0 1 2 3 4 }
```

apart from the functions, there are two ways in the syntax for writing literal lists. text strings written with quotes are lists with the codepoints of its characters:
```
"hello"       .. { 72 69 76 76 79 }
```
or use list literals! `,` puts the expressions before it a list, overriding the usual function calling syntax. they can be nested:

```
1 2 3 ,                 .. { 1 2 3 }
1 2 3 ,  4 5 6 ,  ,     .. { { 1 2 3 } { 4 5 6 } }
```

to nest lists using functions it's useful to use `$` (wrap). it wraps its argument in a one element list.
```
5!$     .. { { 0 1 2 3 4 } }
5!$$    .. { { { 0 1 2 3 4 } } }
1 2; 3; $  4; 5; 6; $ ; .. { { 1 2 3 } { 4 5 6 } }
```

mathematical operations apply to every element in a list. for operations between lists, the elements are paired up.
```
5!-                .. { 0 -1 -2 -3 -4 }
5! 1+              .. { 1 2 3 4 5 }
5!  1 1 0 2 1 , *  .. { 0 1 0 6 5 }
1 2 3 ,  4 5 6 , + .. { 5 7 9 }
```
there is also `/` (fold), a two argument function used like `x F/`, that builds up a value by calling the function F between every element in x.
```
4 5+ 6+ 2+ 1+   .. 18
4 5 6 2 1 , +/  .. 18
```
and of course `#` (length) to get the length of a list.
```
4 5 6 , #    .. 3
```
### indexing
not all values are functions, but every value can be called with any argument.
all integers are functions that index into lists. the first element is always 0, so `0` is a function that gets the first element. 
```
0 1 4 9 16 25 , 4   .. 16
3 9 ,  5 4 ,  , 1 0 .. 5
```
these indices are cyclic, so `1-` always gets the last element.
```
4 3 2 , 1-     .. 2
4 3 2 , 0      .. 4
4 3 2 , 1      .. 3
4 3 2 , 2      .. 2
4 3 2 , 3      .. 4
```
there are no character literals, but `"$"0` does the job fine. of course a character is just an integer.
```
"bees" 4  .. "b"0
"bees" 1- .. "s"0
```
when lists are called, they call each element with the same argument:
```
4  1+ - 2* ,  .. { 5 -4 8 }
```
thus by applying a list of integers, we can select those indices from the array. we can use this to extract elements from a list. also, if the index list has the same length as the argument and the indices are unique, calling it is the same as applying a permutation.
```
"catnip"  1 4 ,          .. "ai"
"catnip"  0 0 0 ,        .. "ccc"
"catnip"  3 4 5 0 1 2 ,  .. "nipcat"
```
with this we can implement many useful list operations. rotating a list is as easy as adding a number to its indices, and calling it with the original array:
```
"catnip"  "catnip"#! 2+  .. "tnipca"
```
### functions
we can even use lambdas (closures) to turn this into a function. `x. y` is a function that binds the argument to the name `x` and calls `y`.
```
5  x. x x *   .. 
"catnip"   l.  l  l#! 2+   .. "tnipca"
```
if you want to take multiple arguments, you can just write multiple `x. y.`s to take multiple arguments.
```
"catnip" 2  n. l.  l  l#! n+  .. "tnipca"
"catnip" 2n.l.  l  l#! n+     .. or this
"catnip" 2n.l.l(l#! n+)       .. or this. you pick
```
still, boil has a bunch of combinators you can use to avoid writing lambdas. here's a list! they also have letters if you're that kind of nerd

| name | usage | result
| --: | --: | ---
| id | `x]` | `x`
| thrush | `F x[` | `xF`
| swap | `` x  y F` `` | `y xF`
| self | `x F^` | `x xF`
| compose | `x  F G:` | `xFG`
| const | `x y@` | `y`

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
we can still reduce this to not use any lambdas at all, but it's not usually worth it. if you play with the combinators for a bit, you might arrive to something like this. `` F  G :` `` is reverse compose ("prepose"), i think of it as adding a step to do before the function (get the domain _before_ we add)
```
"catnip" 2n.(n  +  # !: :`  ^)
```
turning this into a function just means composing all functions together (because of boil's syntax, this means adding a `:` to every function but the first one)
```
"catnip" 2(+  # !: :` :  ^:) .. "tnipca"
```

with these combinators you can build other combinators, if you feel like it. in fact, you can build [all combinators](combinators.md).

we can define this function to use it later. we just use the lambda syntax for name definition:

```
+  # !: :` :  ^:     Rot.

"catnip" 4Rot    .. "ipcatn"
```

by writing the dot at the end of the line, the syntax makes sure that the function body wraps all the rest of the program. so in practice the name `Rot` has been defined for later use.


### fin

that was a brief outline of how boil works. now you can play around with the things you know, look at the [list of primitives](../README.md#primitives), or [read more stuff](../README.md#read_more).