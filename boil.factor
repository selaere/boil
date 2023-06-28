USING:
  accessors arrays ascii assocs combinators command-line grouping
  effects hash-sets hashtables io io.encodings.strict
  io.encodings.utf8 io.files kernel math math.order math.parser
  namespaces prettyprint quotations ranges sequences
  sequences.extras sets strings vectors words.constant ;
IN: boil

<< ALIAS: ' CHAR: >>

TUPLE: numlit { inner number } ;
TUPLE: ident  { inner string } ;
TUPLE: vardot { inner string } ;
TUPLE: prim   { inner fixnum } ;
SINGLETONS: '(' ')' '.' ;

TUPLE: fcall  x f ;
: >fcall< ( fcall -- x f ) [ x>> ] [ f>> ] bi ;
TUPLE: lambda { captures hash-set } def { name string } ;
TUPLE: deeptoken token { depth fixnum } ;

TUPLE: func    { arity fixnum } { impl composed } { curr array } ;
TUPLE: closure { captures hashtable } def { name string } ;

UNION: val   number array func lambda ;

ERROR: unclosed-parenthesis ;

: find-idx ( ... seq quot: ( ... elt -- ... ? ) -- ... idx )
  dupd find drop swap length or
; inline

: cut-some-while ( ... seq quot: ( ... elt -- ... ? ) -- ... tail head )
  [ not ] compose
  [ 1 -rot find-from drop ] keepd [ length or ] keep swap cut-slice swap
; inline

: readtoken ( src -- src' token )
  dup ?first
  {
    { [ dup not ] [ drop f ] }
    { [ dup ascii:digit? ]
      [ drop [ [ ascii:digit? ] [ ' . = ] bi or ] cut-some-while dec> numlit boa ] }
    { [ dup ascii:Letter? ]
      [ drop [ [ ascii:letter? ] [ ' . = ] bi or ] cut-some-while
        dup ?last ' . = [ but-last vardot boa ] [ >string ident boa ] if ] }
    { [ dup ' " = ]
      [ drop [ ' " = not ] cut-some-while rest-slice >vector [ numlit boa ] map [ rest-slice ] dip ] }
    { [ dup ' ( = ] [ drop rest-slice '(' ] }
    { [ dup ' ) = ] [ drop rest-slice ')' ] }
    { [ dup ' . = ] [ drop rest-slice '.' ] }
    [ [ rest-slice ] dip prim boa ]
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

: make-lambda ( def name -- lambda )
  [ [ 0 <hash-set> tuck capture ] [ over delete ] bi* ] 2keep lambda boa
;

DEFER: read-tokens
DEFER: read-expr
: readdeeptoken ( src -- src' deeptoken/f )
  dup [ 32 = not ] find-idx [ tail-slice readtoken ] keep
  over ')' = [ nip f swap ] when
  over '(' = [ [ drop read-tokens swap read-expr ] dip ] when
  swap [ swap deeptoken boa ] [ drop f ] if*
;

: read-tokens ( code -- tokens code )
  0 <vector> swap [ readdeeptoken ] [ swap [ suffix ] dip ] while*
;

: read-expr-at-depth ( tokens depth -- tokens expr )
  [ unclip token>> ] [| d |
    0 <vector> swap
    [ dup ?first [ depth>> d < ] [ f ] if* ]
    [ dup ?first token>> dup '.' =
      [ drop [ 1vector ] dip rest-slice ]
      [ dup vardot?
        [ [ rest-slice dup ?first depth>> 1 + read-expr-at-depth ] dip inner>> make-lambda ]
        [ drop d 1 - read-expr-at-depth ]
        if swap [ suffix ] dip ]
      if
    ] do while swap
    unclip [ fcall boa ] reduce 0 <vector> or
  ] if-zero
;

: ?rest-slice ( seq -- slice ) [ { } ] [ rest-slice ] if-empty ;

: read-expr ( tokens -- expr )
  [ ?rest-slice [ depth>> ] map 0 [ max ] reduce 1 + ] keep swap read-expr-at-depth nip
;

: parse ( code -- tokens ) read-tokens drop read-expr ;

: fmt-parens ( expr -- )
  { { [ dup fcall?  ] [ "(" write >fcall< [ fmt-parens ] dip " " write fmt-parens ")" write ] }
    { [ dup ident?  ] [ inner>> write ] }
    { [ dup prim?   ] [ inner>> write1 ] }
    { [ dup numlit? ] [ inner>> pprint ] }
    { [ dup vector? ] [ "(" write [ fmt-parens " " write ] each ".)" write ]  }
    { [ dup lambda? ]
      [ "(" write
        [ captures>> members [ write ":" write ] each ]
        [ name>> write ". " write ]
        [ def>> fmt-parens ] tri ")" write ] }
    [ drop "?" write ]
  } cond
;
: (.) ( expr -- ) fmt-parens "" print ;

DEFER: apply
: 2apply ( ctx x y f -- ctx f(x)(y) ) rot [ apply ] dip swap apply ;

: 2scalar ( ctx x y quot: ( ctx x y -- ctx val ) -- ctx val )
  2over [ array? ] bi@
  2dup or [ [ [ 2scalar ] curry ] 2dip ] when
  2array { { { f f } [ call ]      } { { t t } [ 2map ]     }
           { { t f } [ curry map ] } { { f t } [ with map ] } } case
; inline recursive

: 1scalar ( ctx x quot: ( ctx x -- ctx val ) -- ctx val )
  over array? [ [ 1scalar ] curry map ] [ call ] if
; inline recursive

: listify ( val -- array ) dup array? [ 1array ] unless ;
: bool ( ? -- x ) 1 0 ? ;

: equal ( x y -- ? ) 2dup [ lambda? ] either? [ eq? ] [ = ] if ;

: iota ( x -- val )
  dup array?
  [ [ product iota ] [ [ abs ] map rest-slice <reversed> ] bi
    [ <groups> [ >array ] map ] each ]
  [ 0 over 0 > [ swap ] when [a..b) >array ] if
;

MEMO: primitives ( -- assoc )
  {
    { ' + 2 [ [ + ] 2scalar ] }
    { ' - 2 [ [ - ] 2scalar ] }
    { ' * 2 [ [ * ] 2scalar ] }
    { ' % 2 [ [ / ] 2scalar ] }
    { ' { 2 [ [ max ] 2scalar ] }
    { ' } 2 [ [ min ] 2scalar ] }
    { ' _ 1 [ [ neg ] 1scalar ] }
    { ' ~ 1 [ [ 1 swap - ] 1scalar ] }
    { ' = 2 [ [ = bool ] 2scalar ] }
    { ' < 2 [ [ < bool ] 2scalar ] }
    { ' > 2 [ [ > bool ] 2scalar ] }
    { ' & 2 [ equal bool ] }
    { ' ] 1 [ 1array ] }
    { ' , 2 [ [ listify ] bi@ append ] }
    { ' ; 2 [ nip ] }
    { ' : 3 [ [ apply ] dip apply ] }
    { ' ` 3 [ swap [ apply ] dip swap apply ] }
    { ' [ 2 [ swap apply ] }
    { ' ^ 2 [ [ apply ] keepd swap apply ] }
    { ' # 1 [ dup array? [ length ] [ drop 1 ] if ] }
    { ' ! 1 [ iota ] }
    { ' ' 2 [ [ apply ] curry map ] }
    { ' | 3 [ [ 2apply ] curry 2map ] }
    { ' @ 2 [ [ apply ] each ] }
    { ' / 2 [ [ unclip ] dip [ 2apply ] curry reduce ] }
    { ' \ 2 [ [ unclip ] dip [ 2apply ] curry accumulate swap suffix ] }
    { ' $ 1 [ listify reverse ] }
    { ' ? 1 [ [ <repetition> >array ] map-index concat ] }
  }
  [ first3 over { [ ] [ first ] [ first2 swap ] [ first3 spin ] } nth prepose
    { } func boa 2array ] map >hashtable
;

: eval ( ctx expr -- ctx val )
  { { [ dup fcall?  ] [ >fcall< [ eval ] dip swap [ eval ] dip swap apply ] }
    { [ dup ident?  ] [ inner>> over at ] }
    { [ dup prim?   ] [ inner>> primitives at clone ] }
    { [ dup numlit? ] [ inner>> ] }
    { [ dup vector? ] [ [ eval ] map >array ] }
    { [ dup lambda? ] [
      [ captures>> members [ [ over at ] keep swap ] H{ } map>assoc ]
      [ def>> ] [ name>> ] tri closure boa ] }
  } cond
;

: can-run-func ( func -- ? ) [ arity>> ] [ curr>> length ] bi <= ;

: apply ( ctx x f -- ctx f(x) )
  { { [ dup func? ] [
      clone [ swap suffix ] change-curr
      dup can-run-func [ [ curr>> ] [ impl>> ] bi call( ctx args -- ctx result ) ] when
    ] }
    { [ dup fixnum? ] [ over array? [ over length rem swap nth ] [ drop ] if ] }
    { [ dup array? ] [ [ [ apply ] keepd swap ] map nip ] }
    { [ dup closure? ]
      [ [ captures>> swap ] [ name>> pick set-at ] [ def>> ] tri eval nip ]
    }
  } cond
;

: boil ( string -- value ) parse 0 <hashtable> swap eval nip ;

: repl ( -- ) [ "    " write flush "\n" read-until drop boil . t ] loop ;
: main ( -- ) command-line get ?first [ repl f ] unless* utf8 strict file-contents boil print ;

MAIN: main