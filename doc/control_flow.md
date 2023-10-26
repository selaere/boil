## choice
there is definitely more than one way of executing a different function based on a value. but the easiest way is to have a list with functions, and index into it. you can write it either with concatenation `,` (which treats functions as scalars, you don't have to enclose `]` them) or with list literals `f g h .`.

making the absolute number is just picking from `;-.` (or `; -,`) based on the sign of the value:

```
5-  n.   n   ;-.  n 0<  ;; => 5
5-  n.  n  n 0< ;-.[    ;; using swid `[`:
5-  0< ;-.[: ^          ;; and then ^ify
5-  ;-. 0<` ^           ;; shorter, weirder alternative
```

## iteration
bounded-length iteration is pretty easy. try using `!` (iota), `'` (each) and `/` (reduce).
```
5! 1+ */  ;; wow!
```

repeating a single function multiple times can be done in multiple ways. knowing that `n?` for a scalar n returns a list of zeroes of length n:
```
21  3 ](f. n. f n? :/        ) ;; doesn't work for n=0
21  3 ](f. n.  f n?  ; ,`  :/)
21  3 ](f. n.  f n? , ;/:    ) ;; or if we're adding an identity element anyways..
21  3 ](f. n. n? , f@/:      ) ;; ignoring the zeroes added by `?` with `@`
;; { { { 21 } } }
```


## recursion
do you want a WORSE way of writing fibonacci?

if you can do something without recursion, definitely do. boil has no built-in way of writing unbounded loops, or recursion, and it also doesn't have any tail-call optimization. but you can write your own ("fix-point") combinator that does the same thing.

say i have written a function like this:

```
L. n.  1-+ L: *`: ^ 1@,  n 2<  n[
```
this returns `L(n-1)*n` if `n<2`, otherwise it just returns `1`. we want to, somehow, pass this function to itself, defining a combinator `Y` where `FY = FYF`. you can try to figure it out yourself, or do what i did and look it up in the internet.

aha! a so-called "Haskell Curry" wrote something like this:
```
F. (X. XXF)(X. XXF)  Y.

fY = (X. XXf)(X. XXf)
   = (X. XXf)(X. XXf)f
   = fY f
```
nice! that works. except it doesn't. if you try to use it, you will get a very scary "`Call stack overflow`" error. in short, what's happening here is that boil uses eager evaluation (instead of "lazy evaluation") and evaluates every function call it comes across. this means that it is going to automatically go
```
fY = fY f = fY f f = fY f f f = fY f f f f ...
```
and never stop. we can get around this by wrapping the self-evaluation `XX` in a function, like this:
```
F. (X. (v. v XX)F)(X. (v. v XX)F)  Z.
```
this is called eta-expansion. `x. x 1+` is obviously the same as `1+`, but the `+` first argument will only be passed when the second argument is given. this can end up being useful when the computation of `1+` can loop infinitely if we're not careful.
```
5 (l. n.  1-+ l: *`: ^ 1@,  n 2<  n[)(F. (X. (v. v XX)F)(X. (v. v XX)F)) ;; 120
```
it works! let's shorten it now. see that the term `X. (v v XX)F` is used twice:
```
F. (X. (v. v XX)F) A. AA  Z.
```
we see this kind of self-application twice, that can be written as `;^`
```
F. (X. (v.  v  X ;^)F) ;^  Z.
```
now, getting rid of the `v.  v  X ;^` is actually a bit tricky. i have a trick up my sleeve. see how ``` f`` ``` does nothing, it swaps the two arguments twice, but now it has two take two elements? this is the same as the eta-expansion we needed earlier!
```
F. (X. X`` ;^ F) ;^  Z.
```
and if we make it fully tacit, 
```
(F. (` `: ;^ F) ;^)
(F. (F  ` `: ;^: :`) ;^)
(F.  F  ` `: ;^: :` ;^:)
```
we get this symbol soup,
```
` `: ;^: :` ;^:  Z.
```
which there may very well be a better way to write. let's try it!
```
    5   (l. n.  1-+ l: *`: ^ 1@,  n 2<  n[)  ` `: ;^: :` ;^:
120
```
yay !!