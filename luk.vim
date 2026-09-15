" syntax/luk.vim : syntax for the "luk" language.
" Reuses Lua syntax then overlays luk-specific tokens.
if exists("b:current_syntax") | finish | endif

runtime! syntax/lua.vim
unlet! b:current_syntax

syntax clear luaError

" keywords: fn = function, elif = elseif, let = local
syntax match   lukKeyword     /\<fn\>/
syntax keyword lukDeclare     let
syntax keyword lukConditional elif

" `@` = return. Lua uses no `@`, so it needs no context.
syntax match lukReturn /@/

highlight default link lukKeyword     Keyword
highlight default link lukConditional Conditional
highlight default link lukReturn      Special
highlight default link lukDeclare     Operator

let b:current_syntax = "luk"
