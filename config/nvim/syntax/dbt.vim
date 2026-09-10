if exists('b:current_syntax')
  finish
endif

runtime! syntax/sql.vim
unlet! b:current_syntax

syntax region dbtJinjaExpression matchgroup=Special start=/{{/ end=/}}/ contains=dbtJinjaFunction,dbtJinjaString
syntax region dbtJinjaStatement matchgroup=Special start=/{%/ end=/%}/ contains=dbtJinjaKeyword,dbtJinjaFunction,dbtJinjaString
syntax region dbtJinjaComment start=/{#/ end=/#}/
syntax region dbtJinjaString contained start=/'/ end=/'/
syntax region dbtJinjaString contained start=/"/ end=/"/
syntax keyword dbtJinjaKeyword contained as else endfor endif endmacro for if in macro set
syntax keyword dbtJinjaFunction contained config env_var ref source var

highlight default link dbtJinjaComment Comment
highlight default link dbtJinjaFunction Function
highlight default link dbtJinjaKeyword Keyword
highlight default link dbtJinjaString String

let b:current_syntax = 'dbt'
