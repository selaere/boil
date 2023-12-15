iota `!` and where `?` are two pretty common functions when working with lists. at first they seem a bit abstract. their names aren't very enlightening at least.

```
4! .. { 0 1 2 3 }          okay?
7! .. { 0 1 2 3 4 5 6 }    that's not very interesting
0 1 2 3 4 ,?    .. { 1 2 2 3 3 3 4 4 4 }    what would i need that for ?
0 1 0 0 1 1 ,?  .. { 1 4 5 }                huh
```
these are already useful in their own. you can use `?` to get the first index of an item in a list like:
```
3 4 2 5 1 7 8 ,5= ? 0  .. 5
```
but they are mostly useful because of the meaning boil gives lists of numbers when used as functions. a list of indices applied to a list selects, or indexes, or applies a permutation.
```
"0abcdef"  3 0 6 6 5 5 ,  .. "c0ffee"
```
now you can see how playing around with the lists given by `!` can be useful for shuffling items around, and `?` can be useful for removing or replicating items.

now remember that, because of currying, a function `F` being applied to `x` and `y` is the same as the result of applying `F` to `x` being applied to `y`. this means that `!` and `?` have alternative meanings when applied with two arguments.


now we have functions that are, as i say, _accidentally ambivalent_. it's pretty common in the APL world to have functions that mean different things depending on how many arguments they are given, but this is something that we can't do with currying: but these two functions are _the same thing_ due to how application works.

|usage | names               | example
| ---: | ------------------- | -------
|  `x!`|iota, range          |`5! .. { 0 1 2 3 4 }`
|`x y!`|reshape, take, prefix|`"beefeater" 3! .. "bee"`
|  `x?`|where, indices       |`0 1 0 1 2 ,? .. { 2 4 5 5 }`
|`x y?`|replicate, mask      |`"bevel"  1 1 0 1 0 ,?  .. "bee"`

look! that `?` is just a filter!
```
9 1 2 3 8 4 7 2 4 9 ,x.  x  x 5< ?  .. { 1 2 3 4 2 4 }
```

iota is expanded to be useful when used with two arguments. defining iota for a negative argument is not obvious, but if we define it like this:
```
5-! .. { -5 -4 -3 -2 -1 }
```
then a negative argument takes from the right:
```
"beetlejuice" 5-!  .. "juice"
```
in the same way, we can define iota for lists of integers as outputting a nested list with that shape:
```
    3 4 2 ,!
{
    { { 0 1 } { 2 3 } { 4 5 } { 6 7 } }
    { { 8 9 } { 10 11 } { 12 13 } { 14 15 } }
    { { 16 17 } { 18 19 } { 20 21 } { 22 23 } }
}
```
and then we get something that works like APL's reshape:
```
    )s "CoNiCuZnRhPdAgCdIrPtAuHg"  3 4 2 ,!
{
    { "Co" "Ni" "Cu" "Zn" }
    { "Rh" "Pd" "Ag" "Cd" }
    { "Ir" "Pt" "Au" "Hg" }
}
```
anyways here are some useful definitions of common list operations

## rotate

we've seen this already
```
"catnip" 2(+  # !: :` :  ^:) .. "tnipca"
```

## pair

for some reason I need a function that creates a list with two elements passed in as arguments. `;` does this for numbers, but I need to pass it lists as well. how do I do this?

easy:

```
"one" "two"(y.x. x y ,) .. { "one" "two" }
```
i can even make it tacit if you want. `,` is very much not a function, but if i combine `$` and `;`...
```
"one" "two"y.x. x$ y$;        .. { "one" "two" }
"one" "two"y.x. x$ y($ ;:)    .. { "one" "two" }
"one" "two"y.x. x$ y($ ;:)    .. { "one" "two" }
"one" "two"y. $ y($ ;:):      .. { "one" "two" }
"one" "two"y. y($ ;:) $(:`)   .. { "one" "two" }
"one" "two"($ ;:  $ :` :)     .. { "one" "two" }
... or otherwise
"one" "two"y.x. x$ y$;        .. { "one" "two" }
"one" "two"y. $ y$;:          .. { "one" "two" }
"one" "two"y. y$;: $[         .. { "one" "two" }
"one" "two"($ ; : $[ ,:/)     .. { "one" "two" }
"one" "two"($ ;: :: $[:)      .. { "one" "two" }
```
woa that's ugly. i would rather write the non-tacit one. isn't there another way?

remember that when arrays are called, each of their members will be called with the same argument:
```
45  1+ 1-+ ,  .. 46 44
```
aha! so we can do this:
```
"one" "two"(y.x.x y.x.y ,)
```
these are two common combinators. the second is the definition of `@`, and the first may be written as `]@` or `` @` `` (just the flipped version of `@`).
```
"one" "two"(@` @;)    .. { "one" "two" }
"one" "two"(]@ @;)    .. { "one" "two" }
```
it might be a little strange how this still works even when we're being passed two arguments. if we see the partially evaluated version, this becomes more clear:
```
"two"(]@ @;)  .. { ] ( "two" @ ) }
```
now, the two elements are the identity (so the next argument will go there) and a constant argument (from the previous argument.)

## reversing

the simplest way is to fold with swapped concatenation:
```
"catnip" ;`/ .. "cpinta"
```
but this only works if the elements inside are scalars. it will flatten the list, like `;/` would.
```
"cat" "dog" "fox" ,;`/ .. "foxdogcat"
```
we can make this work by prepending an empty list, and enclosing the list when concatenating:
```
"cat" "dog" "fox" ,  0!$ ;`  (b.a. b$ a;)/    .. { "fox" "dog" "cat" }
"cat" "dog" "fox" ,  0!$ ;`  (b.a.  a b$ ;`)/ .. { "fox" "dog" "cat" }
"cat" "dog" "fox" ,  0!$ ;`  $ ;`: /          .. { "fox" "dog" "cat" }
```
or easier, wrapping each element in a singleton:
```
"cat" "dog" "fox" , $' ;`/    .. { "fox" "dog" "cat" }
```

there's an easier way, by using the domain:

```
"catnip"  # !:  .. { 0 1 2 3 4 5 }
```

for this we're going to take advantage that the indices are cyclic in both directions, so `x 1-` is the last element. we can try to negate the arguments:

```
"catnip"  # !: -: ^  .. "cpinta"
```

huh, not quite. the index 0 has to become -1, the index 1 has to become -2... let's try adding one before negating!

```
"catnip"  # !: 1+: -: ^  .. "cpinta"
```

## transpose

as with reversing, there is a neat short method that works for non-nested tables. for this we will use concatenate zip `;|`:

```
    1 2 3 ,  4 5 6 ,;|
{ { 1 4 } { 2 5 } { 3 6 } }
```
aha! we can just reduce that over a table and it will be transposed!
```
    5 5 ,!
{
    { 0 1 2 3 4 }
    { 5 6 7 8 9 }
    { 10 11 12 13 14 }
    { 15 16 17 18 19 }
    { 20 21 22 23 24 }
}
    5 5 ,| ;|/
{
    { 0 5 10 15 20 }
    { 1 6 11 16 21 }
    { 2 7 12 17 22 }
    { 3 8 13 18 23 }
    { 4 9 14 19 24 }
}
```
note that, with uneven matrices, this will choose the minimum column size. this is because zip `|` picks the smaller of the two lengths when making the new list.
```
    1 2 3 4 ,  4 5 6 ,  7 8 ,  9 10 11 12 ,  ,;|/
{ { 1 4 7 9 } { 2 5 8 10 } }
```
neat. but what if we have a table like this?
```
"cat" "cog" ,  "dat" "dog" ,  ,;|/    .. { "catdat" "cogdog" }
```
oh! it got flattened! hardly surprising. `;` is quite prone to flattening. let's wrap every cell. using two eaches `F''` means that it will wrap cells deeper:
```
"cat" "cog" ,  "dat" "dog" ,  ,$''  ;|/    .. { { "cat" "dat" } { "cog" "dog" } }
```
therefore, `$'' ;|/:`
## windows
get overlapping windows of a list of a length n. like this!
```
    "beehive" 5Windows Print'
beehi
eehiv
ehive
```
how can we write that? well, observe that the number of windows of size _n_ for a list of size _k_ is `n-k+1`
```
"beehive"  5 n.l. l# n-+ 1+ .. 3
```
then use `!` to get the indices where the windows will start,
```
"beehive"  5 n.l. # n-+ 1+ ! .. { 0 1 2 }
```
and add `n!` (in this case, { 0 1 2 3 4 }) to each of them,
```
"beehive"  5 n.l. l# n-+ 1+ ! n!+' .. { { 0 1 2 3 4 } { 1 2 3 4 5 } { 2 3 4 5 6 } }
```
aha! we've finished. now just apply this to the original list,
```
"beehive"  5 n.l.l(l# n-+ 1+ ! n!+') .. { "beehi" "eehiv" "ehive" }
```

removing one argument from this closure is pretty easy. we see again the pattern of using `^` to rearrange a list in some way:
```
"beehive"  5 n. # n-+: 1+: !: n!+': ^ .. { "beehi" "eehiv" "ehive" }
```
removing the other is a pain. it's used multiple times, and not at the start of the expression, so we have to rearrange and swap a bunch of things. don't bother. i bothered.
```
n. # n-+: 1+: !: n!+': ^
n.  n-+ 1+:  # :`  !:  n!+':  ^
n. n(-  +  1+:  # :`  !:  ,:/) nX.X!+': ^        .. this is really a S combinator
n. n(- 1+:  +  # :`  !:  ,:/) nX.X!+': ^         .. more convenient precedence
n. n n(- 1+:  +  # :`  !:  ,:/  x.x!+': ` :)   ^ .. insert the !+':. :/ ` into the list
- 1+:  +  # :`  !:  x.x!+': `  ,:/  ^  ^:        .. woa that is two ^s
- 1+:  +  # :`  !:  !+':, :/ `  ,:/  ^  ^:       .. i guess x.x counts as a lambda

```
but don't bother.
