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
we can make this a little shorter if we see that `n-k+1 = n-(1-k)`, and `1-x` is defined as `~`:
```
"beehive"  5 n.l. l# n~+ .. 3
```
what a useless little golfing trick. then use `!` to get the indices where the windows will start,
```
"beehive"  5 n.l. # n~+ ! .. { 0 1 2 }
```
and add `n!` (in this case, { 0 1 2 3 4 }) to each of them,
```
"beehive"  5 n.l. l# n~+ ! n!+' .. { { 0 1 2 3 4 } { 1 2 3 4 5 } { 2 3 4 5 6 } }
```
aha! we've finished. now just apply this to the original list,
```
"beehive"  5 n.l.l(l# n~+ ! n!+') .. { "beehi" "eehiv" "ehive" }
```

removing one argument from this closure is pretty easy. we see again the pattern of using `^` to rearrange a list in some way:
```
"beehive"  5 n. # n~+: !: n!+': ^ .. { "beehi" "eehiv" "ehive" }
```
removing the other though, is a pain. you can see it's used multiple times, and not at the start of the expression, so we have to rearrange and swap a bunch of things. don't bother. i bothered.
```
n. # n~+: !: n!+': ^
n.  n~+  # :`  !:  n!+':  ^
n. n(~  +  # :`  !:  ,:/) nX.X!+': ^         .. this is really a S combinator
n. n n(~  +  # :`  !:  ,:/  x.x!+': ` :)   ^ .. insert the !+':. :/ ` into the list
~  +  # :`  !:  x.x!+': `  ,:/  ^  ^:        .. woa that is two ^s
~  +  # :`  !:  !+':, :/ `  ,:/  ^  ^:       .. i guess x.x counts as a lambda

```
but don't bother.
