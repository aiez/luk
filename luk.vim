" syntax/luk.vim : syntax for the "luk" language (end syntax).
" Reuses Lua syntax then overlays luk-specific tokens.
if exists("b:current_syntax") | finish | endif

runtime! syntax/lua.vim
unlet! b:current_syntax

syntax clear luaError

" `fn ... end` block (mirrors lua's luaFunctionBlock).
syntax region lukFnBlock transparent matchgroup=lukKeyword
  \ start=/\<fn\>/ end=/\<end\>/ contains=TOP

" `^` = return, only at statement start: line start or after
" `;` / `then` / `do` / `else` / `fn(...)`.
syntax match lukReturn /^\s*\zs\^/
syntax match lukReturn /\%(;\|\<then\>\|\<do\>\|\<else\>\)\s*\zs\^/
syntax match lukReturn /\<fn\>\s*([^)]*)\s*\zs\^/

syntax match lukDeclare  /:=/
syntax match lukNotEq    /!=/

highlight default link lukKeyword  Keyword
highlight default link lukReturn   Special
highlight default link lukDeclare  Operator
highlight default link lukNotEq    Operator

let b:current_syntax = "luk"
