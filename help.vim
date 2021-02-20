" Vim syntax extention file for comment.txt
" Language: help
" Maintainer: Azshara <azshara.filter@outlook.com>

setlocal iskeyword+=-

" 中文小节标题行
" syn match helpHeadline "^[\u4e00-\u9fa5][\u4e00-\u9fa5 :]*[ \t]\+\*"me=e-1
syn match helpHeadline "^[^ *0-9\t][^*\t]\+[ \t]\+\*"me=e-1

" 带行号的文本块
syn match helpNoteLineNr "^\s*[0-9]\+" contained
syn match helpNoteLineNr "[ \t]\{8,}\zs[1-9]\+\ze" contained
syn match helpNoteSingleSymbol "//.*$" contained contains=helpNoteLineNr
syn match helpNoteSingleSymbol "#.*$" contained contains=helpNoteLineNr

syn region helpNoteDoubleSymbol start="/\*" end="\*/" contained contains=helpNoteLineNr
syn region helpNoteDoubleSymbol start="<!--" end="-->" contained contains=helpNoteLineNr

syn region helpTextArea matchgroup=helpTextAreaDelimiter start=" =t$" start="^=t$" end="^[^ \t]"me=e-1 end="^=t" concealends contains=helpNoteLineNr,helpNoteSingleSymbol,helpNoteDoubleSymbol,helpHeader

hi def link helpTextArea Normal
hi def link helpTextAreaDelimiter Normal
hi def link helpNoteLineNr LineNr
hi def link helpNoteSingleSymbol Comment
hi def link helpNoteDoubleSymbol Comment

" vim:ts=4:et:
