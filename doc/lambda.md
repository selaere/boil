# boil from a Lambda Calculus perspective

boil is similar to the untyped lambda calculus. There are a few obvious differences: we have more types other than lists and a bunch of special functions that are always defined.

Also boil has eager evaluation (or *applicative order*), which makes loops a little trickier: see [control flow](control_flow.md).

## Syntax


| Name | lambda | boil |
|---|---|---|
| abstraction | $\lambda x. M$ | `x.M`
| application | $M\,N$ | `(NM)`
| variables | $x$ | `x`

Some examples to show the spaces syntax. Parentheses also work fine. We like naming functions with uppercase letters (because `xf` is a single identifier) but it does not mean anything. There's no namespace distinction or anything, any value can be called with any other value.

| lambda | boil |
|---|---|
| $F\,x$ | `xF`
| $F\,x\,y$ | `y xF`
| $F\,x\,y\,z$ | `z  y xF`
| $G\,(F\,x)$ | `xFG`
| $H\,(G\,(F\,x))$ | `xFGH`
| $H\,(G\,(F\,x\,y))$ | `y xF G H`
| $F\,x\,(G\,y)$ | `yG xF`
| $x\,y\,z$ | `z  y x`
| $F\,(F\,(F\,(F\,x)))$ | `xFFFF`
| $(\lambda x.y)\,z$ | `z x.y`
| $\lambda x.\lambda y.\,y\,x$ | `x.y. y x`

### Combinators

See [combinators](combinators.md)

| letter | lambda definition | boil symbol | boil definition
| --: | :-- | --: | :--
| I = | $\lambda x.x$ | id `]` = | `x.x`
| T = | $\lambda f.\lambda x.\,x\,f$ | thrush `[` = | `x.F.xF`
| C = | $\lambda f.\lambda x.\lambda y. \,f\,y\,x$ | swap `` ` `` = | `F.x.y.  x yF`
| W = | $\lambda f.\lambda x. \,f\,x\,x$ | self `^` = | `F.x.  x xF`
| B = | $\lambda f.\lambda g.\lambda x. \,f\,(g\,x)$ | compose `:` = | `F.G.x. xGF`
| K = | $\lambda x.\lambda y.\,y$ | const `@` = | `x.y.y`

## Doing things the wrong way

We have our own types but do we have to use them? Not really. Let's define the usual types using only functions (abstractions) the lambda way.

### Church pairs

Remember that using `@` and `]@` we can choose one of two arguments given:
```
3  5 @   .. 5
3  5 ]@  .. 3
```
We can make a function that calls another with those arguments, and later call them with the combinators to choose them:

```
@   F. 3 5F  .. 5
]@  F. 3 5F  .. 3
```

See that `F. 3 5F` is a single function but it stores two values. It's a single value that we can pass around like a single value, but it stores two values. Fascinating!

To make a pair we can define a function that takes in two values and stores them like `x.y.F. y xF`. Tacitly this is expressed like `` ]` `: ``. Later the pairs can be called with `@` or `@[` to get their contents, or we can define `@[` and `]@[` as functions instead.

```
]` `:  Pair.
@[     First.
]@[    Second.

3 5Pair   xy.

xyFirst     .. 5
xySecond    .. 3
```

Pairs are not quite as useful as our lists. But by putting pairs inside other pairs, we can build structures like lists and trees.


### Church numerals

Church numerals are a way of implementing natural numbers in pure lambda calculus. The idea is to make *n* a function that applies a function n times.

* 0 = `F.x. x`
* 1 = `F.x. xF`
* 2 = `F.x. xFF`
* 3 = `F.x. xFFF`
* ...

To turn a church numeral to a boil number just call it with `+1` and `0`: increment the number `0`, n times.

```
F.x. xFFFF  Four.

0 1+Four  .. 4
```

#### Increment

To increment this value by one, just call it with the function again.

```
0 1+ 1+Four  .. 5
0 1+Four 1+  .. 5
```

We can define this function as `N.f.x. x f fN` or `N.f.x. x fN f`:
```
N.f.x. x f fN  Inc.

0 1+(FourInc)  .. 5
```
Or alternatively using combinators as `N.f. f fN:` === `N.f. f f(N ::)` === `N. N :: ^` === `:: ^:` which is a little smaller.
```
0 1+(Four  :: ^:)  .. 5
```

#### Addition

Let's make addition. To apply something m+n times you have to apply it m times, then apply it n times.

```
F.x. xFFF   Three.
F.x. xFFFF  Four.
0 1+Three 1+Four           .. 7
0 1+(f.x. x fThree fFour)  .. 7
```

This is a function like `M.N.f.x. x fN fM` which turns out to be ``:: `: :: ^::``. But we can also read it as "increment n, m times" so it becomes this:

```
0 1+(Three IncFour)
```

So `M.N. N IncM` as an add function works, which is just a single `Inc[` = `:: ^: [`.

```
:: ^: [  Add.

0 1+(Three FourAdd)  .. 7
```

#### Multiplication

What's nice about church numerals is that multiplication and exponentiation is very easy. Calling a function m*n times is the same as having a function that calls m times, and calling it n times. So:

```
0 1+ThreeFour  .. 12
```
Multiplication! This is just composing two numbers: call m times, n times. So multiplication is just `:`.

#### Exponentiation

Exponentiation is even easier, as in, it's literally doing nothing.
```
0 1+(ThreeFour)  .. 81
```
Repeat three times, four times, so this makes a function that repeats $3^4 = 81$ times. Exponentiation is the identity, so `]`.

```
n.f.x.  ]  x@ (r.i. f r i)n     Dec.
```

#### Predecessor

Writing the predecessor function is a little tougher. Here is a straight-forward translation of the usual definition given. It's explained a little further in [the Wikipedia page](https://en.wikipedia.org/wiki/Church_encoding#Predecessor_function):

```
n.f.x.   ]   x@  R.I.fRI n
```

Also, `` n.f.x. f [:` n x@[ ][ `` is equivalent. Here it is shown for n=4:

```
]   x@  R.I.fRI Four
=>
]   x@ R.I.fRI R.I.fRI R.I.fRI R.I.fRI
=>
f  x@ R.I.fRI R.I.fRI R.I.fRI  ]
=>
f  x@ R.I.fRI R.I.fRI  ]  f
=>
f  x@ R.I.fRI  ]  f  f
=>
f  x@  ]  f  f  f
=>
x f f f
```
Basically we set the second argument (the leftmost value) initially to `]`, the identity. The function `R.I.fRI` (or `` f [:` ``) applies that function and changes the leftmost value to `f`. We apply that function n times: the first iteration it is `]`, the identity; all the others use `f`. In effect the first function call has been replaced with the identity function, so the function doesn't change. the `@` (const) is then so the second argument doesn't get applied again.  

#### Subtraction

The same way as addition, once we have defined subtraction, we can just write `M.N. N DecM`, or equivalently `Dec[`.

```
n.f.x.   ]   x@  R.I.fRI n     Dec.

Dec[ Sub.

F.x. xFFFFFFF  Seven.
F.x. xFFF      Three.

0 1+(Seven ThreeSub)  .. 4
```

