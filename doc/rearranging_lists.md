## rotate

we've seen this already
```
"catnip" 2(+  # !: :` :  ^:) .. "tnipca"
```

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
"cat" "dog" "fox" ,  0!] ;`  (b.a. b] a;)/    .. { "cat" "dog" "fox" }
"cat" "dog" "fox" ,  0!] ;`  (b.a.  a b] ;`)/ .. { "cat" "dog" "fox" }
"cat" "dog" "fox" ,  0!] ;`  ] ;`: /          .. { "cat" "dog" "fox" }
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
n. n(~  +  # :`  !:  ,  :/) n(!+':, :/) ^         .. this is really a S combinator
n. n n(~  +  # :`  !:  ,  :/  !+':, :/ ` :)   ^   .. insert the !+':. :/ ` into the list
~  +  # :`  !:  !+':, :/ `  ,  :/  ^  ^:          .. woa that is two ^s
```
but don't bother.
