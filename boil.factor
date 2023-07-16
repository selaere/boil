USING: accessors arrays ascii assocs combinators command-line
continuations grouping hash-sets hashtables io
io.encodings.strict io.encodings.utf8 io.files io.styles kernel
math math.constants math.functions math.order math.parser
namespaces prettyprint prettyprint.custom prettyprint.sections
quotations ranges sequences sets strings ui.theme vectors ;
IN: boil

<< ALIAS: ' CHAR: >>

TUPLE: numlit { inner number } ;
TUPLE: ident  { inner string } ;
TUPLE: vardot { inner string } ;
TUPLE: prim   { inner fixnum } ;
SINGLETONS: '(' ')' '.' nothing ;

TUPLE: fcall  x f ;
: >fcall< ( fcall -- x f ) [ x>> ] [ f>> ] bi ;
TUPLE: lambda { captures hash-set } def { name string } ;
TUPLE: deeptoken token { depth fixnum } ;

TUPLE: func    { symbol union{ fixnum string } } { curr array } ;
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
    { [ over ";;" head? ] [ drop [ ' \n = not ] cut-some-while drop nothing ] }
    { [ dup ' \n = ] [ drop rest-slice nothing ] }
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
  over nothing = [ 2drop readdeeptoken ] [ swap [ swap deeptoken boa ] [ drop f ] if* ] if
;

: read-tokens ( code -- tokens code )
  0 <vector> swap [ readdeeptoken ] [ swap [ suffix ] dip ] while*
;
DEFER: read-at-depth
: read-lambda ( tokens name -- tokens lambda )
  [ rest-slice dup first depth>> 1 + read-at-depth ] dip make-lambda
;

: read-at-depth ( tokens depth -- tokens expr )
  [ unclip token>> ] [| d |
    0 <vector> swap
    [ dup ?first [ depth>> d < ] [ f ] if* ]
    [ dup ?first [ CHAR: ; prim boa 0 deeptoken boa ] unless*
      token>> dup '.' =
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
  [ ?rest-slice [ depth>> ] map 0 [ max ] reduce 1 + ] keep swap read-at-depth nip
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

ALIAS: ln log  ALIAS: exp e^
MEMO: primitives ( -- assoc )
  {
    { ' + 2 [ [ + ] 2scalar ] }
    { ' - 1 [ [ neg ] 1scalar ] }
    { ' * 2 [ [ * ] 2scalar ] }
    { ' % 1 [ [ recip ] 1scalar ] }
    { ' { 2 [ [ max ] 2scalar ] }
    { ' } 2 [ [ min ] 2scalar ] }
    { ' _ 1 [ [ floor ] 1scalar ] }
    { ' ~ 1 [ [ 1 swap - ] 1scalar ] }
    { ' = 2 [ [ = bool ] 2scalar ] }
    { ' < 2 [ [ < bool ] 2scalar ] }
    { ' > 2 [ [ > bool ] 2scalar ] }
    { ' & 2 [ equal bool ] }
    { ' ] 1 [ 1array ] }
    { ' , 2 [ [ listify ] bi@ append ] }
    { ' ; 1 [ ] }
    { ' : 3 [ [ apply ] dip apply ] }
    { ' ` 3 [ swapd 2apply ] }
    { ' [ 2 [ swap apply ] }
    { ' ^ 2 [ [ apply ] keepd swap apply ] }
    { ' # 1 [ dup array? [ length ] [ drop 1 ] if ] }
    { ' ! 1 [ iota ] }
    { ' ' 2 [ [ apply ] curry map ] }
    { ' | 3 [ [ 2apply ] curry 2map ] }
    { ' @ 2 [ nip ] }
    { ' / 2 [ [ unclip ] dip [ 2apply ] curry reduce ] }
    { ' \ 2 [ [ unclip ] dip [ 2apply ] curry accumulate swap suffix ] }
    { ' $ 1 [ listify reverse ] }
    { ' ? 1 [ [ <repetition> >array ] map-index concat ] }
    { "Pow" 2 [ [ ^ ] 2scalar ] }
    { "pi" 0 [ pi ] }
    { "Write" 1 [ write { } ] }
    { "Print" 1 [ print { } ] }
    { "Out" 1 [ ... { } ] }
  }
  { sin cos tan asin acos atan sqrt round exp ln }
  [ [ name>> unclip ch>upper prefix 1 ] [ 1quotation [ 1scalar ] curry ] bi 3array ] map append
  [ first3 2array ] H{ } map>assoc
;

: resolve ( ctx name -- ctx val/f )
  over ?at [ dup primitives at dup first 0 = [ nip second call( -- x ) ] [ drop { } func boa ] if ] unless
;

: eval ( ctx expr -- ctx val )
  { { [ dup fcall?  ] [ >fcall< [ eval ] dip swap [ eval ] dip swap apply ] }
    { [ dup ident?  ] [ inner>> resolve ] }
    { [ dup prim?   ] [ inner>> { } func boa ] }
    { [ dup numlit? ] [ inner>> ] }
    { [ dup vector? ] [ [ eval ] map >array ] }
    { [ dup lambda? ] [
      [ captures>> members [ [ resolve ] keep swap ] H{ } map>assoc ]
      [ def>> ] [ name>> ] tri closure boa ] }
  } cond
;

: get-arity    ( func -- arity ) symbol>> primitives at first  ;
: get-impl     ( func -- impl  ) symbol>> primitives at second ;
: can-run-func ( func -- ? ) [ get-arity ] [ curr>> length ] bi <= ;

: apply ( ctx x f -- ctx f(x) )
  { { [ dup func? ] [
      clone [ swap prefix ] change-curr
      dup can-run-func
      [ [ curr>> swap prefix ] [ get-impl ] bi with-datastack first2 ] when
    ] }
    { [ dup fixnum? ] [ over array? [ over length rem swap nth ] [ drop ] if ] }
    { [ dup array? ] [ [ [ apply ] keepd swap ] map nip ] }
    { [ dup closure? ]
      [ [ captures>> swap ] [ name>> pick set-at ] [ def>> ] tri eval nip ]
    }
  } cond
;

: show-symbol ( func -- ) 1string dim-color foreground associate styled-text ; 

M: func pprint*
  dup curr>> length 0 =
  [ symbol>> show-symbol ] [
    f <inset "(" text
    [ curr>> [ pprint* ] each ] [ symbol>> show-symbol ] bi
    ")" text block>
  ] if
;

: boil ( string -- value ) parse 0 <hashtable> swap eval nip ;

: repl ( -- ) [ "    " write flush "\n" read-until drop boil . t ] loop ;
: main ( -- ) command-line get ?first [ repl f ] unless* utf8 strict file-contents boil print ;

MAIN: main