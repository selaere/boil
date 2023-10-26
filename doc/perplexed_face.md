# perplexed face
if we have a big list of functions that we apply sequentially, you will end up writing something like this:

```
f g: h:
1+ !: 2+: 2%*:
```

this is a little confusing. why do all the functions have a `:` after them EXCEPT the first one? 

this is how binary operations work in boil. if we write it in infix, `h ∘ g ∘ f`, the composition operator is used two times. kind of like building up a value, `f g: h:` means "f, compose with g, compose with h". 

composition is associative, so you could write something like this:
```
f  g h: :
```
but now the syntax tree leans right, so we need more parentheses or spacing when adding more functions. also you have to keep track of how many colons you want.
```
f    g   h  i j: :  :   :
```

composition also has an identity element (appropiately, the identity function, `;`), so we could do this as well,
```
; f: g: h: i:
```
now every function is composed to the same `;`. this might be a bit clearer, but i don't love it.

my preferred solution is using another feature in the language. list literals! `1 2 3 .` results in a list with the numbers { 1 2 3 }. this works for any value, so `f g h .` is indeed a list with the functions { f g h }.

now, if only we had some way to apply a binary operator over a list. oh wait that's reduce `/`

```
1 2 3 . +/ ;; 6
f g h . :/ ;; same as f g: h:
5  1+ ! 2+ 2%* . :/   ;; { 1 1+1/2 2 2+1/2 3 3+1/2 }
```

forth fans in the audience are drooling right now.

i call this guy "perplexed face". he encompasses all feelings of "meh"ness. "meh" because, like, this is really cool, but do i really have to type ` . :/`? like that's ehhhhh like it makes sense but i dont _love_ it

another thing perplexie is good at is "indexing at depth". say we use `2 3 4 .!` as a list:
```
    2 3 4 .!
{
    { { 0 1 2 3 } { 4 5 6 7 } { 8 9 10 11 } }
    { { 12 13 14 15 } { 16 17 18 19 } { 20 21 22 23 } }
}
```
if we want to index into it we can just, use indexer numbers, like usual,

```
2 3 4 .! 0 0 0  ;; 0
2 3 4 .! 1 1 1  ;; 17
2 3 4 .! 0 2 3  ;; 11
2 3 4 .! 1 0    ;; { 12 13 14 15 }
```

but if we already have all the indices we're interested somewhere, how do we index into the list? remember that these are functions, so we can compose them in the same way,
```
2 3 4 .!  0 2: 3:  ;; 11
```
so if we have a list, we can just perplex for each (`'`) element:
```
2 3 4 .!   0 0 0 .  1 1 1 .  0 2 3 .  . :/' ;; { 0 17 11 }
```
note that this will not work for empty arrays. we can prepend an identity to the reduction to make it work for any length:

```
2 3 4 .!   0!  ; ,` :/:   ;; { { { 0 1 2 3 } { 4 5 6 ...
```

look! a DOUBLE perplexed face `:/:`. you don't see that every day!