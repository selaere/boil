## the dumb way

get the prefixes of the input, and fold for each.

```
1 3 2 4 , +(f. # !: 1+: !': ^ f/':) .. { 1 4 6 10 }
```

this runs in O(n²) time. it's doing redundant work. not great!

## the good way

change the function that is used for the fold. observe that we can do something like this:

```
1 3 2 4 , (b. a.  a  a 1- b+ ;)/
```
growing the list progressively. this works well for an argument of depth 1, but we can't just replace that `+` by every function. case in point:

```
"list" "of" "words" , ;\  .. { "list" "listof" "listofwords" }
"list" "of" "words" , b.a.(a  a 1- b; ;)\ .. "listtoffwords"
```
first, we have to enclose the first element, so that it doesn't read "t" as the first element to scan over. this turns out to be a bit difficult: i've chosen to take the domain outside of the first element, and then concatenate `0]]` in. we will do this as a preprocessing step to the reduction.

```
.. { { "list" } "of" "words" }
"list" "of" "words" , a.(a   a# 1-+ ! 1+  0$$ ;`)
"list" "of" "words" ,   # 1-+: !: 1+:  0$$ ;` :  ^
"list" "of" "words" ,  # 1-+: !: 1+: ;: 0$$[: ^
```
second, we have to enclose every element before concatenating,

```
"list" "of" "words" ,  # 1-+: !: 1+: ;: 0$$[: ^  (b. a.  a  a 1- b; ] ;)/
.. { "list" "listof" "listofwords" }
```
aha! now we can try to turn this into an actual single function.

```
"list" "of" "words" , ;(F. # 1-+: !: 1+: ;: 0$$[: ^ (b. a.  a  a 1- bF ] ;)/:)
"list" "of" "words" , ;(F. # 1-+: !: 1+: ;: 0$$[: ^ (b. 1- bF: ]: ;: ^)/:)
```
this is probably the version i would use. but for fun,
```
F. # 1-+: !: 1+: ;: 0$$[: ^ (b. bF: 1-[ ]: ;: ^)/:         .. swap with [
F.  # 1-+: !: 1+: ;: 0$$[: ^  F :: 1-[: ]:: ;:: ^: / :     
# 1-+: !: 1+: ;: 0$$[: ^  :: 1-[: ]:: ;:: ^: / : ,:/ `
```
it works with the prefix sum as well!
```
1 3 2 4 , +(# 1-+: !: 1+: ;: 0$$[: ^  :: 1-[: ]:: ;:: ^: / : ,:/ `)
```