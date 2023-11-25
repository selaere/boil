USING: accessors arrays ascii assocs combinators command-line
continuations debugger grouping hash-sets hashtables io
io.encodings.utf8 io.files io.styles kernel math math.constants
math.functions math.order math.parser namespaces prettyprint
prettyprint.custom prettyprint.sections quotations ranges sorting
sequences sequences.extras sequences.private sets strings system
ui.theme vectors words readline hints ;
IN: boil

<< ALIAS: ' CHAR: >>

TUPLE: numlit { inner number } ;
TUPLE: ident  { inner string } ;
TUPLE: vardot { inner string } ;
TUPLE: prim   { inner fixnum } ;
SINGLETONS: '(' ')' ',' nothing ;

TUPLE: fcall  x f ;
: >fcall< ( fcall -- x f ) [ x>> ] [ f>> ] bi ;
TUPLE: lambda { captures hash-set } def { name string } ;
TUPLE: deeptoken token { depth fixnum } ;

TUPLE: func    { symbol union{ fixnum string } } { curr vector } ;
: <func> ( symbol -- func ) 3 <vector> func boa ; inline
TUPLE: closure { captures hashtable } def { name string } ;

UNION: val   number array func lambda ;

: find-idx ( ... seq quot: ( ... elt -- ... ? ) -- ... idx )
  dupd find drop swap length or
; inline

: cut-some-while ( ... seq quot: ( ... elt -- ... ? ) -- ... tail head )
  negate [ 1 -rot find-from drop ] keepd [ length or ] keep swap cut-slice swap
; inline

CONSTANT: +subscripts+ "₀₁₂₃₄₅₆₇₈₉₊₋₌₍₎ₐₑₒₓₔₕₖₗₘₙₚₛₜᵢᵣᵤᵥⱼᵦᵧᵨᵩᵪ"

: readtoken ( src -- src' token )
  dup ?first
  {
    { [ over ".." head? ] [ drop [ ' \n = not ] cut-some-while drop nothing ] }
    { [ dup ' \n = ] [ drop nothing ] }
    { [ dup not ] [ drop f ] }
    { [ dup ascii:digit? ]
      [ drop [ [ ascii:digit? ] [ ' . = ] bi or ] cut-some-while
        dec> numlit boa ] }
    { [ dup ascii:Letter? ]
      [ drop [ [ ascii:letter? ] [ +subscripts+ member? ] bi or ] cut-some-while
        over ?first ' . = 
        [ [ rest-slice ] dip >string vardot boa ]
        [ >string ident boa ] if ] }
    { [ dup ' " = ]
      [ drop [ ' " = not ] cut-some-while rest-slice 
        [ numlit boa ] V{ } map-as [ rest-slice ] dip ] }
    { [ dup ' ( = ] [ drop rest-slice '(' ] }
    { [ dup ' ) = ] [ drop rest-slice ')' ] }
    { [ dup ' , = ] [ drop rest-slice ',' ] }
    { [ dup ascii? ] [ [ rest-slice ] dip prim boa ] }
    [ over ?second ' . =
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
  dup ?first ' \n =
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
  [ rest-slice dup first depth>> 1 + read-at-depth ] dip make-lambda
;

: read-at-depth ( tokens depth -- tokens expr )
  [ dup empty? [ CHAR: $ prim boa ] [ unclip token>> ] if ]
  [| d | 0 <vector> swap
    [ dup ?first [ depth>> d < ] ?call ]
    [ dup ?first [ token>> ] ?call dup ',' =
      [ drop [ 1vector ] dip rest-slice ]
      [ dup vardot? [ inner>> read-lambda ] [ drop d 1 - read-at-depth ] if
        swap [ suffix ] dip ]
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

: parse ( code -- tokens ) read-tokens drop read-expr ;

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

DEFER: apply
: 2apply ( ctx x y f -- ctx f(x)(y) ) rot [ apply ] dip swap apply ; inline

: 2each ( ... x y quot: ( ... x y -- ... val ) -- ... val )
  2over [ array? ] bi@
  2array { { { f f } [ call ]      } { { t t } [ 2map ]     }
           { { t f } [ curry map ] } { { f t } [ with map ] } } case
; inline recursive

: 2scalar ( ... x y quot: ( ... x y -- ... val ) -- ... val )
  2over [ array? ] either? [ [ 2scalar ] curry 2each ] [ 2each ] if
; inline recursive

: 1scalar ( ... x quot: ( ... x -- ... val ) -- ... val )
  over array? [ [ 1scalar ] curry map ] [ call ] if
; inline recursive

: listify ( val -- array ) dup array? [ 1array ] unless ;
: bool ( ? -- x ) 1 0 ? ; inline

: equal ( x y -- ? ) 2dup [ lambda? ] either? [ eq? ] [ = ] if ;

: iota ( x -- val )
  dup array?
  [ [ product iota ] [ [ abs ] map rest-slice <reversed> ] bi
    [ <groups> [ >array ] map ] each ]
  [ 0 over 0 > [ swap ] when [a..b) >array ] if
;
<<
USING: parser make lexer ;
SYNTAX: P[  ! ]
  scan-number
  [ suffix parse-quotation ]
  [ { [ drop ] [ first-unsafe ] [ first2-unsafe swap ] [ first3-unsafe spin ] }
    nth ] bi prepend >quotation suffix!
;

SYNTAX: TRIG:
  [ [ dup unclip ch>upper prefix , 1 ,
      parse-word 1quotation [ first ] prepose >quotation ,
    ] { } make suffix
  ] ";" swap each-token
;
>>

ALIAS: ln log  ALIAS: exp e^
MACRO: primitives ( -- table )
  {
    { ' - P[ 1 [ neg ] 1scalar ] }
    { ' + P[ 2 [ + ] 2scalar ] }
    { ' * P[ 2 [ * ] 2scalar ] }
    { ' % P[ 1 [ recip ] 1scalar ] }
    { ' { P[ 2 [ max ] 2scalar ] }
    { ' } P[ 2 [ min ] 2scalar ] }
    { ' _ P[ 1 [ floor ] 1scalar ] }
    { ' ~ P[ 1 [ 1 swap - ] 1scalar ] }
    { ' = P[ 2 [ = bool ] 2scalar ] }
    { ' < P[ 2 [ < bool ] 2scalar ] }
    { ' > P[ 2 [ > bool ] 2scalar ] }
    { ' & P[ 2 equal bool ] }
    { ' ] P[ 1 1array ] }
    { ' ; P[ 2 [ listify ] bi@ append ] }
    { ' : P[ 3 [ apply ] dip apply ] }
    { ' ` P[ 3 swapd 2apply ] }
    { ' [ P[ 2 swap apply ] }
    { ' ^ P[ 2 [ apply ] keepd swap apply ] }
    { ' # P[ 1 dup array? [ length ] [ drop -1 ] if ] }
    { ' ! P[ 1 iota ] }
    { ' ' P[ 2 [ apply ] curry over array? [ map ] [ call ] if ] }
    { ' | P[ 3 [ 2apply ] curry 2each ] }
    { ' @ P[ 2 nip ] }
    { ' / P[ 2 [ unclip ] dip [ 2apply ] curry reduce ] }
    { ' \ P[ 2 [ unclip ] dip [ 2apply ] curry accumulate swap suffix ] }
    { ' $ P[ 1 ] }
    { ' ? P[ 1 listify [ <repetition> >array ] map-index concat ] }
    { "Pow"   P[ 2 [ ^ ] 2scalar ] }
    { "pi"    P[ 0 pi ] }
    { "Write" P[ 1 write { } ] }
    { "Print" P[ 1 print { } ] }
    { "Out"   P[ 1 ... { } ] }
    ! TRIG: sin cos tan asin acos atan sqrt round exp ln ;
  } 1quotation
;

MACRO: prim-impl-case ( table -- cond-thing )
  [ 1 swap remove-nth ] map [ no-case ] swap case>quot ;
: prim-impl ( ctx args symbol -- ctx return ) primitives prim-impl-case ;
HINTS: prim-impl { hashtable vector fixnum } { hashtable vector string } ;

MACRO: get-arity-case ( table -- cond-thing )
  [ first2 1quotation 2array ] map [ no-case ] swap case>quot ;
: get-arity ( func -- return ) primitives get-arity-case ;

: resolve ( ctx name -- ctx val/f )
  over ?at [ dup get-arity 0 = [ V{ } swap prim-impl ] [ <func> ] if ] unless
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
      clone [ curr>> push ] keep
      dup can-run-func [ [ curr>> ] [ symbol>> ] bi prim-impl ] when
    ] }
    { [ dup number? ] 
      [ over [ array? ] [ empty? not ] bi and
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
  f <inset "(" text [ name>> text "," text ] [ def>> fmt-parens ] bi
  ")" text block>
;

: boil ( string -- value ) parse 0 <hashtable> swap eval nip ;

: repl ( -- )
  [ "    " has-readline?
    [ flush readline ] [ write flush "\n" read-until drop ] if
    [ dup ")q" head? [ "bye" print 0 exit ] when
    [ boil . ] [ print-error drop ] recover ] unless-empty t
  ] loop
;
: main ( -- )
  command-line get ?first [ repl f ] unless* utf8 file-contents boil ...
;

MAIN: main
