# boil
is a dynamically typed functional pure-ish language based on untyped lambda calculus etc etc. boring. it is also a minimalistic<sup>1</sup> vector<sup>2</sup> tacit<sup>3</sup> programming language with postfix<sup>4</sup>, whitespace-based<sup>5</sup> terse<sup>6</sup> syntax

1. there are not a lot of built-in functions (see [primitives](#primitives))
2. boil values can either be scalars or vectors (which i will from here on just call "lists"). arithmetic operations like `+` (addition) map to every element in a list.
3. functions can be defined using combinators like `:` compose, as well as currying for partial evaluation.
4. `x-` means "minus x". application goes in left-to-right order
5. spaces are used to regroup things: `ABCD` is `((AB)C)D`, `A  B CD` is `A(B(CD))`. `x yF` calls F with y and x
6. most built-in are just ascii symbols (these are called "primitives")

### [INTROduction](doc/introduction.md) (<- that blue thing is a link) (click there)
it's a sort of tutorial but not really and it's not that long look at it
## how to run/build
install [factor](https://factorcode.org) and then, replacing `factor` by whichever name you have factor installed with,
* `factor boil.factor`,
* or place boil in your work folder and `"boil" deploy`,
* or if you dont know what that means,
  ```sh
  git clone https://github.com/selaere/boil
  factor -e='USE: namespaces "." deploy-directory set "." add-vocab-root "boil" deploy'
  # ^ run outside the cloned repo
  ```

## more things
* [implementing stuff with lists](doc/rearranging_lists.md)
  * [sorting](doc/sorting.md) `~`
  * [reading](doc/reading.md) (splitting, parsing numbers)
* [arithmetic](doc/arithmetic.md)
* [control flow](doc/control_flow.md) (conditions, iteration, recursion)
* [combinators](doc/combinators.md)
* [perplexed face](doc/perplexed_face.md) `:/`
* [reimplementing scan](doc/reimplementing_scan.md)
* [syntax](doc/syntax.md) (more details about how precedence works)
* [more words](doc/more_words.md) (inspirations, discourse, blah blah blah)

## primitives
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
<td>wrap</td>
<td><pre>
3 4 5 ,$ .. { { 3 4 5 } }
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
3 1 2 ,!' .. { { 0 1 2 } { 0 } { 0 1 } }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x y*</code></td>
<td>times</td>
<td><pre>
1 2 3 ,  4 5 6 ,* .. { 4 10 18 }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x y+</code></td>
<td>add</td>
<td><pre>
1 2 3 ,  4 5 6 ,+ .. { 5 7 9 }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x-</code></td>
<td>negate</td>
<td><pre>
0 1 2 ,- .. { 0 -1 -2 }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x f/</code></td>
<td>fold</td>
<td><pre>
2 3 4 ,+/ .. 9
2 3 4 ,*/ .. 24
1 2 ,  3 4 ,  5 6 ,  ,  ;/  ..  { 1 2 3 4 5 6 }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x  f g:</code></td>
<td>compose</td>
<td><pre>
"cats"  # !:    .. { 0 1 2 3 }
1 2 3 ,1(- +:) .. { 0 1 2 }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x y;</code></td>
<td>concat</td>
<td><pre>
1 2 3 ,   4 5 6 ,;    .. { 1 2 3 4 5 6 }
1 2 3 ,$  4 5 6 ,$ ;  .. { { 1 2 3 } { 4 5 6 } }
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
<td>id</td>
<td><pre>
1]   .. 1
2 -] .. -2
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
<td>min</td>
<td><pre>
4 5 6 , 5{ .. { 4 5 5 }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x  y f|</code></td>
<td>zip</td>
<td><pre>
1 2 3 ,  4 5 6 , ;| .. { { 1 4 } { 2 5 } { 3 6 } } 
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x y}</code></td>
<td>max</td>
<td><pre>
4 5 6 , 5} .. { 5 5 6 }
</pre></td></tr><tr></tr>
<tr>
<td align="right"><code>x~</code></td>
<td>grade</td>
<td>
<pre>
3 5 1 4 3 2 3 0 ,~  .. { 7 2 5 0 4 6 3 1 }
3 5 1 4 3 2 3 0 ,~^ .. { 0 1 2 3 3 3 4 5 }</pre>
</td>
</table>

## other builtins

* `xSin` `xCos` `xTan` `xAsin` `xAcos` `xAtan` `xSqrt` `xRound` `xExp` `xLn` do exactly what you expect them to do (see [arithmetic](doc/arithmetic.md))
* `b nPow` is b to the power of n
* `xDeco` returns the two components of ratio x
* `pi` is pi

these are the reason why i said "pure-ish" at the start:
* `input` gets all the input from stdin until eof
* `sWrite` writes a string to stdout
* `sPrint` writes a string to stdout with a trailing newline
* `xOut` prettyprints x and returns x
* `xOuts` prettyprints x and returns x, where lists with only numbers will be formatted as strings
* `nRand` returns a random integer in [0, n). if n = 0, return a random float in [0.0, 1.0)

## repl

if you call the executable with no arguments you get sent to a repl. type in expressions, press enter, and pretty-printed results come out! if you write a line with `var.` at the end, the result of that expression will be saved in the repl environment with the name _var_. there are also some other commands that can be used at the beginning of a line (these will probably change):
* `)q`: quit
* `)s`: pretty-prints the result, where lists with only numbers will be formatted as strings
* `)v`: show name of every variable set in the environment
* `)p`: parse the expression and print out the AST without running it

