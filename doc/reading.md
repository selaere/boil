## splitting lists

this is not exactly straightforward. let's try to get the words from this camel-cased string:
```
    "wordsThingsStuff"   0 1 2 3 4 ,  5 6 7 8 9 10 ,  11 12 13 14 15 ,  ,
{ "words" "Things" "Stuff" }
```
doesn't look too hard. just a bunch of iotas:
```
    "wordsThingsStuff"   5!  6! 5+  5! 11+  ,
{ "words" "Things" "Stuff" }
```
and because pervasion,
```
    "wordsThingsStuff"   5 6 5 ,!'  0 5 11 ,+
{ "words" "Things" "Stuff" }
```
aha! i understand. the `5 6 5 ,` is the length of each word, and `0 5 11 ,` is the starting position of each word. okay then! the starting position of each word is easy to get. in this example we only need to get the positions where (`?`) the character is not lowercase:
```
    "wordsThingsStuff" "a"0< ?
{ 5 11 }
```
and then add a zero to the start
```
    "wordsThingsStuff" "a"0< ? 0(;`)
{ 0 5 11 }
```
we can get the length of each word by looking at the difference between every starting position pair: the first word is 5 minus 0, the second one is 11 minus 5. we also need the length of the input to know the length of the last element: we can append it to the end
```
    "wordsThingsStuff" i. i "a"0< ? 0(;`) i#;
{ 0 5 11 16 }
```
OR do a little trick: add a one to the list before calling where:
```
    "wordsThingsStuff" "a"0<
{ 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 }
    "wordsThingsStuff" "a"0< ?
{ 5 11 }
    "wordsThingsStuff" "a"0< 1;
{ 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 1 }
    "wordsThingsStuff" "a"0< 1; ?
{ 5 11 16 }
    "wordsThingsStuff" "a"0< 1; ? 0(;`)
{ 5 11 16 }
```
how do we do that difference thing? well we could [remove an element from the start and the end](rearranging_lists.md), and later subtract them,
```
    "wordsThingsStuff" "a"0< 1; ? 0(;`)  # 1-+: !: 1+: ^
{ 5 11 16 }
    "wordsThingsStuff" "a"0< 1; ? 0(;`)  # 1-+: !: ^
{ 0 5 11 }
    5 11 16 ,  0 5 11 ,- +
{ 5 6 5 }
```
but like haven't you seen how long that is? completely useless. let's just not add the zero on one of them.
```
    "wordsThingsStuff" "a"0< 1; ?
{ 5 11 16 }
    "wordsThingsStuff" "a"0< 1; ? 0(;`)
{ 0 5 11 16 }
```
when calling a scalar two-argument function like `+` with two lists of different length, it will throw away some items from the end of the larger list so the lengths are equal. so,
```
    5 11 16 ,  0 5 11 16 ,- +
{ 5 6 5 }
```
easy! let's write our function now. remember this from a while ago:
```
    "wordsThingsStuff"   5 6 5 ,!  0 5 11 ,+
{ "words" "Things" "Stuff" }
```
we can call `i` the starting positions, `f` the final positions, and `l` the lengths. again, it doesn't matter that `i` is larger than it has to be (you can also see it as the limits of each word, if that helps)
```
in.
    in "a"0< 1; ? f.
    in "a"0< 1; ? 0(;`) i.
    f i-+ l.
    in  l !' i+
Split.
"wordsThingsStuff"Split  .. { "words" "Things" "Stuff" }
```
of course we can inline the `l`, and write `i` based on `f`,

```
in.
    in "a"0< 1; ? f.
    0 f; i.
    in  f i-+ !' i+
Split.
"wordsThingsStuff"Split  .. { "words" "Things" "Stuff" }
```
and something i will also do is turn `f` into an input of the function, so we can use it in more places,
```
in. f.
    0 f; i.
    in  f i-+ !' i+
Split.
"wordsThingsStuff"  in.  in  in "a"0< 1; ? Split
"wordsThingsStuff"  "a"0< 1;: ?: Split: ^
```
and then we don't need `in` as an input,
```
f. 0 f; i. f i-+ !' i+  Group.
"wordsThingsStuff"  "a"0< 1;: ?: Group: ^
```
look at that thing `f. 0 f; i. f i-+ !' i+`. it is the simplest of a family of functions which i will now call "grouping functions". it takes a list of indices after the ending of each word, and returns a list of indices of each the words:
```
    5 11 16 ,Group
{ { 0 1 2 3 4 } { 5 6 7 8 9 10 } { 11 12 13 14 15 } }
```
### splitting by lines
you dont actually want to split a camel-cased string to its individual words. that is useless. i have never needed that. nobody needs that. it was just a convenient example. here's the REAL stuff.

how do i split something by lines?

```
"data 1 2 3
bees 4 5 6
other 7 9 8
" in.
```
let's assume your file is known to have a trailing newline for now. let's also assume that a newline is a single character with ascii code 10. lots of assumptions i know

well let's use the grouping function we already know!

```
    in 10= ?
{ 10 21 33 }
    in  in 10= ? f. 0 f; i. f i-+ !' i+
{ "data 1 2 3" "\nbees 4 5 6" "\nother 7 9 8" }
```
ugh not quite. why does the first line have newlines but the rest don't? if we add 1 after the where:
```
    ..           ++ added
    in  in 10= ? 1+ f. 0 f; i. f i-+ !' i+
{ "data 1 2 3\n" "bees 4 5 6\n" "other 7 9 8\n" }
```
ah! the line endings should be pointing to the character after the newline. now we have the newlines in every line. good! or bad. you might want this? some apis do this. but that newline at the end is useless. as this is written, if there was extra data in the file without a newline it would get stripped off anyways, so the newline isn't even giving any information

we can subtract one from the lengths `f i-+`,

```
    ..                               +++ added
    in  in 10= ? 1+ f. 0 f; i. f i-+ 1-+ !' i+
{ "data 1 2 3" "bees 4 5 6" "other 7 9 8" }
```
, or if you prefer, move the initial positions, so that we dont need that `1+` from before,
```
    ..          | removed
    ..          v      + +++++ added
    in  in 10= ? f. 0 (f 1+); i. f i-+ !' i+
{ "data 1 2 3" "bees 4 5 6" "other 7 9 8" }
    .. and because 1- 1+ is 0,
    in  in 10= ? f. 1- f; 1+ i. f i-+ !' i+
{ "data 1 2 3" "bees 4 5 6" "other 7 9 8" }
```
this gives us another grouping function, `f. 1- f; 1+ i. f i-+ !' i+`. it does the same thing as the last one, but removing the separators
```
    4 8 15 ,f. 0 f; i. f i-+ !' i+
{ { 0 1 2 3 } { 4 5 6 7 } { 8 9 10 11 12 13 14 } }
    4 8 15 ,f. 1- f; 1+ i. f i-+ !' i+
{ { 0 1 2 3 } { 5 6 7 } { 9 10 11 12 13 14 } }
```
neat! splitting by some other separator is the same, just using the `1; ?` trick we saw earlier. here's splitting by spaces in a single function:
```
    "family guy funny moments"  " "0= 1;: ?: (f. 1- f; 1+ i. f i-+ !' i+): ^
{ "family" "guy" "funny" "moments" }
```

## parse natural number in decimal
subtracting by `"0"0` is enough to get the digits in a number
```
    "142857" "0"0-+
{ 1 4 2 8 5 7 }
```
retrieving the actual value is as easy as reducing by a function that multiplies the left digit by 10 and adds the second digit `y.x. x 10* y+`.
```
    "142857" (y.x. x 10* y+)/
142857
```
to make this tacit, convert it to `y.x.  y  x 10* +` by commutativity. this is just `` 10* +: ` ``!
```
    "142857"  "0"0-+  10* +: ` /
142857
```