" syntax/fun.vim : syntax for the "fun" language.
" Reuses Lua syntax then overlays fun-specific tokens.
if exists("b:current_syntax") | finish | endif

runtime! syntax/lua.vim
unlet! b:current_syntax

syntax clear luaError

" `fun ... end` block (mirrors lua's luaFunctionBlock).
syntax region funFunBlock transparent matchgroup=funKeyword
  \ start=/\<fun\>/ end=/\<end\>/ contains=TOP

" `if (cond) ... end` block.
syntax region funIfBlock transparent matchgroup=funKeyword
  \ start=/\<if\>\ze\s*(/ end=/\<end\>/ contains=TOP

syntax keyword funKeyword  let else elseif
syntax match   funReturn   /!/
syntax match   funDeclare  /:=/
syntax match   funBlockCol /:\s*$/
syntax match   funBlockCol /:\s\+/

highlight default link funKeyword   Keyword
highlight default link funReturn    Special
highlight default link funDeclare   Operator
highlight default link funBlockCol  Operator

let b:current_syntax = "fun"
