" syntax/luk.vim : syntax for the sandbox "luk" dialect.
" Dialect: fun=function  ^=return  let NAME=V  X+=Y  colon blocks.
" Reuses Lua syntax then overlays luk-specific tokens.
if exists("b:current_syntax") | finish | endif

runtime! syntax/lua.vim
unlet! b:current_syntax

syntax clear luaError

" keywords: fun = function, let = local declaration
syntax match   lukKeyword /\<fun\>/
syntax keyword lukDeclare let

" block-header ":" at end of line ("if (x):", "fun f():", ...) and
" one-liner ": " colon-space ("if (x): !y"). Method colons (no
" space after) and "::labels::" don't match.
syntax match lukColon /[^:]\zs:\ze\s*$/
syntax match lukColon /[^:]\zs:\ze\s\+/

" `^` = return, only at statement start: line start, after ";",
" or after ": " one-liner colon. Mid-expression `^` stays pow.
syntax match lukReturn /^\s*\zs\^/
syntax match lukReturn /;\s*\zs\^/
syntax match lukReturn /:\s\+\zs\^/

" augmented assignment and not-equal
syntax match lukAugAssign /[-+*/]=/
syntax match lukNotEq     /!=/

highlight default link lukKeyword   Keyword
highlight default link lukDeclare   Keyword
highlight default link lukColon     Keyword
highlight default link lukReturn    Special
highlight default link lukAugAssign Operator
highlight default link lukNotEq     Operator

let b:current_syntax = "luk"
