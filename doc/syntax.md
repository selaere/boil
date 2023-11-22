# elements of syntax
## primitives
one of the characters ``!#$%&'*+-/:;<=>?@[\]^_`{|}~``. these cannot be redefined.
## identifiers
identifiers can be either:
- an uppercase ascii letter followed by any number of lowercase ascii letters (`Pow`)
- one or more lowercase ascii letters (`pow`)
- another non-ascii symbol (`↑`)

note that mixing case in a single identifier is not allowed: i.e. `xPowOut` is parsed as `x` then `Pow` then `Out`. for this reason i tend to name functions in uppercase and values in lowercase (though every value can act as a function), so that they can be applied by writing them next to each other, instead of `x pow out` (adding one more precedence level) or `x$pow$out` (ugly).

## number literals
one or more ascii digit, then an optional decimal part. the decimal part is a dot `.` and then one or more ascii digits.

## precedence
boil uses the concept of precedence to turn tokens into a tree. every token has a precedence represented by the whitespace before it. see the following example:
```
A  B C DE   F GH  IJ K
```
each token here is assigned a precedence, which is equal to the number of spaces before it:

```
A B C D E F G H I J K
0 2 1 1 0 3 1 0 2 0 1
```
which then are parsed recursively in reverse order. a token of precedence starts an expression in that precedence. the precedence at the start of an expression doesn't matter for the inner layers.
```
   A B C D E F G H I J K
   0 2 1 1 0 3 1 0 2 0 1
   +--------------------  ABCDEFGHIJK
3: +-------- +----------  (ABCDE)(FGHIJK)
2: + +------ +---- +----  (A(BCDE))((FGH)(IJK))
1: + + + +-- + +-- +-- +  (A(BC(DE)))((F(GH))((IJ)K))
0: + + + + + + + + + + +
```
there are two types of precedence: inline precedence (like we've seen earlier) and indent precedence, for tokens at the start of a line. i will write the latter as ~n where n is the number of spaces before the token.

inline tokens are always deeper than the line-separated ones (m < ~n) and the further indented tokens are deeper (m < n ↔ ~n < ~m). therefore, in order, the indent levels for any program are:

```
0 1 2 3 4 5 6 ... ~6 ~5 ~4 ~3 ~2 ~1 ~0
```
consider the following program
```
A
B
    C
    DE F
G
```
its list of precedences:
```
A  B  C  D  E  F  G
0 ~0 ~4 ~4  0  1  ~0
```
the precedences used in the file are, in order, `0 1 ~4 ~0`, so
```
    A  B  C  D  E  F  G
    0 ~0 ~4 ~4  0  1 ~0
    +------------------
~0: +  +  +---------  + AB(CDEF)G
~4: +  +  +  +------  + AB(C(DEF))G
 1: +  +  +  +---  +  + AB(C((DE)F))G
 0: +  +  +  +  +  +  + 
```
after this, if there are no special tokens, each term in the expression is grouped in pairs left-associatively, so `ABCD` = `((AB)C)D`. each of these pairs `AB` represents the function B being called with A as an argument. the expression with one term `A` evaluates to the only term.

a token has precedence ~n when it is preceded by a newline `\n` followed by n spaces. any other whitespace before a newline `\n` character is ignored.

TODO: specify and implement how tabs and carriage returns work
## parentheses
parentheses start a new parsing context with its own whole precedence stuff. the expression inside two matching parentheses `(`-`)` is parsed and replaced by a token with the same precedence before the opening parentheses. the precedence of the first token in the parentheses (spaces after the `(`) or of the closing parentheses (spaces before the `)`) do not matter.

## comments
`..` starts a comment that extends until but not including the next line break, or the end of file. [NOT IMPLEMENTED. `(.` starts a comment that ends at the matching parenthesis.] comments are removed when tokenizing, and their precedence is ignored.

## list literals
the token `,` is special in that, instead starting a new expression with a lower precedence, it will aggregate all the terms in the expression into a _list literal_ and continue parsing in the same precedence. representing a list literal `1 2 3 ,` as `[123]`,

```
1 2 3 ,1+

   1 2 3 , 1 +
   0 1 1 1 0 0
   +----------  (123,1+)
1: + + + ! +--  [123](1+)
0: + + + ! + +  [123](1+)


1 2 3 ,  4 5 6 ,  ,

   1 2 3 , 4 5 6 , ,
   1 1 1 1 2 1 1 1 2
   +----------------  123,456,,
2: +------ +------ !  [(123,)(456,)]
1: + + + ! + + + ! !  [123][456]
```

## lambdas

when an identifier followed by `.` is found at its precedence, it starts a lambda expression. it will start parsing again at _one more_ than the precedence of the _next_ token.

```
3x. x x*  1+

   3 x.x x * 1 +
   0 1 1 1 0 2 0
   +------------ 3x.xx*1+
2: +-------- +-- (3x.xx*)(1+)
1: + \------ +-- (3\x(xx*))(1+)
  2:   +----     
  1:   + +--     (3\x(x(x*)))(1+)
  0:   + + +     (3\x(x(x*)))(1+)
0: + \ + + + + + 
```

this is convenient for a few reasons. first, you can make a function that takes multiple arguments without having to space all of them out:

```
x.y.z.  x  y z+ *

   x.y.z.x y z + *
   0 0 0 2 2 1 0 1
2: \-------------- x.y.z.xyz+*
  1: \------------ x.(y.z.xyz+*)
    1: \---------- x.(y.(z.xyz+*))
      3: +-------- x.(y.(z.(xyz+*)))
      2: + +------ x.(y.(z.(x(yz+*))))
      1: + + +-- + x.(y.(z.(x(y(z+)*))))
      0: + + + + +
```
and if we use the same precedence after multiple lambdas,

```
1 o. o o+ t. t t* f. f t+

   1 o.o o + t.t t * f.f t +
   0 1 1 1 0 1 1 1 0 1 1 1 0
   +------------------------ 1o.oo+t.tt*f.ft+
1: + \---------------------- 1(o.oo+t.tt*f.ft+)
    2: +-------------------- 1(o.(oo+t.tt*f.ft+))
    1: + +-- \-------------- 1(o.(o(o+)(t.tt*f.ft+)))
            3: +------------ 1(o.(o(o+)(t.(tt*f.ft+))))
            1: + +-- \------ 1(o.(o(o+)(t.(t(t*)(f.ft+)))))
                    3: +---- 1(o.(o(o+)(t.(t(t*)(f.(ft+))))))
                    1: + +-- 1(o.(o(o+)(t.(t(t*)(f.(f(t+)))))))
                    0: + + +


```

you can see the "scope" expands rightward, so the inner lambda can see all of `o`, `t` and `f`. look i can also write it like this

```
1 one.
one one+ two.
two two* four.
four two+
```
this is assignment! well, assignment with a weird syntax, where you can't have recursive or mutually recursive references, BUT because ~0 (newline) is the highest precedence you can always add lines at the top of a file and define more stuff, and then you can organize stuff in a file and then you can happiness etc
