boil has built-in list sorting. it doesn't have to, you can definitely write a sorting function without it. look at this psuedo-quicksort (updated version of one written by olus2000)
```
(s.  (<=>,  s]s, (S.F. 0 F: ^ ?: ^ SS:)|  ;/:)],  # 2<: `  ^)`` ]^
... or if you really hate parentheses
s.  S.F. 0 F: ^ ?: ^ SS:  |  s]s,[  <=>,[  ;/:  ];  # 2<: `  ^   ` `: ]^:
```
if the length is greater or equal to two (`` # 2<: ` ``) it breaks the selection up in parts less, equal and greater (`<=>,`) to the pivot point (the first element) and it iterates the function only in two of the three partitions (`s]s,`)

i think it's cute. well. recursive functions (```f`` ]^```) are always quite ugly in boil. but you kind of need recursion to write something like this. there are other sorting algorithms: i didn't bother writing any of them. instead i just added
## grade
`x~` grade returns a permutation that sorts the items in x
```
8 3 1- 2 0 3 4 3 ,~   .. { 2 4 3 1 5 7 6 0 }
```
the first item of the result will be index 2 in the argument (-1), the second item will be index 4 (0), the third item will be the index 3 (2)...

of course, because this is boil, we can just apply it again and get the sorted list:
```
8 3 1- 2 0 3 4 3 ,~^   .. { -1 0 2 3 3 3 4 8 }
```
neat! so `~^` sorts a list. returning a permutation instead of a list might seem like some unnecessary indirection, but it's quite convenient if we want to sort a list according to some other list. i can sort a list of words by length, for example. look!

```
    "By" "lifted," "we" "mean" "that" "it" "can" "be" "bogus." ,x.
    x #'
{ 2 7 2 4 4 2 3 2 6 }
    x  x #' ~  Print'  ...i couldve also written  #' ~: ^
By
we
it
be
can
mean
that
bogus.
lifted,
```
one important property of grade is that it uses a stable sorting algorithm: when two elements have the same value, their order in the list must always be conserved. see that the two-letter words above (`By we it be`) are in the same order as in the original list.

grade is another of those ambivalent functions. we can even update that one table if you want look
|usage | names               | example
| ---: | ------------------- | -------
|  `x!`|iota, range          |`5! .. { 0 1 2 3 4 }`
|`x y!`|reshape, take, prefix|`"beefeater" 3! .. "bee"`
|  `x?`|where, indices       |`0 1 0 1 2 ,? .. { 2 4 5 5 }`
|`x y?`|replicate, mask      |`"bevel"  1 1 0 1 0 ,?  .. "bee"`
|  `x~`|grade, invert        |`0 2 2 1 4 5 ,~ .. { 0 3 1 2 4 5 }`
|`x y~`|sort by              |`"lobi"  3 1 0 2 ,~  .. "boil"`

this function is stolen straight from apl's `⍋`, and the apl wizards have found a bunch of uses for it. it happens to find the inverse of a permutation, that's pretty useful on its own. if you apply it twice:
```
    9 249 17 2 157 116 227 91 ,~ ~
{ 1 7 2 0 5 4 6 3 }
```
it ranks the elements of the array: the smallest element is marked with a 0, the second smallest with a 1...

`~` is also useful if you want to find the index of the greatest or lowest element:

```
    41 42 13 56 23 73 ,~ 0
2
    41 42 13 56 23 73 ,~ 1-
5
```