## how to run
install [factor](https://factorcode.org) and then `rlwrap factor boil.factor` (replace `factor` by whichever name you have factor installed with)
# boil
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
or use `,` as special syntax, that takes all expressions in the same depth and puts them in a list

```
1 2 3 ,                 .. { 1 2 3 }
1 2 3 ,  4 5 6 ,  ,     .. { { 1 2 3 } { 4 5 6 } }
1 2; 3; ]  4; 5; 6; ] ; .. { { 1 2 3 } { 4 5 6 } }
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
numbers are functions that index into lists. these indices are cylic, so `1-` gets the last element
```
0 1 4 9 16 25 , 4   .. 16
3 9 ,  5 4 ,  , 1 0 .. 5
"bees" 4  .. "b"0
"bees" 1- .. "s"0
```
and when lists are called, they call each element with the same argument:
```
4  1+ - 2* ,  .. { 5 -4 8 }
```
this means that rearranging items is the same as applying a permutation as a function:
```
"catnip"  4 5 6 1 2 3 ,  .. "nipcat"
```
with this, we can implement many useful list operations. rotating a list is as easy as adding a number to the domain (`x#` is length), and calling it with the original array:
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
"catnip" 2n.l.(l  l#! n+)     .. or this
"catnip" 2n.l.l(l#! n+)       .. or this. you pick
```
still, boil has a bunch of combinators you can use to avoid writing lambdas. here's a list! they also have letters if you're that kind of nerd

| name | usage | result | letter |
| --: | --: | --- | ---
| id | `x$` | `x` | I
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
"catnip" 2(n. l. l  # !: n+: ^)
```
a lambda that just consists of the argument being called with a constant function is the same as the function itself (this is called "eta reduction"), so we can reduce this into:
```
"catnip" 2(n. # !: n+: ^)
```
we can still reduce this to not use any lambdas at all. if you play with the combinators for a bit, you might arrive to something like this. `` F  G :` `` is reverse compose ("prepose"), i think of it as adding a step to do before the function (get the domain _before_ we add)
```
"catnip" 2(n.  n  +  # !: :`  ^)
```
turning this into a function just means composing all functions together (because of boil's syntax, this means adding a `:` to every function but the first one)
```
"catnip" 2(+  # !: :` :  ^:) .. "tnipca"
```

with these combinators you can build other combinators, if you feel like it. in fact, you can build all combinators. here is the infamous S combinator (<code>x&nbsp;&nbsp;F&nbsp;GS&nbsp;=>&nbsp;xF&nbsp;xG</code>, or `λgfx.gx(fx)`)
```
G.F.x. xF xG       .. note how the args are listed backwards
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

more things:
* [control flow](doc/control_flow.md) (conditions, iteration, recursion)
* [perplexed face](doc/perplexed_face.md) `:/`
* [implementing stuff with lists](doc/rearranging_lists.md)
* [reimplementing scan](doc/reimplementing_scan.md)
* [syntax](doc/syntax.md) (more detail about how precedence works etc)

## builtins
<table><tr></tr>
<tr><th>usage</th><th>name</th><th>example</th></tr>
<tr>
<td align="right"><code>x!</code></td>
<td>iota</td>
<td><pre>
5!          .. { 0 1 2 3 4 }
5-!         .. { -1 -2 -3 -4 -5 }
"string" 4! .. "stri"
2 3; !      .. { { 0 1 } { 2 3 } { 4 5 } }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x#</code></td>
<td>length</td>
<td><pre>
12 34 56 , # .. 3
"string"#    .. 6
4#           .. -1
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x$</code></td>
<td>id</td>
<td><pre>
1$   .. 1
2 -$ .. -2
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x%</code></td>
<td>reciprocal</td>
<td><pre>
3%    .. 1/3
6 3%* .. 2
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x y&</code></td>
<td>match</td>
<td><pre>
"meow" "meow"& .. 1
"woof" "meow"& .. 0
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x f'</code></td>
<td>each</td>
<td><pre>
3 1 2 , !' .. { { 0 1 2 } { 0 } { 0 1 } }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x y*</code></td>
<td>times</td>
<td><pre>
1 2 3 ,  4 5 6 , * .. { 4 10 18 }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x y+</code></td>
<td>add</td>
<td><pre>
1 2 3 ,  4 5 6 , + .. { 5 7 9 }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x-</code></td>
<td>negate</td>
<td><pre>
0 1 2 , - .. { 0 -1 -2 }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x f/</code></td>
<td>fold</td>
<td><pre>
2 3 4 , +/ .. 9
2 3 4 , */ .. 24
1 2 ,  3 4 ,  5 6 ,  ,  ;/  ..  { 1 2 3 4 5 6 }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x  f g:</code></td>
<td>compose</td>
<td><pre>
"cats"  # !:    .. { 0 1 2 3 }
1 2 3 , 1(- +:) .. { 0 1 2 }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x y;</code></td>
<td>concat</td>
<td><pre>
1 2 3 ,   4 5 6 ,;    .. { 1 2 3 4 5 6 }
1 2 3 ,]  4 5 6 ,] ;  .. { { 1 2 3 } { 4 5 6 } }
1 2;                  .. { 1 2 }
1  2 3 4 ,;           .. { 1 2 3 4 }
1 2 3 , 4;            .. { 1 2 3 4 }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x y&lt;</code></td>
<td>less</td>
<td><pre>
4 5 6 , 5< .. { 1 0 0 }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x y=</code></td>
<td>equal</td>
<td><pre>
4 5 6 , 5= .. { 0 1 0 }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x y></code></td>
<td>greater</td>
<td><pre>
4 5 6 , 5> .. { 0 0 1 }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x?</code></td>
<td>where</td>
<td><pre>
0 0 0 1 0 0 1 0 1 1 0 , ? .. { 3 6 8 9 }
0 1 3 0 2 0 4 , ? .. { 1 2 2 2 4 4 6 6 6 6 }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x y@</code></td>
<td>const</td>
<td><pre>
1 2@ .. 2
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>f x[</code></td>
<td>thrush</td>
<td><pre>
3 "hello"[ .. 'l'
+ 2[ 3[    .. 5
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x f\</code></td>
<td>scan</td>
<td><pre>
4 2 5 3 2- 3 , +\ .. { 4 6 11 14 12 15 }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x]</code></td>
<td>wrap</td>
<td><pre>
3 4 5 , ] .. { { 3 4 5 } }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x f^</code></td>
<td>self</td>
<td><pre>
4 *^ .. 16
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x_</code></td>
<td>floor</td>
<td><pre>
4.5_ .. 4
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x  y f`</code></td>
<td>swap</td>
<td><pre>
1 2 3 ,  4 ;` .. { 4 1 2 3 }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x y{</code></td>
<td>max</td>
<td><pre>
4 5 6 , 5{ .. { 5 5 6 }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x  y f|</code></td>
<td>zip</td>
<td><pre>
1 2 3 ,  4 5 6 , ;| .. { { 1 4 } { 2 5 } { 3 6 } } 
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x y}</code></td>
<td>min</td>
<td><pre>
4 5 6 , 5} .. { 4 5 5 }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x~</code></td>
<td>not</td>
<td>
<pre>1 2 0 4 0 5 0 6 , 0= ~ .. { 1 1 0 1 0 1 0 1 }
1- 0 1 2 3 , ~ .. { 2 1 0 -1 -2 } </pre>
</td>
</table>

## other builtins

* `xSin` `xCos` `xTan` `xAsin` `xAcos` `xAtan` `xSqrt` `xRound` `xExp` `xLn` do exactly what you expect them to do
* `b nPow` is b to the power of n
* `pi` is pi
* `sWrite` writes a string to stdout
* `sPrint` writes a string to stdout with a trailing newline
* `xOut` prettyprints x

## uncertain
how do multiline files ?
- i want to do something smart with indentation, to go along with the spacing-based precedence, but i'm not sure exactly how that would work

how 2 sort?
- implementing one is definitely possible, but unwieldy
- `Grade^` would be very nice

unbounded recursion is non-trivial. fixed-point combinators?

identifiers with numbers would be cool i think

keep state in the repl
- set variables by having `name.` at the end ?
