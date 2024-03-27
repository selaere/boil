
## more words

boil is mostly a mix of things i like from other places. in general, a lot of the symbols and primitive design comes from array languages like [K](https://k.miraheze.org/wiki/Main_Page) or [APL](https://aplwiki.com/). boil has no multidimensional arrays, but its lists work a lot like K.

there aren't a lot of applicative languages that do postfix functions ("applicative" here basically means "not stack-based"), but it feels kind of similar to the `|>` pipes in the functional world or `.` method chaining in everywhere else. i think it's a more natural way to think about computation, but it probably doesn't matter that much.

what does matter is the associativity of application: i think function composition `xFGH` is more important than passing multiple arguments to the same function `z  y xF`, and the syntax reflects this. i also think it's neat that you can write that with thrush `F x[ y[ z[` and now it looks like Lisp but with more punctuation

the whitespace-based precedence reminds me of [I](https://github.com/mlochbaum/ILanguage), but it's quite different: here functions take one argument before instead of two arguments around. it is also [extended](doc/syntax.md#precedence) to files with newlines in a neat way that lets me use the lambda syntax for assignment. list literals `,` kind of remind me of Lisp quotes? i'm not sure

most array languages have a clear separation of values and functions. we need to call the result of functions anyways: everything takes one argument, so we curry the arguments. but here boil does something a bit original: a number called with a list indexes it (like K, but the other way around), and a vector called with a value calls that each of those elements with that value (this seems similar to [nial](https://www.nial-array-language.org/)'s atlases, but i haven't looked into it much). this means that some glyphs can become "overloaded": see [rearranging lists](doc/rearranging_lists.md)

i think it could be reasonable as a general-purpose language if some more functions are added. the functions "reverse" and "not" used to be primitives, but i added more stuff and ascii is too small. these are not hard to write out (``$' ;`/`` and `0=`/`- 1+:`), but that's soooo long and also `x 0= 0=` looks so ugly!! unicode identifiers are allowed, so those could become `⌽` and `¬` in some other library of some sort, but i don't really want them to be primitives.

TODO add some way of importing things from other files
