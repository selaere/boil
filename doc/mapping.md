## mapping

boil has two builtins for iteration: each `'` and zip `|`

each `x f'` takes one function f and applies it to every item in x.
```
1 2 3 ,!' .. { { 0 } { 0 1 } { 0 1 2 } }
```
and zip `x  y f|` takes one function f and applies it to every pair of items, matched up from x and y.

```
1 2 3 ,  4 5 6 ,;| .. { { 1 4 } { 2 5 } { 4 6 } }
```
what do these do when passed something that is not a list, like, a number? each just applies the function to the argument.
```
3 !  .. { 0 1 2 }
3 !' .. { 0 1 2 }
3 !'''''''''''''''' .. { 0 1 2 }
```
and for zip, if one of its arguments is not a list, it will use that same argument for every iteration:
```
1 2 3 ,  4 ;|  .. { { 1 4 } { 2 4 } { 3 4 } }
0  1 2 3 , ;|  .. { { 0 1 } { 0 2 } { 0 3 } }
```
if neither is a list, it just applies the function, like each.
```
1  2 ;| .. { 1 2 }
```
if this seems familiar, it's because it's similar to how pervasive operations work, the math functions.

```
1 2 3 , 1+  .. { 2 3 4 }
```
you usually don't need to specify mapping when working with math functions, because they have implicit mapping. in specific, the one-argument functions `-%` act like they've been eached a lot of times, and the two-argument functions `+*<=>{}` act like they've been zipped a lot of times. it's when we look at other functions that aren't pervasive, like the `!` and `;` we've been seeing, when using the iteration functions is important.

i say "a lot of times" in that paragraph above because this is also an important distinction: each `'` and zip `|` only act on the top-level lists, and won't dig any deeper.
```
"abc" "def" , $' .. { { "abc" } { "def" } }
```
see? it wrapped every string! but we can have them act at lower depths by applying them multiple times:
```
"abc" "def" , $'' .. { { { 97 } { 98 } { 99 } } { { 100 } { 101 } { 102 } } }
```
now it wrapped every character! the pervasive functions always dig down through all the lists to find the numbers deep below and do something to it. 

```
2 3 , 4 , 5 ,  1 2 ,+  .. { { { 3 4 } 5 } 7 }
```

in case this worries you: this operation will always halt. there is no way to create a list that contains itself, or to otherwise create a loop using lists (lists are well-founded)

## iterating over two arguments

each and zip can be used and combined in different ways to implement different iteration patterns.
we can concatenate these two lists:
```
1 2 3 ,  4 5 6 ,; .. { 1 2 3 4 5 6 }
```
or we can concatenate their elements, with zip:
```
1 2 3 ,  4 5 6 ,;| .. { { 1 4 } { 2 5 } { 3 6 } }
```
### each-right
but how do we express concatenating each _element_ of the second list with the _whole_ first list? easy! now we are iterating through only one argument, so we can use each `'`:
```
1 2 3 ,  4 5 6 ,;' .. { { 1 2 3 4 } { 1 2 3 5 } { 1 2 3 6 } }
```
huh? i thought that each was for 1-argument functions? but concatenate `;` takes two arguments? how does this work?

muahahahaha LOOK
```
4 5 6 ,;' .. { ( 4 ; ) ( 5 ; ) ( 6 ; ) }
```
it's currying again!! your worst nightmare!!! each of those functions (shown as `(4 ;)`) is partially applied, and they will be fully applied, with the same value, when we apply it to something else:

```
1  4 5 6 ,;' .. { { 1 4 } { 1 5 } { 1 6 } }
```
### each-right
we can abuse currying again if we want to do the opposite, concatenating the whole second list with each element of the first list. let me add a single space before the each
```
1 2 3 ,  4 5 6 ,; ' .. { { 1 4 5 6 } { 2 4 5 6 } { 3 4 5 6 } }
```
what we are doing now is partially applying `;` with the whole list, and using that as the function for each.
```
4 5 6 ,; .. ( { 4 5 6 } ; )
```
or equivalently, the `'` is composed to `;`, not just applied,
```
1 2 3 ,  4 5 6 ,(; ' ) .. { { 1 2 3 4 } { 1 2 3 5 } { 1 2 3 6 } }
1 2 3 ,  4 5 6 ,(; ':) .. { { 1 4 5 6 } { 2 4 5 6 } { 3 4 5 6 } }
```
so you can think of `'` as "each-right" and `':` as "each-left".

another way of writing each-left is to swap the function, map, and swap back, to get the mapping to work on the other argument. this is convenient in some cases, especially when you can remove the first swap due to the function being commutative. but also the different quotes `` F`'` ``  look quite funny
```
1 2 3 ,  4 5 6 ,;`'` .. { { 1 4 5 6 } { 2 4 5 6 } { 3 4 5 6 } }
```

another example, this time the repeated argument is a number and not a list. you can see this as an each-left with values `1 2 3 ,`, `0` and concatenation; or just like each called with `1 2 3 ,` and the function "append zero" `0;`. you can also use zip `|`, because 0 is a number, but it's a little uglier here,
```
1 2 3 ,0(; ':) .. { { 1 0 } { 2 0 } { 3 0 } }
1 2 3 ,0;'     .. { { 1 0 } { 2 0 } { 3 0 } }
1 2 3 ,  0 ;|  .. { { 1 0 } { 2 0 } { 3 0 } }
```
### outer product
what if we applied both each-right `'` and each-left `':` at once?
```
    1 2 3 ,  4 5 6 ,(; ' ':)
 .. 1 2 3 ,  4 5 6 ,;' '      .. reduced
{
    { { 1 4 } { 1 5 } { 1 6 } }
    { { 2 4 } { 2 5 } { 2 6 } }
    { { 3 4 } { 3 5 } { 3 6 } }
}
```
huh? it's something like a cartesian product. this has every possible pair from each list, lined up in a neat table. APL users like to call this "[outer product](https://aplwiki.com/wiki/Outer_Product)"

if we apply them in the opposite order, the table just ends up transposed.
```
    1 2 3 ,  4 5 6 ,(; ': ')
{
    { { 1 4 } { 2 4 } { 3 4 } }
    { { 1 5 } { 2 5 } { 3 5 } }
    { { 1 6 } { 2 6 } { 3 6 } }
}
```
this is the example everyone they always like to give with outer product:
```
    10! 1+ (* ' ':)^
{
    { 1 2 3 4 5 6 7 8 9 10 }
    { 2 4 6 8 10 12 14 16 18 20 }
    { 3 6 9 12 15 18 21 24 27 30 }
    { 4 8 12 16 20 24 28 32 36 40 }
    { 5 10 15 20 25 30 35 40 45 50 }
    { 6 12 18 24 30 36 42 48 54 60 }
    { 7 14 21 28 35 42 49 56 63 70 }
    { 8 16 24 32 40 48 56 64 72 80 }
    { 9 18 27 36 45 54 63 72 81 90 }
    { 10 20 30 40 50 60 70 80 90 100 }
}
```
aha! it's a multiplication table! a little ugly because the rows aren't aligned, a little unfortunate. here we called the outer product of `*` with the same list twice, one that goes `{ 1 2 3 ... 10 }`. so we see every pair of digits being multiplied in a little table. nice!

it's interesting that we got `*` to apply in a different way, when I said earlier that these functions already had implicit mapping. but if we did this without the eaches, we would just see each number squared (or the diagonal of the table)
```
10! 1+ *^  .. { 1 4 9 16 25 36 49 64 81 100 }
```
but in this case, to get this behavior, one each-right is enough

```
    10! 1+ *'^
{
    { 1 2 3 4 5 6 7 8 9 10 }
    { 2 4 6 8 10 12 14 16 18 20 }
    ...
    { 10 20 30 40 50 60 70 80 90 100 }
}
```
now instead of multiplying `{ 1 2 3 ... 10 }` with itself, it is multiplying `{ 1 2 3 ... 10 }` by `1`, and then `{ 1 2 3 ... 10 }` by `2`, and so on, building each row.

## zip does weird things
zip behaves interestingly when given lists with unequal lengths:

```
1 2 3 ,  4 5 ,;| .. { { 1 4 } { 2 5 } }
1 2 ,  4 5 6 ,;| .. { { 1 4 } { 2 5 } }
```
it will discard some items at the end, always taking the minimum of the lengths of the two lists. it would make sense have this raise an error, but can be useful in some cases.

look! here's a way to check if a string starts with a given prefix:
```
"beeswax" "bee"=     .. { 1 1 1 }
"beeswax" "bee"= {/  .. 1
```
i don't like this very much. it isn't clear how to do the opposite, check if a string ends with a prefix. of course, you can reverse ``;`/`` both strings
```
"beeswax" ;`/  "wax" ;`/ =  {/  .. 1
```
but it's a little ugly. something that takes the suffix out would probably be clearer:
```
"beeswax" 3-! "wax"&  .. 1
```
the one using `=` has False Positives, if the searched string is small.
```
"b" "bee"= {/ .. "b"
```
though the one using `!` has something similar for some strings, because of cyclic indexing. oh no!
```
"memory" 3! "mem"& .. 1
"me" 3! "mem"&     .. 1
```
be careful is all.
