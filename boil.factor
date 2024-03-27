USING: accessors arrays ascii assocs combinators combinators.short-circuit
command-line continuations debugger grouping hash-sets hashtables hints io
io.encodings.utf8 io.files io.styles kernel lexer make math math.constants
math.functions math.order math.parser namespaces parser prettyprint
prettyprint.custom prettyprint.sections quotations random ranges readline
sequences sequences.extras sequences.private sequences.deep sets sorting strings
system ui.theme vectors words ;
IN: boil

TUPLE: numlit { inner number } ;
TUPLE: ident  { inner string } ;
TUPLE: vardot { inner string } ;
TUPLE: prim   { inner fixnum } ;
SINGLETONS: '(' ')' ',' nothing ;

TUPLE: fcall  x f ;
: >fcall< ( fcall -- x f ) [ x>> ] [ f>> ] bi ;
TUPLE: lambda { captures hash-set } def { name string } ;
TUPLE: deeptoken token { depth fixnum } ;

TUPLE: func    { symbol union{ fixnum string } } { curr array } ;
: <func> ( symbol -- func ) { } func boa ; inline
TUPLE: closure { captures hashtable } def { name string } ;

ERROR: function-unexpected x ;
ERROR: scalar-expected x y ;
ERROR: divide-by-zero ;
ERROR: empty-list ;
ERROR: invalid-integer-literal ;
ERROR: out-of-domain ;

ERROR: primitive-error ctx args symbol err ;
ERROR: variable-undefined name ;

UNION: val   number array func lambda ;

: function? ( val -- ? ) { [ func? ] [ lambda? ] } 1|| ; inline

: find-idx ( ... seq quot: ( ... elt -- ... ? ) -- ... idx )
  dupd find drop swap length or
; inline

: cut-some-while ( ... seq quot: ( ... elt -- ... ? ) -- ... tail head )
  negate [ 1 -rot find-from drop ] keepd [ length or ] keep swap cut-slice swap
; inline

: trim-until-matching ( src -- src' )
  0 [ dup 0 = ]
  [ over first { { CHAR: ( [ 1 + ] } { CHAR: ) [ 1 - ] } [ drop ] } case
    [ rest-slice ] dip ] do until
  drop
;

: (cut-string) ( src -- src' str ) [ CHAR: " = not ] cut-some-while swap rest-slice ;

: cut-string ( src -- src' str )
  (cut-string) [ rest-slice ] dip
  [ dup first CHAR: " = ] [ (cut-string) [ append ] dip ] while swap
; 

: continuation-letter ( chr -- ? )
  { [ ascii:letter? ] [ "₀₁₂₃₄₅₆₇₈₉₊₋₌₍₎ₐₑₒₓₔₕₖₗₘₙₚₛₜᵢᵣᵤᵥⱼᵦᵧᵨᵩᵪ" member? ] } 1||
;

: string-to-frac ( str -- n )
  dup [ CHAR: . = ] find drop
  [ [ swap remove-nth ] keep
    over length swap -
    [ [ dec> ] [ invalid-integer-literal ] recover ] dip
    over integer? not [ invalid-integer-literal ] when
    10^ /
  ] [ dec> ] if*
;

: >rat ( a -- m/n )
  dup float? [ frexp [ 2 53 ^ * >integer ] [ 53 swap - 2^ ] bi* / ] when
;

: readtoken ( src -- src' token )
  dup ?first
  {
    { [ over ".." head? ] [ drop [ CHAR: \n = not ] cut-some-while drop nothing ] }
    { [ over "(." head? ] [ drop trim-until-matching nothing ] }
    { [ dup CHAR: \n = ] [ drop nothing ] }
    { [ dup not ] [ drop f ] }
    { [ dup ascii:digit? ]
      [ drop [ { [ ascii:digit? ] [ CHAR: . = ] } 1|| ] cut-some-while
        string-to-frac numlit boa ] }
    { [ dup ascii:Letter? ]
      [ drop [ continuation-letter ] cut-some-while
        over ?first CHAR: . = 
        [ [ rest-slice ] dip >string vardot boa ]
        [ >string ident boa ] if ] }
    { [ dup CHAR: " = ]
      [ drop cut-string
        [ numlit boa ] V{ } map-as ] }
    { [ dup CHAR: ( = ] [ drop rest-slice '(' ] }
    { [ dup CHAR: ) = ] [ drop rest-slice ')' ] }
    { [ dup CHAR: , = ] [ drop rest-slice ',' ] }
    { [ dup ascii? ] [ [ rest-slice ] dip prim boa ] }
    [ over ?second CHAR: . =
      [ [ 2 tail-slice ] dip 1string vardot boa ]
      [ [ rest-slice ] dip 1string ident boa ] if ]
  } cond
;

:: capture ( expr set -- )
  expr {
    { [ dup fcall?  ] [ >fcall< [ set capture ] bi@ ] }
    { [ dup ident?  ] [ inner>> set adjoin ] }
    { [ dup vector? ] [ [ set capture ] each ] }
    { [ dup lambda? ] [ captures>> members set adjoin-all ] }
    [ drop ]  ! prim, numlit
  } cond
;

DEFER: read-tokens
DEFER: read-expr
: readdeeptoken ( src -- src' deeptoken/f )
  dup ?first CHAR: \n =
  [ rest-slice dup [ 32 = not ] find-idx [ tail-slice readtoken ] keep -1 swap - ]
  [            dup [ 32 = not ] find-idx [ tail-slice readtoken ] keep           ] if
  over ')' = [ nip f swap ] when
  over '(' = [ [ drop read-tokens swap read-expr ] dip ] when
  over nothing =
    [ 2drop readdeeptoken ] [ swap [ swap deeptoken boa ] [ drop f ] if* ] if
;

: read-tokens ( code -- tokens code )
  0 <vector> swap [ readdeeptoken ] [ swap [ suffix ] dip ] while*
;
DEFER: read-at-depth

: make-lambda ( def name -- lambda )
  [ [ 0 <hash-set> tuck capture ] [ over delete ] bi* ] 2keep lambda boa
;
: read-lambda ( tokens name -- tokens lambda )
  [ dup first depth>> 1 + read-at-depth ] dip make-lambda
;

: read-at-depth ( tokens depth -- tokens expr )
  [ dup empty?
    [ CHAR: ] prim boa ]
    [ unclip token>> dup vardot? [ inner>> read-lambda ] when ] if ]
  [| d | 0 <vector> swap
    [ dup ?first [ depth>> d < ] ?call ]
    [ dup ?first [ token>> ] ?call dup ',' =
      [ drop [ 1vector ] dip rest-slice ]
      [ drop d 1 - read-at-depth swap [ suffix ] dip ]
      if
    ] do while swap
    unclip [ fcall boa ] reduce
  ] if-zero
;

: ?rest-slice ( seq -- slice ) [ { } ] [ rest-slice ] if-empty ;

: read-expr ( tokens -- expr )
  dup [ depth>> ] map
  [ 2dup [ 0 < ] same? [ <=> ] [ >=< ] if ] sort-with deduplicate
  swap [ [ over index ] change-depth ] map
  swap length 1 + read-at-depth nip
;

: parse ( code -- tokens )
  dup "#!" head? [ [ CHAR: \n = not ] cut-some-while drop ] when
  read-tokens drop read-expr
;

: fmt-parens ( expr -- )
  { { [ dup fcall?  ] [
      f <inset "(" text >fcall< [ fmt-parens ] dip fmt-parens ")" text block> ] }
    { [ dup ident?  ] [ inner>> text ] }
    { [ dup prim?   ] [ inner>> 1string text ] }
    { [ dup numlit? ] [ inner>> pprint* ] }
    { [ dup vector? ]
      [ f <inset "(" text [ fmt-parens ] each "," text ")" text block> ] }
    { [ dup lambda? ]
      [ f <inset "(" text
        [ name>> text "." text ]
        [ def>> fmt-parens ] bi ")" text block> ] }
    [ drop "?" text ]
  } cond
;
: (.) ( expr -- ) [ fmt-parens ] with-pprint "" print ;
: stringy ( expr -- expr ) [ dup [ number? ] all? [ >string ] when ] deep-map ;

DEFER: apply
: 2apply ( ctx x y f -- ctx f(x)(y) ) rot [ apply ] dip swap apply ; inline

: 2each ( ... x y quot: ( ... x y -- ... val ) -- ... val )
  2over [ array? ] bi@
  2array { { { f f } [ call ]      } { { t t } [ 2map ]     }
           { { t f } [ curry map ] } { { f t } [ with map ] } } case
; inline recursive

: assert-not-function ( x -- ) dup function? [ function-unexpected ] [ drop ] if ;

: 2scalar ( ... x y quot: ( ... x y -- ... val ) -- ... val )
  2over [ assert-not-function ] bi@
  2over [ array? ] either? [ [ 2scalar ] curry 2each ] [ 2each ] if
; inline recursive

: 1each ( ... x quot: ( ... x -- ... val ) -- ... val )
  over array? [ map ] [ call ] if
; inline

: 1scalar ( ... x quot: ( ... x -- ... val ) -- ... val )
  over assert-not-function
  over array? [ [ 1scalar ] curry map ] [ call ] if
; inline recursive

: listify ( val -- array ) dup array? [ 1array ] unless ;
: bool ( ? -- x ) 1 0 ? ; inline

: equal ( x y -- ? ) 2dup [ lambda? ] either? [ eq? ] [ = ] if ;

: iota ( x -- val )
  dup assert-not-function
  dup array?
  [ dup [ number? ] all? [ f scalar-expected ] unless
    [ product iota ] [ [ abs ] map rest-slice <reversed> ] bi
    [ <groups> [ >array ] map ] each ]
  [ 0 over 0 > [ swap ] when [a..b) >array ] if
;

: where ( x -- val )
  dup assert-not-function listify
  [ over number? [ <repetition> >array ] [ f scalar-expected ] if ] map-index
  concat
;

: setup-reduce ( x:xs f -- xs x quot )
  [ listify [ empty-list ] when-empty unclip ] dip [ 2apply ] curry
; inline

: grade ( x -- x ) [ length <iota> ] keep [ nth ] curry sort-by ;

<<
SYNTAX: P[  ! ]
  scan-number
  [ suffix parse-quotation ]
  [ { [ drop ] [ first-unsafe ] [ first2-unsafe swap ] [ first3-unsafe spin ] }
    nth ] bi prepose suffix!
;

: assert-real ( x -- x ) dup real? not [ out-of-domain ] when ;

SYNTAX: TRIG:
  [ [ dup unclip ch>upper prefix , 1 ,
      parse-word 1quotation
      [ assert-real ] compose
      [ 1scalar ] curry [ first ] prepose ,
    ] { } make suffix
  ] ";" swap each-token
;
>>

ALIAS: ln log  ALIAS: exp e^  ALIAS: round round-to-even
MACRO: primitives ( -- table )
  {
    { CHAR: - P[ 1 [ neg ] 1scalar ] }
    { CHAR: + P[ 2 [ + ] 2scalar ] }
    { CHAR: * P[ 2 [ * ] 2scalar ] }
    { CHAR: % P[ 1 [ [ divide-by-zero ] [ recip ] if-zero ] 1scalar ] }
    { CHAR: { P[ 2 [ min ] 2scalar ] }
    { CHAR: } P[ 2 [ max ] 2scalar ] }
    { CHAR: _ P[ 1 [ floor >integer ] 1scalar ] }
    { CHAR: = P[ 2 [ = bool ] 2scalar ] }
    { CHAR: < P[ 2 [ < bool ] 2scalar ] }
    { CHAR: > P[ 2 [ > bool ] 2scalar ] }
    { CHAR: & P[ 2 equal bool ] }
    { CHAR: $ P[ 1 1array ] }
    { CHAR: ] P[ 1 ] }
    { CHAR: ; P[ 2 [ listify ] bi@ append ] }
    { CHAR: : P[ 3 [ apply ] dip apply ] }
    { CHAR: ` P[ 3 swapd 2apply ] }
    { CHAR: [ P[ 2 swap apply ] }
    { CHAR: ^ P[ 2 [ apply ] keepd swap apply ] }
    { CHAR: # P[ 1 dup array? [ length ] [ drop -1 ] if ] }
    { CHAR: ! P[ 1 iota ] }
    { CHAR: ' P[ 2 [ apply ] curry 1each ] }
    { CHAR: | P[ 3 [ 2apply ] curry 2each ] }
    { CHAR: @ P[ 2 nip ] }
    { CHAR: / P[ 2 setup-reduce reduce ] }
    { CHAR: \ P[ 2 setup-reduce accumulate swap suffix ] }
    { CHAR: ? P[ 1 where ] }
    { CHAR: ~ P[ 1 listify grade ] }
    { "Pow"   P[ 2 [ ^ assert-real ] 2scalar ] }
    { "pi"    P[ 0 pi ] }
    { "Deco"  P[ 1 [ >rat >fraction 2array ] 1scalar ] }
    { "Rat"   P[ 1 [ >rat ] 1scalar ] }
    { "Write" P[ 1 write { } ] }
    { "Print" P[ 1 print { } ] }
    { "Out"   P[ 1 dup ... ] }
    { "Outs"  P[ 1 dup stringy ... ] }
    { "Rand"  P[ 1 [ 1.0 random ] [ >integer random ] if-zero ] }
    { "input" P[ 0 read-contents >array ] }
    TRIG: sin cos tan asin acos atan sqrt round exp ln ;
  } 1quotation
;

MACRO: prim-impl-case ( table -- cond-thing )
  [ 1 swap remove-nth ] map [ no-case ] swap case>quot ;
: prim-impl ( ctx args symbol -- ctx return )
  [ primitives prim-impl-case ] [ \ primitive-error boa rethrow ] recover ;
HINTS: prim-impl { hashtable array fixnum } { hashtable array string } ;

MACRO: get-arity-case ( table -- cond-thing )
  [ first2 1quotation 2array ] map [ variable-undefined ] swap case>quot ;
: get-arity ( func -- return ) primitives get-arity-case ;

: resolve ( ctx name -- ctx val/f )
  over ?at [ dup get-arity 0 = [ { } swap prim-impl ] [ <func> ] if ] unless
; inline

: eval ( ctx expr -- ctx val )
  { { [ dup fcall?  ] [ >fcall< [ eval ] dip swap [ eval ] dip swap apply ] }
    { [ dup ident?  ] [ inner>> resolve ] }
    { [ dup prim?   ] [ inner>> <func> ] }
    { [ dup numlit? ] [ inner>> ] }
    { [ dup vector? ] [ [ eval ] map >array ] }
    { [ dup lambda? ] [
      [ captures>> members [ [ resolve ] keep swap ] H{ } map>assoc ]
      [ def>> ] [ name>> ] tri closure boa ] }
  } cond
;

: can-run-func ( func -- ? ) [ symbol>> get-arity ] [ curr>> length ] bi <= ;

: apply ( ctx x f -- ctx f(x) )
  { { [ dup func? ] [
      clone [ swap suffix ] change-curr
      dup can-run-func [ [ curr>> ] [ symbol>> ] bi prim-impl ] when
    ] }
    { [ dup number? ] 
      [ over { [ array? ] [ empty? not ] } 1&&
        [ over length rem swap nth ] [ drop ] if ] }
    { [ dup array? ] [ [ [ apply ] keepd swap ] map nip ] }
    { [ dup closure? ]
      [ [ captures>> swap ] [ name>> pick set-at ] [ def>> ] tri eval nip ]
    }
  } cond
;

: show-symbol ( func -- )
  dup fixnum? [ 1string ] when dim-color foreground associate styled-text ; 

M: func pprint*
  dup curr>> length 0 =
  [ symbol>> show-symbol ] [
    f <inset "(" text
    [ curr>> unclip-slice [ [ pprint* "" text ] each ] [ pprint* ] bi* ]
    [ symbol>> show-symbol ] bi
    ")" text block>
  ] if
;

M: closure pprint*
  f <inset "(" text [ name>> text "." text ] [ def>> fmt-parens ] bi
  ")" text block>
;

M: primitive-error error.
  "Error in primitive " write
  dup symbol>> dup fixnum? [ 1string ] when write
  " being called with arguments" write
  dup args>> [ " " write pprint ] each
  ":\n" write
  err>> error.
;

: boil-with ( ctx string -- ctx value ) parse eval ;
: boil ( string -- value ) 0 <hashtable> swap boil-with nip ;

: repl-command ( ctx cmd -- ctx )
  { { [ dup { [ empty? ] [ ".." head? ] } 1|| ] [ drop ] }
    { [ dup "." tail? ]
      [ but-last-slice dup [ continuation-letter not ] find-last
        { [ ascii:LETTER? not ] [ ascii? ] } 1&& [ 1 + ] when
        cut-slice [ boil-with ] [ >string ] bi* pick set-at ] }
    { [ dup ")v" head? ] [ drop dup keys . ] }
    { [ dup ")s " head? ] [ 3 tail-slice boil-with stringy . ] }
    { [ dup ")p " head? ] [ 3 tail-slice parse (.) ] }
    [ boil-with . ] } cond
;
: repl ( -- x )
  0 <hashtable> clone
  [ "    " has-readline?
    [ flush readline ] [ write flush "\n" read-until drop ] if
    [ 32 = ] trim-slice
    dup ")q" head? [ drop f ]
    [ [ repl-command ] [ print-error drop ] recover t ] if
  ] loop
;
: main ( -- )
  command-line get ?first [ repl drop f ] unless* utf8 file-contents boil
  dup { [ array? ] [ empty? ] } 1&& [ drop ] [ ... ] if
;
MAIN: main
