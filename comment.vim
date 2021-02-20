" Vim global plugin for code comment
" Maintainer: Azshara <azshara.filter@outlook.com>
" Version:
" Last Change:

if exists('g:loaded_code_comment')
    finish
endif

let g:loaded_code_comment = 1

let s:save_cpo = &cpo
set cpo&vim

" 定义变量 {{{

let s:NOTE_ON = 1
let s:NOTE_OFF = 2
let s:NOTE_EMPTY = 4
let s:A_BLANK_SPACE = "\x20"
let s:DEFAULT_DELIMITER = ','
let s:DEFAULT_S_SYMBOL = '//'
let s:DEFAULT_D_SYMBOL = '/*'. s:DEFAULT_DELIMITER .'*/'
let s:INLINE_PREFIX = '*'. s:A_BLANK_SPACE

" 注释模式的消息标记
"
" s:FLAG_DEFAULT    默认
" s:FLAG_BLOCK      列块
" s:FLAG_EACH       伪模式表示双符号应用于每一行
" s:FLAG_FIRST      伪模式表示第一列插入双符号
" s:FLAG_SEMI       伪模式表示首和尾符号行是新建行
" s:FLAG_REVERSE    伪模式表示单符号反转
"
let s:FLAG_DEFAULT = 'Default'
let s:FLAG_BLOCK   = 'Block'
let s:FLAG_EACH    = 'Each'
let s:FLAG_FIRST   = 'First'
let s:FLAG_SEMI    = 'Semi'
let s:FLAG_REVERSE = 'Resver'
let s:presetFlag = s:FLAG_DEFAULT


" 和错误消息相关的定义
"
" s:FATAL   全局变量检测的致命(Fatal)错误并终止脚本
" s:WARNING 由用户在操作中产生的警告(Warning)错误并终止注释操作
" s:NOTE    TODO
" s:DEBUG   仅内部调试使用
"
let s:FATAL = [
    \ 'FA1: 缺省注释符号不匹配',
    \ 'FA2: 内行前辍设置不匹配',
    \ 'FA3: 第一列模式的字符串值不匹配',
    \ 'FA4: 每一行模式的字符串值不匹配',
\ ]

let s:WARNING = [
    \ 'WA1: 多余的注释符号行',
    \ 'WA2: 没用可用的双符号',
\ ]

let s:DEBUG = [
    \ 'DE1: 列块模式末行的最小空白宽度不匹配',
    \ 'DE2: 列块模式的首或尾符号行不是以首或尾符号结尾',
    \ 'DE3: 列块模式的内行前辍字符不匹配',
    \ 'DE4: 列块模式的内行最小空白宽度不区配',
\ ]

let s:ERROR_CODE = {
    \ 'Fatal'   :   s:FATAL,
    \ 'Warning' :   s:WARNING,
    \ 'Debug'   :   s:DEBUG,
\ }
"}}}

" 初始化 {{{
"
" Default separator
if exists('g:reset_default_delimiter')
    let s:isDelimiter = g:reset_default_delimiter
    let s:DEFAULT_D_SYMBOL = '/*'. s:isDelimiter .'*/'
else
    let s:isDelimiter = s:DEFAULT_DELIMITER
endif

" Default single symbol
if exists('g:reset_default_single_symbol')
    let s:isDefinedS = g:reset_default_single_symbol

    if stridx(s:isDefinedS, s:isDelimiter) != -1
        echomsg s:ERROR_LEVEL.Fatal[0]
        finish
    endif
else
    let s:isDefinedS = s:DEFAULT_S_SYMBOL
endif

" Default double symbol
if exists('g:reset_default_double_symbol')
    let s:isDefinedD = g:reset_default_double_symbol

    if stridx(s:isDefinedD, s:isDelimiter) == -1
        echomsg s:ERROR_LEVEL.Fatal[0]
        finish
    endif
else
    let s:isDefinedD = s:DEFAULT_D_SYMBOL
endif

" 是否关闭消息回显
if exists('g:close_echo_message') && g:close_echo_message
    let s:isMsg = 0
else
    let s:isMsg = 1
endif

" 当消息回显是启用状态时检测是否使用自定义消息
if s:isMsg
    if exists('g:custom_echo_message')
        \ && !empty(g:custom_echo_message)
        \ && len(g:custom_echo_message) == 2

        let s:isCustom = g:custom_echo_message
    else
        let s:isCustom = ['Cancle!', 'Done!']
    endif
endif

" 是否关闭一个空格
if exists('g:close_strict_space') && g:close_strict_space
    let s:isBlank = "\x0"
else
    let s:isBlank = s:A_BLANK_SPACE
endif

" 是否使用第一列模式的文件类型
if exists('g:allow_first_column_mode')
    let s:pattern = '^\(\([^,]\+\),\?\)\+[^, ]$'

    if matchstr(g:allow_first_column_mode, s:pattern) == ""
        echomsg s:ERROR_LEVEL.Fatal[2]
        finish
    endif

    let s:isFirstInsert = 1
    unlet s:pattern
else
    let s:isFirstInsert = 0
endif

" 是否使用每一行模式的文件类型
if exists('g:allow_each_line_mode')
    let s:pattern = '^\(\([^,]\+\),\?\)\+[^, ]$'

    if matchstr(g:allow_each_line_mode, s:pattern) == ""
        echomsg s:ERROR_LEVEL.Fatal['3']
        finish
    endif

    let s:isEachLineInsert = 1
    unlet s:pattern
else
    let s:isEachLineInsert = 0
endif

" 是否使用半成品列块模式的文件类型
if exists('g:allow_semi_block_mode')
    let s:pattern = '^\(\([^,]\+\),\?\)\+[^, ]$'

    if matchstr(g:allow_semi_block_mode, s:pattern) == ""
        echomsg s:ERROR_LEVEL.Fatal['3']
        finish
    endif

    let s:isSemiBlock = 1
    unlet s:pattern
else
    let s:isSemiBlock = 0
endif

" 是否启用单符号反转
if exists('g:open_single_reverse') && g:open_single_reverse
    let s:isReverse = 1
else
    let s:isReverse = 0
endif

" 是否启用列块模式
if exists('g:open_column_block_mode') && g:open_column_block_mode
    let s:presetFlag = s:FLAG_BLOCK
    let s:isColumnBlockMode = 1
else
    let s:isColumnBlockMode = 0
endif

" 内行前辍应该只有在启用了列块模式才可以设置，不过为了兼容在默认模式的取消操作
" 中可以取消列块模式的注释格式，只能跳出列块模式的检测。
if exists('g:d_line_prefix')
    if g:d_line_prefix == ""
        let s:isLinePrefix = g:d_line_prefix
    else

        if matchstr(g:d_line_prefix, '^\S') != ""
            let s:isLinePrefix = g:d_line_prefix
        else
            echomsg s:ERROR_LEVEL.Fatal[1]
            finish
        endif

    endif
else
    let s:isLinePrefix = s:INLINE_PREFIX
endif

if exists('g:method_synopsis')
    let s:isSummary = g:method_synopsis
else
    let s:isSummary = ['@return void']
endif

"}}}

" 映射 {{{

" Single
if !hasmapto('<Plug>CommentSingleToggle')
    nmap <silent> <unique> <Leader>cc <Plug>CommentSingleToggle
endif

nnoremap <silent> <unique> <script> <Plug>CommentSingleToggle <SID>SingleToggle
nnoremap <SID>SingleToggle :<C-U>call <SID>SingleToggle(0, 0)<CR>

if !hasmapto('<Plug>CommentHighSingleToggle')
    vmap <silent> <unique> <Leader>cc <Plug>CommentHighSingleToggle
endif

vnoremap <silent> <unique> <script> <Plug>CommentHighSingleToggle <SID>HighSingleToggle
vnoremap <SID>HighSingleToggle :<C-U>call <SID>HighSingleToggle()<CR>

" Double
if !hasmapto('<Plug>CommentDoubleToggle')
    nmap <silent> <unique> <Leader>dd <Plug>CommentDoubleToggle
endif

nnoremap <silent> <unique> <script> <Plug>CommentDoubleToggle <SID>DoubleToggle
nnoremap <SID>DoubleToggle :<C-U>call <SID>DoubleToggle(0, 0)<CR>

if !hasmapto('<Plug>CommentHighDoubleToggle')
    vmap <silent> <unique> <Leader>dd <Plug>CommentHighDoubleToggle
endif

vnoremap <silent> <unique> <script> <Plug>CommentHighDoubleToggle <SID>HighDoubleToggle
vnoremap <SID>HighDoubleToggle :<C-U>call <SID>HighDoubleToggle()<CR>

" Empty note
if !hasmapto('<Plug>CommentEmptyNote')
    imap <silent> <unique> <C-L>x <Plug>CommentEmptyNote
endif

inoremap <silent> <unique> <script> <Plug>CommentEmptyNote <SID>EmptyNote
inoremap <SID>EmptyNote :<C-U><C-R>=<SID>EmptyNote(0, 0)<CR>
"}}}

" 命令 {{{

if !exists(':SToggle')
    command -range SToggle call <SID>SingleToggle(<line1>, <line2>)
endif

if !exists(':DToggle')
    command -range DToggle call <SID>DoubleToggle(<line1>, <line2>)
endif
"}}}

" s:SingleToggle() {{{

" 单符号操作开关
" @param number sLine 命令行中范围的开始行号
" @param number eLine 命令行中范围的结束行号
" @return void
"
function s:SingleToggle(sLine, eLine)
    " key share
    if exists('b:doubleSymbol')
        call <SID>DoubleToggle(a:sLine, a:eLine)
        return
    endif

    let saCursor = getpos('.')

    " key share
    if !exists('b:singleSymbol')
        if !exists('b:symbol')
            let b:symbol = <SID>ParseCommentSymbol()
        endif

        let index = stridx(b:symbol[0], s:isDelimiter)

        " ['单符号']
        if index == -1
            let sS = b:symbol[0]
        else
            " ['首双符号,尾双符号']
            let b:doubleSymbol = [
                \strpart(b:symbol[0], 0, index),
                \strpart(b:symbol[0], index + 1),
            \]

            " 当只有一种双符号为注释符号时,先执行单符号按键操作时这里将执行，
            " 并直接调用双符号操作，同时将双符号存入缓冲变量 b:doubleSymbol
            " 并在双操作调用的函数中检查此变量以节省对注释符号的分析的步骤。当
            " 再次使用单操作时也会检查 b:doubleSymbol 变量，并直接调用双操作，
            " 这时单操作也节省了对注释符号分析的步骤。
            call <SID>DoubleToggle(a:sLine, a:eLine)
            return
        endif
    else
        let sS = b:singleSymbol
    endif

    " @var number 默认行号
    let curNo = saCursor[1]

    " @var number 默认循环界限
    let limit = curNo + 1

    " @var number 最大行号
    let lastNo = line('$')

    " command line
    if a:sLine || a:eLine
        let curNo = a:sLine
        let endNo = a:eLine
        let limit = endNo + 1
    endif

    " Key count
    if v:count > 1
        let limit = curNo + v:count

        if (limit - 1) > lastNo
            let limit  = lastNo + 1
        endif
    endif
    let curNo = <SID>GetRealCurrentLine(curNo, limit)

    if !curNo | return | endif

    if !exists('b:singleLen')
        let b:singleLen = strlen(sS)
    endif

    " 调用核心操作
    let result = <SID>SingleExecCore(curNo, limit, sS)

    if s:isMsg
        call <SID>SingleEcho(curNo, sS, result)
    endif

    call setpos('.', saCursor)
endfunction
"}}}

" s:DoubleToggle() {{{

" 定义双符号注释开关
" @param number sLine 命令行中范围的开始
" @param number eLine 命令行中范围的结束
" @return void
"
function s:DoubleToggle(sLine, eLine)
    if exists('b:singleSymbol')
        call <SID>SingleToggle(a:sLine, a:eLine)
        return
    end

    let saCursor = getpos(".")

    if !exists('b:doubleSymbol')
        if !exists('b:symbol')
            " ['单符号']
            " ['首双符号,尾双符号']
            " ['单符号', '首双符号,尾双符号']
            "
            " @var list 返回的固定格式如上
            let b:symbol = <SID>ParseCommentSymbol()
        endif

        " @var number -1 表示不存在分隔符号
        let index = stridx(b:symbol[0], s:isDelimiter)

        " ['首双符号,尾双符号']
        if index > -1
            " @var string dS 首符号
            " @var string dE 尾符号
            let dS = strpart(b:symbol[0], 0, index)
            let dE = strpart(b:symbol[0], index + 1)
        else
            " ['单符号', '首双符号,尾双符号']
            if index == -1 && len(b:symbol) == 2
                let index = stridx(b:symbol[1], s:isDelimiter)

                let dS = strpart(b:symbol[1], 0, index)
                let dE = strpart(b:symbol[1], index + 1)
            else
                " ['单符号']
                let b:singleSymbol = b:symbol[0]
                call <SID>SingleToggle(a:sLine, a:eLine)
                return
            endif
        endif
    else
        let dS = b:doubleSymbol[0]
        let dE = b:doubleSymbol[1]
    endif

    let curNo = saCursor[1]
    let endNo = saCursor[1]
    let lastNo = line('$')

    " @var bool 真值表示命令行的单行操作
    let exMutilFlag = 0

    if a:sLine || a:eLine
        let curNo = a:sLine
        let endNo = a:eLine

        if a:sLine == a:eLine
            let exMutilFlag = 1
        endif
    elseif v:count > 1
        let endNo = curNo + v:count - 1

        if endNo > lastNo
            let endNo = lastNo
        endif
    endif

    if !exists('b:dHeadLen')
        let b:dHeadLen = strlen(dS)
        let b:dTailLen = strlen(dE)
    endif

    if !exists('b:prefixLen')
        let b:prefixLen = len(s:isLinePrefix)
    endif

    let curStr = getline(curNo)

    " @var string dHeadChar 首字符
    " @var string dTailChar 尾字符
    let dHeadChar = <SID>GetHeadChar(curStr, b:dHeadLen)
    let dTailChar = <SID>GetTailChar(curStr, dE)

    let isPattFirst = <SID>IsPatternFirstMode()
    let isPattSemi = <SID>IsPatternSemiBlockMode()
    let isPattEach = <SID>IsPatternEachLineMode()

    let originalMessageFlag = s:presetFlag

    " 多行操作是简单，在多行操作中有明确范围的开始行号和结束行号。如果开始行存
    " 在首符号并且结束的行存在尾符号，那就是取消注释的操作，否则就是注释操作 (
    " 强硬注释)。单行操作比多行操作要复杂些，尤其当它们的双符号还是相同时。
    if (v:count > 1 || a:sLine || a:eLine) && !exMutilFlag
        let dTailChar = <SID>GetTailChar(getline(endNo), dE)

        if isPattEach
            let curNo = <SID>GetRealCurrentLine(curNo, endNo + 1)
            if !curNo | return | endif

            let pattern = '\V\^\s\*'. escape(dS, '\/') .'\.\*'
            let pattern .= dE .'\s\*\$'
            " 每一行模式不兼容其它模式的多行取消检测需要重定义
            let each = matchstr(getline(curNo), pattern) != ""
        endif

        if dHeadChar == dS && dTailChar == dE || exists("each") && each
            let l:args = [curNo, endNo, dS, dE, saCursor]
            let lines = <SID>CompatCancel(l:args)
        else
            let isNote = s:NOTE_ON

            let multiMode = s:isColumnBlockMode || isPattFirst || isPattSemi

            if multiMode && !isPattEach
                call <SID>CreateDoubleColBlock(curNo, endNo, dS, dE, saCursor)
                let endNo += 2
            else
                if isPattEach
                    let isNo = <SID>CreateDoubleEachLine(curNo,endNo+1,dS,dE)
                    if isNo | let endNo = isNo | endif
                else
                    let cC = <SID>DoubleEX(curNo, endNo, dS, dE, s:NOTE_ON)
                    execute cC[0]
                    execute cC[1]
                endif
            endif
        endif
    else
        """ 单行操作

        " 当首和尾符号完全相同时，如 python 的 "''','''"。并且只有首或尾符号的
        " 是独占行时，它不知道这是取消范围的开始行还是结束行，需单独定义。
        if dS == dE
            let tempStr = substitute(curStr, '^\s*', "", "")
            let onlyHead = substitute(tempStr, '\s*$', "", "")
        endif

        " 当首符号中包含以尾符号字符的结尾时需要特殊处理，如 sh ":<<EOF,EOF"。
        if matchstr(dHeadChar, dTailChar .'$') != "" && dS != dE
            let sameds= escape(dS, "\/'")
            let toTailEnd= matchstr(curStr, '\V\^\s\*'.sameds.'\s\*\$') != ""
        endif

        " @ var bool 如果是相同双符号中的首或尾符号独占一行时为真
        let isSameSymHead = exists("onlyHead") && onlyHead == dS

        " @ var bool 如果在首符号中包含以尾符号字符的结尾为真
        let isEndSame = exists("toTailEnd") && toTailEnd

        " 仅处理完全相同双符号的首或尾是独占行时的范围取消，如 "^\s*'''\s*$"。
        if isSameSymHead
            if lastNo / 2 > curNo
                let upValue = <SID>SameUpFilter(curNo, dS)

                " 如果相等先作为范围的开始行
                if upValue == curNo
                    let curNo = upValue
                    let isTrue = <SID>DownFindHead(curNo, dS, dE, lastNo)

                    " 如果为真作为范围的结束行
                    if isTrue
                        let endNo = isTrue
                        let l:args = [curNo, endNo, dS, dE, saCursor]
                        let lines = <SID>CompatCancel(l:args)
                    else
                        call <SID>ErrorHandle('Warning', 0)
                        return
                    endif
                else
                    let endNo = curNo
                    let curNo = upValue
                    let l:args = [curNo, endNo, dS, dE, saCursor]
                    let lines = <SID>CompatCancel(l:args)
                endif
            else
                let downValue = <SID>SameDownFilter(curNo, dS, lastNo)

                " 如果相等先作为范围的结束行
                if downValue == curNo
                    let isTrue = <SID>UpFindTail(curNo, dS, dE)

                    " 如果为真作为范围的开始行
                    if isTrue
                        let curNo = isTrue
                        let l:args = [curNo, endNo, dS, dE, saCursor]
                        let lines = <SID>CompatCancel(l:args)
                    else
                        call <SID>ErrorHandle('Warning', 0)
                        return
                    endif
                else
                    let endNo = downValue
                    let l:args = [curNo, endNo, dS, dE, saCursor]
                    let lines = <SID>CompatCancel(l:args)
                endif
            endif
        endif

        " 首和尾符号都在光标所在的行上时为取消单行注释
        "
        " 对完全相同部分尾字符相同的双符号需要过滤，因为它们的匹配总是相同的。
        " !isSameSymHead 过滤完全相同双符号
        " !isEndSame 过滤部分尾字符相同的双符号
        "
        if dHeadChar == dS && dTailChar == dE && !isSameSymHead && !isEndSame
            let row = <SID>ALineHandle(curNo, dS, dE, s:NOTE_OFF)
        endif

        " 首和尾符号都不在光标行上时可能是单行的注释或范围的取消注释
        "
        " 支持相同双符号，同时隐含的兼容了对首符号中包含并以尾符号字符结尾的行
        "
        if dHeadChar != dS && dTailChar != dE
            if dS != dE
                let isHeadTrue = <SID>UpFindTail(curNo, dS, dE)
                let isTailTrue = <SID>DownFindHead(curNo, dS, dE, lastNo)
            else
                " 这只有真值
                let l:up = <SID>SameUpFilter(curNo, dS)
                let l:down = <SID>SameDownFilter(curNo, dS, lastNo)

                if l:up != l:down
                    let isHeadTrue = l:up
                    let isTailTrue = l:down
                else
                    let isHeadTrue = 0
                endif
            endif

            if isHeadTrue && isTailTrue && !isPattEach
                let curNo = isHeadTrue
                let endNo = isTailTrue

                let l:args = [curNo, endNo, dS, dE, saCursor]
                let lines = <SID>CompatCancel(l:args)
            else
                " 第一列/半成品列块模式的单行注释操作
                if (isPattFirst || isPattSemi) && !isPattEach
                    let isNote = s:NOTE_ON

                    call <SID>CreateDoubleColBlock(curNo,endNo,dS,dE,saCursor)
                    let endNo += 2
                else
                    let row = <SID>ALineHandle(curNo, dS, dE, s:NOTE_ON)
                endif
            endif
        endif

        " 当光标在注释范围中的首行时向下查找尾符号
        "
        " 隐含的兼容了相同双符号像这样的行 "'^\s*'.dS.'\s*\S'"
        " isEndSame 允许首符号中包含并以尾符号字符结尾的并只的首符号的行
        " 
        if dHeadChar == dS && dTailChar != dE || isEndSame && !isPattEach
            let isTrue = <SID>DownFindHead(curNo, dS, dE, lastNo)

            if isTrue
                let endNo = isTrue
                let l:args = [curNo, endNo, dS, dE, saCursor]
                let lines = <SID>CompatCancel(l:args)
            else
                call <SID>ErrorHandle('Warning', 0)
                return
            endif
        endif

        " 当光标在注释范围中的末行时向上查找首符号
        "
        " 隐含的兼容了双符号像这样的行 "'\S\s*'.dE.'\s*$'"
        "
        if dHeadChar != dS && dTailChar == dE && !isPattEach
            let isTrue = <SID>UpFindTail(curNo, dS, dE)

            if isTrue
                let curNo = isTrue
                let l:args = [curNo, endNo, dS, dE, saCursor]
                let lines = <SID>CompatCancel(l:args)
            else
                call <SID>ErrorHandle('Warning', 0)
                return
            endif
        endif
    endif

    if s:isMsg
        let symchar = dS . s:isDelimiter . dE

        if exists('isNote') && isNote == s:NOTE_ON
            call <SID>ParseMessage(symchar, curNo, endNo, 1, s:presetFlag)

            if exists('originalMessageFlag')
                let s:presetFlag = originalMessageFlag
            endif
        endif

        if exists("lines")
            call <SID>DoubleEcho(symchar,curNo,endNo,"cancel",lines)
        endif

        if exists('row')
            call <SID>DoubleEcho(symchar,curNo,endNo,"aline", row)
        endif
    endif

    call setpos(".", saCursor)
endfunction
"}}}

" s:HighSingleToggle() {{{

" 定义高亮单符号操作开关
" @return void
"
function s:HighSingleToggle()
    if exists('b:doubleSymbol')
        call <SID>HighDoubleToggle()
        return
    endif

    " 重画屏幕后消息可回显
    redraw
    let saCursor = getpos('.')

    " 修正可视行时光标的列位置
    if visualmode(1) ==# 'V'
        redir => values
            silent marks <
        redir END

        let marksList = split(values, "\n")
        let [mname, mline, mcol; mth] = split(marksList[1])
        let saCursor[2] = mcol + 1
    endif

    if !exists('b:singleSymbol')
        if !exists('b:symbol')
            let b:symbol = <SID>ParseCommentSymbol()
        endif

        let index = stridx(b:symbol[0], s:isDelimiter)

        " ['单符号']
        if index == -1
            let sS = b:symbol[0]
        else
            " ['首双符号,尾双符号']
            let b:doubleSymbol = [
                \strpart(b:symbol[0], 0, index),
                \strpart(b:symbol[0], index + 1)
            \]

            call <SID>HighDoubleToggle()
            return
        endif
    else
        let sS = b:singleSymbol
    endif

    let curNo = line("'<")
    let endNo = line("'>")
    let limit = endNo + 1

    " 获取真实的操作行号
    let curNo = <SID>GetRealCurrentLine(curNo, limit)

    if !curNo
        " 如果操作的空行或空白行时退出无意义的操作
        call setpos('.', saCursor)
        return
    endif

    if !exists('b:singleLen')
        let b:singleLen = strlen(sS)
    endif

    " 调用核心操作
    let result = <SID>SingleExecCore(curNo, limit, sS)

    if s:isMsg
        call <SID>SingleEcho(curNo, sS, result)
    endif

    call setpos('.', saCursor)
endfunction
"}}}

" s:HighDoubleToggle() {{{

" 定义高亮双符号注释开关
" @return void
"
function s:HighDoubleToggle()
    if exists('b:singleSymbol')
        call <SID>HighSingleToggle()
        return
    end

    redraw
    let saCursor = getpos(".")

    if visualmode(1) ==# 'V'
        " Vim 7 不支持 execute(), 使用 redir 替代
        redir => values
            silent marks <
        redir END

        let marksList = split(values, "\n")
        let [mname, mline, mcol; mth] = split(marksList[1])
        let saCursor[2] = mcol + 1
    endif

    if !exists('b:doubleSymbol')
        if !exists('b:symbol')
            let b:symbol = <SID>ParseCommentSymbol()
        endif

        let index = stridx(b:symbol[0], s:isDelimiter)

        if index > -1
            let dS = strpart(b:symbol[0], 0, index)
            let dE = strpart(b:symbol[0], index + 1)
        else
            if index == -1 && len(b:symbol) == 2
                let index = stridx(b:symbol[1], s:isDelimiter)

                let dS = strpart(b:symbol[1], 0, index)
                let dE  = strpart(b:symbol[1], index + 1)
            else
                let b:singleSymbol = b:symbol[0]
                call <SID>HighSingleToggle()
                return
            endif
        endif
    else
        let dS = b:doubleSymbol[0]
        let dE = b:doubleSymbol[1]
    endif

    let curNo = line("'<")
    let endNo = line("'>")

    if !exists('b:dHeadLen')
        let b:dHeadLen = strlen(dS)
        let b:dTailLen = strlen(dE)
    endif

    if !exists('b:prefixLen')
        let b:prefixLen = len(s:isLinePrefix)
    endif

    let curStr = getline(curNo)
    let dHeadChar = <SID>GetHeadChar(curStr, b:dHeadLen)
    let dTailChar = <SID>GetTailChar(curStr, dE)

    if curNo != endNo
        let endStr    = getline(endNo)
        let dTailChar = <SID>GetTailChar(endStr, dE)
    endif

    let isPattFirst = <SID>IsPatternFirstMode()
    let isPattSemi = <SID>IsPatternSemiBlockMode()
    let isPattEach = <SID>IsPatternEachLineMode()

    let originalMessageFlag = s:presetFlag

    if isPattEach
        let curNo = <SID>GetRealCurrentLine(curNo, endNo + 1)
        if !curNo | return | endif

        let pattern = '\V\^\s\*'. escape(dS, '\/') .'\.\*'
        let pattern .= dE .'\s\*\$'

        " @var bool 如果是每一行模式的取消格式为真
        let each = matchstr(getline(curNo), pattern) != ""
    endif

    " 由于可视模式有指定的范围，这隐含了单行或多行的取消操作。
    if dHeadChar == dS && dTailChar == dE || exists("each") && each
        let l:args = [curNo, endNo, dS, dE, saCursor]
        let lines = <SID>CompatCancel(l:args)
    else
        " 注释操作与普通模式稍有差义

        " @var bool isMultiLine 表示列块模式的多行操作
        " @var bool isPattFirst 单行或多行的每一列模式操作
        " @var bool !isPattEach (取反) 除了每一行模式

        let isMultiLine = s:isColumnBlockMode &&  curNo != endNo

        if ( isMultiLine || isPattFirst || isPattSemi) && !isPattEach
            call <SID>CreateDoubleColBlock(curNo, endNo, dS, dE, saCursor)
            let endNo += 2

        else
            if isPattEach
                let isNo = <SID>CreateDoubleEachLine(curNo,endNo+1,dS,dE)
                if isNo | let endNo = isNo | endif
            else
                if curNo == endNo && s:isColumnBlockMode
                    let s:presetFlag = s:FLAG_DEFAULT
                endif

                " 列块的单行操作使用默认模式
                let cC = <SID>DoubleEX(curNo, endNo, dS, dE, s:NOTE_ON)
                execute cC[0]
                execute cC[1]
            endif
        endif
    endif

    if s:isMsg
        let symchar = dS . s:isDelimiter . dE

        if exists('lines')
            " @var number 取消操作中真实的末行号
            let l:last = <SID>DoubleEcho(symchar,curNo,endNo,"cancel",lines)
        else
            call <SID>ParseMessage(symchar, curNo, endNo, 1, s:presetFlag)

            if exists('originalMessageFlag')
                let s:presetFlag = originalMessageFlag
            endif
        endif
    endif

    if s:isColumnBlockMode || isPattFirst || isPattSemi
        execute curNo .'mark <'

        if exists("l:last")
            execute l:last .'mark >'
        else
            execute endNo .'mark >'
        endif
    endif

    call setpos('.', saCursor)
endfunction
"}}}

" s:CreateSingleColBlock(){{{

" 单符号列块注释操作
" @param number curNo
" @param number limit 循环界限，末行行号加1
" @param string sS
" @return void
"
function s:CreateSingleColBlock(curNo, limit, sS)
    let getWidth = <SID>GetSmallBlankWidth(a:curNo, a:limit)
    let baseWidth = getWidth[0]

    " 不受空格设置的影响 g:close_strict_space
    let sS = a:sS . "\x20"

    let incre = a:curNo
    let limit = a:limit

    while incre < limit
        let blankLine = <SID>IsBlankLine(incre)

        " 跳过空白行
        if blankLine
            let incre += 1
            continue
        endif

        let curStr = getline(incre)

        " 以基准位置分割字符串
        if baseWidth
            let left  = strpart(curStr, 0, baseWidth)
            let right = strpart(curStr, baseWidth)
        else
            " 如果是以可见字符开头的那么基准宽度为 0
            " @see <SID>GetSmallBlankWidth
            let left  = ""
            let right = curStr
        endif

        let replace = escape(left . sS . right, '\/&')
        execute incre .'s/^.*$/'. replace .'/'

        " 具有实际操作末行号
        let realEndNo = incre

        let incre += 1
    endwhile

    return realEndNo
endfunction
"}}}

" s:SingleExecCore(){{{
"
" 单符号操作核心
" @param number curNo
" @param number limit 末行号加1
" @param number sS 单符号
" @return {}
"   "endNo": 末行号
"   "category": s:NOTE_ON 或 s:NOTE_OFF
"   "record": 被反转的行数
"
function s:SingleExecCore(curNo, limit, sS)
    let headChar = <SID>GetHeadChar(getline(a:curNo), b:singleLen)

    " @var number 注释反转的行数
    let reverseRecord = 0

    " @var number 具有实际被操作修改的末行号
    let realEndNo = 0

    let incre = a:curNo

    if headChar == a:sS
        let isNote = s:NOTE_OFF

        while incre < a:limit
            " @var bool blankLine 真值表示空白行
            " @var bool resverComment 真值表示当前行的下一行存在注释符号

            let blankLine = <SID>IsBlankLine(incre)

            if blankLine
                " 过滤掉空白行并执行一个空操作
                let cC = <SID>SingleEX(incre, a:sS, s:NOTE_EMPTY)
                let resverComment = cC

                let incre += 1
                continue
            endif

            " 检测反转功能是否启用并且列块模式不使用反转
            if s:isReverse && !s:isColumnBlockMode
                " 检测是否需要反转
                if exists('resverComment') && !resverComment
                    let cC = <SID>SingleEX(incre, a:sS, s:NOTE_ON)
                    execute cC[0]

                    let realEndNo = incre
                    let resverComment = cC[1]
                    let reverseRecord += 1
                    let incre += 1

                    continue
                endif
            endif

            " 在反转功能是关闭时，过滤掉没有注释符号的行，因为取消操作是匹配不
            " 到没有注释符号的行，会报告找不到模式 E486。给它一个空操作可修正
            " 对多行执行取消操作时，对不连续有符号的行都可以取消注释。对注释操
            " 作不存在这样的情况，因为注释操作是强硬的。
            "
            if exists('resverComment') && !resverComment
                let cC = <SID>SingleEX(incre, a:sS, s:NOTE_EMPTY)

                let resverComment = cC
                let incre += 1

                continue
            endif

            " 缺省的操作
            let cC = <SID>SingleEX(incre, a:sS, s:NOTE_OFF)
            execute cC[0]

            let realEndNo = incre
            let resverComment = cC[1]
            let incre += 1
        endwhile
    else
        let isNote = s:NOTE_ON

        if s:isColumnBlockMode
            let realEndNo = <SID>CreateSingleColBlock(incre, a:limit, a:sS)
        else
            while incre < a:limit
                let bool = <SID>IsBlankLine(incre)

                if bool
                    let cC = <SID>SingleEX(incre, a:sS, s:NOTE_EMPTY)
                    let resverComment = cC
                    let incre += 1
                    continue
                endif

                if s:isReverse
                    if exists('resverComment') && resverComment
                        let cC = <SID>SingleEX(incre, a:sS, s:NOTE_OFF)
                        execute cC[0]

                        let realEndNo = incre
                        let resverComment = cC[1]
                        let reverseRecord += 1
                        let incre += 1

                        continue
                    endif
                endif

                let cC = <SID>SingleEX(incre, a:sS, s:NOTE_ON)
                execute cC[0]

                let realEndNo = incre
                let resverComment = cC[1]
                let incre += 1
            endwhile
        endif
    endif

    return {'endNo':realEndNo, 'category':isNote, 'record':reverseRecord}
endfunction
"}}}

" s:SingleEcho(){{{
"
" 回显单符号操作消息
" @see <SID>SingleToggle()
" @see <SID>SingleExecCore()
"
" @param number curNo
" @param string sS
" @param {} info
" @return void
"
function s:SingleEcho(curNo, sS, info)
    let endNo = a:info.endNo

    if s:isReverse && a:info.record
        if a:info.category == s:NOTE_ON
            call <SID>ParseMessage(a:sS, a:curNo, endNo, 1, s:FLAG_REVERSE)
        else
            call <SID>ParseMessage(a:sS, a:curNo, endNo, 0, s:FLAG_REVERSE)
        endif
    else
        if a:info.category == s:NOTE_OFF
            call <SID>ParseMessage(a:sS, a:curNo, endNo, 1, s:presetFlag)
        else
            call <SID>ParseMessage(a:sS, a:curNo, endNo, 0, s:presetFlag)
        endif
    endif
endfunction
"}}}

" s:GetRealCurrentLine(){{{

" 获取真实的操作行号仅用于单符号操作
" @param number curNo
" @param number limit
" @return number 返回真实的操作行号，如果返回 0 表示操作的是空行或空白行。
"
function s:GetRealCurrentLine(curNo, limit)
    let curNo = a:curNo
    let bLine = <SID>IsBlankLine(curNo)

    while bLine && curNo < a:limit
        let curNo += 1
        let bLine = <SID>IsBlankLine(curNo)
    endwhile

    if curNo == a:limit
        return 0
    else
        return curNo
    endif
endfunction
"}}}

" s:CreateDoubleColBlock(){{{

" 双符号列块模式的注释操作
"
" 关于注释格式: 首行的首符号在最小空白宽度之后写入，其它行在最小空白宽度加1后
" 的位置写入。
"
" @param number curNo 首行号
" @param number endNo 末行号
" @param string dS 首双符号
" @param string dS 尾双符号
" @param list cursor 光标位置信息
" @return void
"
function s:CreateDoubleColBlock(curNo, endNo, dS, dE, cursor)
    let dS = escape(a:dS, '\/&')
    let dE = escape(a:dE, '\/&')

    let headLineNo = a:curNo
    let tailLineNo = a:endNo

    let valueList = <SID>GetSmallBlankWidth(a:curNo, a:endNo+1)

    let baseWidth = valueList[0]
    let oWidth = baseWidth + 1

    " 创建一个用于首符号的空行
    "
    " 兼容 Ex 命令 "DToggle"
    execute ":". headLineNo

    execute "normal O" | redraw
    let a:cursor[1] += 1
    let tailLineNo += 1

    " 创建一个用于尾符号的空行
    execute ":". tailLineNo
    execute "normal o" | redraw
    let tailLineNo += 1

    if s:isFirstInsert && <SID>IsPatternFirstMode()
        let s:presetFlag = s:FLAG_FIRST
        call <SID>PadSpace(headLineNo, dS, 0)
        call <SID>PadSpace(tailLineNo, dE, 0)
        return
    endif

    if s:isSemiBlock && <SID>IsPatternSemiBlockMode()
        let s:presetFlag = s:FLAG_SEMI
        call <SID>PadSpace(headLineNo, dS, baseWidth)
        call <SID>PadSpace(tailLineNo, dE, baseWidth)
        return
    endif

    call <SID>PadSpace(headLineNo, dS, baseWidth)
    call <SID>PadSpace(tailLineNo, dE, oWidth)

    let incre = headLineNo + 1
    let limit = tailLineNo

    while incre < limit
        let curStr = getline(incre)
        let curLen = strlen(curStr)

        let blankLine = <SID>IsBlankLine(incre)

        if blankLine
            " 将空白行变为空行
            if curLen > 0
                execute incre .'s/^.*$/'

                " 空行长度为0，字符为空。
                let curStr = ""
                let curLen = 0
            endif

            " 如果前辍为空填充无意义并跳过空白行
            if s:isLinePrefix == ""
                let incre +=1
                continue
            endif

            while curLen < oWidth
                let curStr .= "\x20"
                let curLen = strlen(curStr)
            endwhile
        else
            " 非空白行缩进一个空格
            let curStr = "\x20". curStr
        endif

        let left  = strpart(curStr, 0, oWidth)
        let right = strpart(curStr, oWidth)

        " 符号 & 在替换中有特殊意义 :h &
        let replace = escape(left . s:isLinePrefix . right, '\/&')
        execute incre .'s/^.*$/'. replace

        let incre += 1
    endwhile
endfunction
"}}}

" s:UndoDoubleColBlock{{{

" 双符号块列模式的取消操作
" @param number curNo 首行号
" @param number endNo 末行号
" @param string command 仅作用内行的 Ex 字符串命令
" @param [] cursor 原光标位置信息
" @return void
"
function s:UndoDoubleColBlock(curNo, endNo, command, cursor)
    let incre = a:curNo + 1

    while incre < a:endNo
        let blankLine = <SID>IsBlankLine(incre)

        " 空白行处理，这隐含了对前辍字符的处理。
        if blankLine
            execute incre .'s/^\(\s*\)$/'
        else
            " 是否只有前辍字符的行
            let iop = <SID>IsOnlyPrefix(incre)

            if iop
                " execute incre . 's/'. iop
                execute incre .'s/^.*$/'
            else
                execute incre . a:command
            end
        endif

        let incre += 1
    endwhile

    " 删除首和尾行并写入到 "_ 寄存器
    execute a:endNo .'g/^.*$/normal "_dd'
    execute a:curNo .'g/^.*$/normal "_dd'

    call <SID>RestoreCursor(a:curNo, a:endNo, a:cursor)
endfunction
"}}}

" s:CreateDoubleEachLine(){{{
"
" 每一行模式的双符号创建
" @param number curNo
" @param number limit
" @param string dS
" @param string dE
" @return void
"
function s:CreateDoubleEachLine(curNo, limit, dS, dE)
    let cC = <SID>DoubleEX(a:curNo, a:limit-1, a:dS, a:dE, s:NOTE_ON)

    " 首和尾符号在 <SID>DoubleEX 中转义
    let dS = escape(a:dS, '\/')
    let dE = escape(a:dE, '\/')

    let realEndNo = 0

    let incre = a:curNo

    while incre < a:limit
        let blankLine = <SID>IsBlankLine(incre)

        if blankLine
            let incre += 1
            continue
        endif

        let pattern = '\V\^\s\*'. dS .'\.\*'. dE .'\s\*\$'
        let correct = matchstr(getline(incre), pattern) == ""

        if correct
            execute incre cC[0]
            execute incre cC[1]
            let realEndNo = incre
        endif

        let incre += 1
    endwhile

    let s:presetFlag = s:FLAG_EACH
    return realEndNo
endfunction
"}}}

" s:UndoDoubleEachLine(){{{
"
" 每一行模式的双符号取消
" @see <SID>CreateDoubleEachLine()
"
function s:UndoDoubleEachLine(curNo, limit, dS, dE)
    let cC = <SID>DoubleEX(a:curNo, a:limit-1, a:dS, a:dE, s:NOTE_OFF)

    let dS = escape(a:dS, '\/')
    let dE = escape(a:dE, '\/')

    let realEndNo = 0

    let incre = a:curNo

    while incre < a:limit
        let blankLine = <SID>IsBlankLine(incre)

        if blankLine
            let incre += 1
            continue
        endif

        let pattern = '\V\^\s\*'. dS .'\.\*'. dE .'\s\*\$'
        let correct = matchstr(getline(incre), pattern) != ""

        if correct
            execute incre cC[0]
            execute incre cC[1]
            let realEndNo = incre
        endif

        let incre += 1
    endwhile

    return realEndNo
endfunction
"}}}

" s:CompatCancel(){{{

" 注释模式兼容的多行取消注释
" @param [] input 0首行号 1末行号 2首符号 3末符号 4光标信息的列表
" @return number|string|list|null
"   number  在列块模式或第一列模式
"   string  在列块模式取消默认模式
"   list    [number real_number, string original_message_flag]
"           在列块模式取消第一列模式
"           在默认模式取消列块格式
"           在默认模式取消第一列模式
"   null    在默认模式取消默认模式的返回空

function s:CompatCancel(input)
    let first = a:input[0]
    let l:last = a:input[1]
    let dS  = a:input[2]
    let dE  = a:input[3]
    let cursor = a:input[4]

    let temp = s:presetFlag

    let comm = <SID>DoubleEX(first, l:last, dS, dE, s:NOTE_OFF)

    let isFormat = <SID>IsStrictFormat(first, l:last, dS, dE)

    let isPattFirst = <SID>IsPatternFirstMode()
    let isPattEach = <SID>IsPatternEachLineMode()
    let isPattSemi = <SID>IsPatternSemiBlockMode()

    if isPattFirst || isFormat[0] || isPattSemi
        let realEndNo = l:last - 2
    endif

    if s:isColumnBlockMode
        if isFormat[0]
            call <SID>UndoDoubleColBlock(first, l:last, comm, cursor)
            return realEndNo
        else
            let s:presetFlag = s:FLAG_DEFAULT

            let s:isColumnBlockMode = 0
            let dEx = <SID>DoubleEX(first, l:last, dS, dE, s:NOTE_OFF)
            let s:isColumnBlockMode = 1

            if isPattEach
                let s:presetFlag = s:FLAG_EACH
                let endNo = <SID>UndoDoubleEachLine(first, l:last+1, dS, dE)
                return [endNo, temp]
            endif

            " 默认/第一列/半成品
            execute dEx[0]
            execute dEx[1]

            if isPattFirst
                let s:presetFlag = s:FLAG_FIRST
                call <SID>RestoreCursor(first, l:last, cursor)
                return [realEndNo, temp]
            endif

            if isPattSemi
                let s:presetFlag = s:FLAG_SEMI

                call <SID>RestoreCursor(first, l:last, cursor)
                return [realEndNo, temp]
            endif

            return temp
        endif
    else
        if isFormat[0]
            let s:presetFlag = s:FLAG_BLOCK

            let s:isColumnBlockMode = 1
            let cEx = <SID>DoubleEX(first, l:last, dS, dE, s:NOTE_OFF)
            let s:isColumnBlockMode = 0

            call <SID>UndoDoubleColBlock(first, l:last, cEx, cursor)
            return [realEndNo, temp]
        else
            if isPattEach
                let s:presetFlag = s:FLAG_EACH
                let endNo = <SID>UndoDoubleEachLine(first, l:last+1, dS, dE)
                return [endNo, temp]
            endif

            execute comm[0]
            execute comm[1]

            if isPattFirst
                let s:presetFlag = s:FLAG_FIRST

                call <SID>RestoreCursor(first, l:last, cursor)
                return [realEndNo, temp]
            endif

            if isPattSemi
                let s:presetFlag = s:FLAG_SEMI

                call <SID>RestoreCursor(first, l:last, cursor)
                return [realEndNo, temp]
            endif

            return v:null
        endif
    endif
endfunction
"}}}

" s:ALineHandle(){{{

" 双符号单行注释或取消注释
" @see <SID>DoubleToggle()
" @param number curNo
" @param string dS
" @param string dE
" @param number type s:NOTE_ON | s:NOTE_OFF
" @return number|list [number type, string message_flag]
"
function s:ALineHandle(curNo, dS, dE, type)
    if s:isColumnBlockMode
        let temp = s:presetFlag
        let s:presetFlag = s:FLAG_DEFAULT
        " 复位
        let s:isColumnBlockMode = 0
    endif

    " 调用默认模式的 Ex 字符串命令
    let eX = <SID>DoubleEX(a:curNo, a:curNo, a:dS, a:dE, a:type)
    execute eX[0]
    execute eX[1]

    if exists('temp')
        let s:isColumnBlockMode = 1
    endif

    " 每一行模式单行操作消息标记
    if <SID>IsPatternEachLineMode()
        let temp = s:presetFlag
        let s:presetFlag = s:FLAG_EACH
    endif

    if exists('temp')
        return [a:type, temp]
    else
        return a:type
    endif

endfunction
"}}}

" s:DoubleEcho(){{{
"
" 回显双符号操作消息
"
" 由于不同模式的影响，及取消的兼容操作，导致返回消息不整齐。需要分别处理。
"
" @see <SID>CompatCancel()
" @see <SID>ALineHandle()
" @see <SID>DoubleToggle()
" @see <SID>HighDoubleToggle()
" @see <SID>ParseMessage()
"
" @param string symbol
" @param number curNo
" @param number endNo
" @param string category
"   "cancel" 多行取消
"   "aline"  单行注释或取消注释
" @param mixed info 根据 category 的不同返回不同的值
" @return void
"
function s:DoubleEcho(symbol,curNo,endNo,category,info)
    let l:endNo = a:endNo

    if a:category == 'cancel'
        if type(a:info) == type([])
            " v:t_list
            let l:endNo = a:info[0]
            let originalMessageFlag = a:info[1]
        elseif type(a:info) == type(0)
            " v:t_number
            let l:endNo = a:info
        elseif type(a:info) == type("")
            " v:t_string
            let originalMessageFlag = a:info
        elseif type(a:info) == type(v:none)
            " v:t_none
        endif

        call <SID>ParseMessage(a:symbol, a:curNo, l:endNo, 0, s:presetFlag)
    endif

    if a:category == 'aline'
        if type(a:info) == type([])
            let opt = a:info[0]
            let originalMessageFlag = a:info[1]
        else
            let opt = a:info
        endif

        if opt == s:NOTE_ON
            call <SID>ParseMessage(a:symbol, a:curNo, a:endNo, 1,s:presetFlag)
        endif

        if opt == s:NOTE_OFF
            call <SID>ParseMessage(a:symbol, a:curNo, a:endNo, 0,s:presetFlag)
        endif
    endif

    " 恢复原模式消息标记
    if exists("originalMessageFlag")
        let s:presetFlag = originalMessageFlag
    endif

    return l:endNo
endfunction
"}}}

" s:EmptyNote(){{{
" 
" 带摘要的空注释
" @return string 返回空字符 "\x0"
"
function s:EmptyNote(sLine, eLine)
    stopinsert
    let saCursor = getpos(".")

    let sym = <SID>ParseCommentSymbol()

    let index = stridx(sym[0], s:isDelimiter)

    " ['首双符号,尾双符号']
    if index > -1
        let dS = strpart(sym[0], 0, index)
        let dE = strpart(sym[0], index + 1)
    else
        " ['单符号', '首双符号,尾双符号']
        if index == -1 && len(sym) == 2
            let index = stridx(sym[1], s:isDelimiter)
            let dS = strpart(sym[1], 0, index)
            let dE = strpart(sym[1], index + 1)
        else
            " 对不对支持双符号文件停止操作
            return
        endif
    endif

    let dS = escape(dS, '\/&')
    let dE = escape(dE, '\/&')

    let curNo = line(".")
    let temp = curNo

    let amount = str2nr(nr2char(getchar()))
    if amount < 3 | let amount = 3 | endif

    let headPos = strlen(matchstr(getline(curNo), '^\s*'))
    let otherPos = headPos + 1

    let sumLen = len(s:isSummary)

    " 首符号行
    call <SID>PadSpace(temp, dS, headPos)

    let incre = 0

    while incre <= amount
        execute "normal o\<Esc>"
        let temp += 1

        let scaler = 0
        let str = ""

        while scaler < otherPos
            let str .= "\x20"
            let scaler = strlen(str)
        endwhile

        if sumLen && incre
            execute temp .'s/^.*$/'. str ."*\x20". s:isSummary[incre-1]
            let sumLen -= 1
        else
            execute temp .'s/^.*$/'. str ."*\x20"
        endif

        let incre += 1
    endwhile

    " 末符号行
    call <SID>PadSpace(temp, dE, otherPos)

    let saCursor[1] = curNo + 1
    call setpos(".", saCursor)

    startinsert!

    " 返回空是有必要的，否则默认返回值 0 在插入模式光标之前。
    return "\x0"
endfunction
"}}}

" s:ParseCommentSymbol() {{{
"
" 解析注释符号
" @return [] 返回包含了注释符号的列表,该列表长度不是1就是2
"
function s:ParseCommentSymbol()
    if !exists('g:add_comment_symbol')
        return [s:isDefinedS, s:isDefinedD]
    endif

    " call <SID>IsValueCorrect()

    let ft  = &filetype
    let fn  = expand('%')
    let ext = expand('%:e')

    " 解析格式
    "
    " ['ft:php,javascript,css', '//', '/*,*']
    " [['ft:php,javascript,css', '//', '/*,*'], ...]

    let tempCell = []

    for item in g:add_comment_symbol
        if type(item) != type([])
            " @var string item 一维列表字符串项添加为新列表
            call add(tempCell, item)
            continue
        endif

        if !empty(tempCell)
            let item = tempCell
        endif

        " @var list item
        " @var list temp
        let temp = split(item[0], ':')
        let headType = temp[0]

        " @var list
        let headCell = split(temp[1], s:isDelimiter)
        let headLen  = len(headCell)

        " @var list 注释符号列表，未设置符号时为空列表
        let symCell = item[1:]

        if empty(symCell)
            let result = [s:isDefinedS, s:isDefinedD]
        else
            let symLen = len(symCell)

            if symLen == 1
                " ['首双符号,尾双符号']
                " ['单符号']
                let result = [symCell[0]]
            else
                " ['单符号', '首双符号,尾双符号']
                " ['首双符号,尾双符号', '单符号']

                let l:index = stridx(symCell[0], s:isDelimiter)

                " 调整顺序后 ['单符号', '首双符号,尾双符号']，这是有必要的，在
                " 分析该函数返回值时，不必考虑顺序。
                if l:index == -1
                     let result = [symCell[0], symCell[1]]
                else
                     let result = [symCell[1], symCell[0]]
                endif
            endif
        endif

        " @var number 自增的初始值0
        let incre = 0

        if headType == 'ft'
            while incre < headLen
                if ft == headCell[incre]
                    return result
                endif

                let incre += 1
            endwhile
        elseif headType == 'fn'
            while incre < headLen
                if fn == headCell[incre]
                    return result
                endif

                let incre += 1
            endwhile
        elseif headType == 'ext'
            while incre < headLen
                if ext == headCell[incre]
                    return result
                endif
                let incre += 1
            endwhile
        endif
    endfor

    " 如果检测不到 g:add_comment_symbol 中的关联使用默认的注释符号
    return [s:isDefinedS, s:isDefinedD]
endfunction
"}}}

" s:ParseMessage() {{{

" 解析回显消息
" @see s:isCustom
" @see s:FLAG_DEFAULT
"
" @param string symbol some  some[0] 和行号信息 some[1]
" @param number curNo some  some[0] 和行号信息 some[1]
" @param number endNo some  some[0] 和行号信息 some[1]
" @param int item   0取消注释消息 1注释消息
" @param string flag
" @return void
"
function s:ParseMessage(symbol, curNo, endNo, item, flag)
    " Annotation symbol
    let temp = a:symbol . s:A_BLANK_SPACE

    " Message flag
    if a:flag == s:FLAG_FIRST
        let temp .= s:FLAG_FIRST

    elseif a:flag == s:FLAG_DEFAULT
        let temp .= s:FLAG_DEFAULT

    elseif a:flag == s:FLAG_BLOCK
        let temp .= s:FLAG_BLOCK

    elseif a:flag == s:FLAG_REVERSE
        let temp .= s:FLAG_REVERSE

    elseif a:flag == s:FLAG_SEMI
        let temp .= s:FLAG_SEMI

    elseif a:flag == s:FLAG_EACH
        let temp .= s:FLAG_EACH
    endif

    " Single line
    if a:curNo == a:endNo
        let temp .=  s:A_BLANK_SPACE . a:curNo
    else
        " Multi line
        let temp .= s:A_BLANK_SPACE
        let temp .= a:curNo . s:isDelimiter . a:endNo
    endif

    " Output message
    echohl Tag | echo '['. temp .'] '. s:isCustom[a:item] | echohl None
endfunction
"}}}

" s:SingleEX() {{{
"
" 单符号 Ex 命令
" 拼装单符号操作的 Ex 字符串命令。单符号列块的注释操作不经过此函数。
"
" @param number curNo
" @param string sS 单符号
" @param number type 操作类型: s:NOTE_OFF | s:NOTE_ON | s:NOTE_EMPTY
" @return bool | [string Ex, bool flag ]
"     bool 表示当前行的下一行存在单符号为真，反之为假。
"     Ex 返回列表包含了字符串形式的 Ex 命令
"     flag 表示当前行的下一行存在单符号为真，反之为假。
"
function s:SingleEX(curNo, sS, type)
    let sS = escape(a:sS, '/\')
    let strict = sS . s:isBlank

    let currStr = getline(a:curNo)
    let nextStr = getline(a:curNo + 1)

    " 检测操作行单符号之后的空格数量。
    " 当空格的数量分别为 0 个或 1 个和至少 2 个时使用不同的匹配替换。
    " 这样在取消注释时更灵活并对至少2个的空格操作时也不影响正常的缩进。
    let currGtLt2Space = matchstr(currStr, '\V\^\(\s\*\)'. sS .'\s\{2,}')

    " @var string patCo_1
    " @var string patCo_2
    " @var bool patCo 当前行的下一行存在单符号为真，将用于反转的标识。

    let patCo_1 = matchstr(nextStr, '\V\^'. sS)
    let patCo_2 = matchstr(nextStr, '\V\^\s\+'. sS)
    let patCo   = patCo_1 != "" || patCo_2 != ""

    if a:type == s:NOTE_EMPTY
        return patCo
    endif

    if a:type == s:NOTE_OFF
        " 列块取消操作不受空格设置的影响
        if s:isColumnBlockMode
            let strict = sS . "\x20"
        endif

        if currGtLt2Space != ""
            " 当两个以上空格(包括两个)时对空格严格
            return [
                \ a:curNo .'s/\V\^\(\s\*\)'. strict .'\(\.\*\)\$/\1\2/',
                \ patCo]
        else
            " 当空格为 0 个或 1 个时空格不严格
            return [
                \ a:curNo .'s/\V\^\(\s\*\)'. sS .'\s\?\(\.\*\)\$/\1\2/',
                \ patCo]
        endif
    endif

    if a:type == s:NOTE_ON
        let strict = escape(strict, '&')
        return [a:curNo.'s/\V\^\(\s\*\)\(\.\*\)\$/\1'. strict .'\2/', patCo]
    endif
endfunction
"}}}

" s:DoubleEX() {{{
"
" 双符号操作命令的拼装
" @param number curNo
" @param number endNo   如果和 curNo 相同将作用于单行
" @param string dS      首双符号
" @param string dE      尾双符号
" @param number type    操作类型: s:NOTE_OFF 或 s:NOTE_ON
" @return string | list
"   string  仅列块模式内行的 Ex 字符串命令
"   list    [string tail_command, string head_command]
"               tail_command 尾符号行字符串形式的 Ex 命令
"               head_command 首符号行字符串形式的 Ex 命令
"
function s:DoubleEX(curNo, endNo, dS, dE, type)
    let isPattEach = <SID>IsPatternEachLineMode()

    " 取消操作: 所有模式，不包括列块的首和尾行。
    if a:type == s:NOTE_OFF
        let dS = escape(a:dS, '/\')
        let dE = escape(a:dE, '/\')

        if isPattEach
            let tail = 's/\V\s\?'. dE .'\s\*\$'
            let head = 's/\V\^\(\s\*\)'. dS .'\s\?/\1'
            return [tail, head]
        endif

        if s:isColumnBlockMode
            " @see <SID>UndoDoubleColBlock()
            let prefix = escape(s:isLinePrefix, '\/')
            return 's/\V\^\(\s\*\)\s\{1}'. prefix .'/\1/'
        else
            let isHeadEnd = <SID>IsHeadSymEnd(a:curNo, a:dS, 0)
            let isTailEnd = <SID>IsTailSymEnd(a:endNo, a:dE, 0)

            let isPattFirst = <SID>IsPatternFirstMode()
            let isPattSemi = <SID>IsPatternSemiBlockMode()

            if isHeadEnd
                if isPattFirst || isPattSemi
                    let head = a:curNo .'g/^.*$/normal "_dd'
                else
                    let head = a:curNo .'s/^.*$/'
                endif
            else
                let head = a:curNo .'s/\V\^\(\s\*\)'. dS .'\s\?/\1/'
            endif

            if isTailEnd
                if isPattFirst || isPattSemi
                    let tail = a:endNo .'g/^.*$/normal "_dd'
                else
                    let tail = a:endNo .'s/^.*$/'
                endif
            else
                let tail = a:endNo .'s/\V\s\?' . dE .'\s\*\$/'
            endif

            return [tail, head]
        endif
    endif

    " 注释操作: 仅默认模式和每一行模式
    if a:type == s:NOTE_ON
        let dS = escape(a:dS, '/\#&')
        let dE = escape(a:dE, '/\#&')

        if isPattEach
            let head = 's#\v^(\s*)#\1'. dS . s:isBlank
            let tail = 's#\v(.*)$#\1'. s:isBlank . dE
            return [head, tail]
        endif

        let smallWidth = <SID>GetSmallBlankWidth(a:curNo, a:endNo+1)
        let insertPosition = smallWidth[0]

        let isHeadBlank = <SID>IsBlankLine(a:curNo)

        if isHeadBlank
            call <SID>PadSpace(a:curNo, dS, insertPosition)
            let head = ""
        else
            let head = a:curNo. 's#\v^(\s*)(.*)$#\1'. dS . s:isBlank .'\2#'
        endif

        " @var bool 执行位置隐含了单行操作时首符号不会被尾符号覆盖
        let isTailBlank = <SID>IsBlankLine(a:endNo)

        if isTailBlank
            call <SID>PadSpace(a:endNo, dE, insertPosition)
            let tail = ""
        else
            let tail = a:endNo. 's#\v^(.*)$#\1'. s:isBlank . dE .'#'
        endif

        return [head, tail]
    endif
endfunction
"}}}

" s:UpFindTail() {{{
"
" 向上查找只有两种情况: 在尾符号的行向上查找;在首和尾符号都不存在的行向上找。
" @param number lineNo  当前行号
" @param string needleS 首符号
" @param string needleE 尾符号
" @return number 0|1
"
function s:UpFindTail(lineNo, needleS, needleE)
    if a:lineNo == 1
        return 0
    endif

    let prevNo = a:lineNo - 1

    while prevNo
        let str = getline(prevNo)

        if a:needleS != a:needleE
            let ndS = <SID>GetHeadChar(str, b:dHeadLen)
            let ndE = <SID>GetTailChar(str, a:needleE)

            " 优先找尾符号，防止一行的首和尾符号同时存在。
            if ndE == a:needleE
                " 过滤尾字符，如 sh 的双符号 ":<<EOF,EOF"，有相同的 EOF 结尾。
                if ndS != a:needleS
                    return 0
                end
            endif

            if ndS == a:needleS
                return prevNo
            endif
        else
            " 对于相同的双符号已确定的尾符号向上查找
            let dS = escape(a:needleS, '\/')
            " char '''
            let ndS = matchstr(str, '\S\s*'. dS .'\s*$') != ""
            " '''
            let onlyS = matchstr(str, '^\s*'. dS .'\s*$') != ""
            " ''' char
            let charE = matchstr(str, '^\s*'. dS .'\s*\S') != ""

            if ndS
                return 0
            endif

            if onlyS || charE
                return prevNo
            endif
        endif

        let prevNo -= 1
    endwhile

    return 0
endfunction
"}}}

" s:DownFindHead() {{{
"
" 向下找只有两种情况: 在首符号的行向下查找; 在首和尾符号都不存在的行向下查找。
" @param number lineNo 操作行号
" @param string needleS 首双符号
" @param string needleE 尾双符号
" @param number lastNo 当前文件的最大行号
" @return number 返回 0 表示当前行为单行注释操作，非 0 值取消多行注释的操作。
"
function s:DownFindHead(lineNo, needleS, needleE, lastNo)
    if a:lineNo == a:lastNo
        return 0
    endif

    let nextNo = a:lineNo + 1

    while nextNo
        let str = getline(nextNo)

        if a:needleS != a:needleE
            let ndS = <SID>GetHeadChar(str, b:dHeadLen)
            let ndE = <SID>GetTailChar(str, a:needleE)

            if ndS == a:needleS
                return 0
            endif

            if ndE == a:needleE
                return nextNo
            endif
        else
            let dS = escape(a:needleS, '\/')
            let ndS = matchstr(str, '^\s*'. dS . '\s*\S') != ""
            let onlyS = matchstr(str, '^\s*'. dS .'\s*$') != ""
            let charE = matchstr(str, '\S\s*'. dS .'\s*$') != ""

            if ndS
                return 0
            endif

            if onlyS || charE
                return nextNo
            endif
        endif

        let nextNo += 1

        if nextNo > a:lastNo
            return 0
        endif
    endwhile
endfunction
"}}}

" s:SameUpFilter(){{{
"
" @see <SID>SameDownFilter()
" @param number curNo
" @param string dS
" @return number
"   如果返回的行号是 a:curNo，将当前行号作为范围的开始，并隐含了向上只找到范围
"   的开始行。
"
"   如果返回的不是 a:curNo，将向上查找的第一个带有符号的行号作为范围的开始，并
"   隐含了向上已经查找到范围的开始行和结束行。
"
function s:SameUpFilter(curNo, dS)
    if a:curNo == 1
        return a:curNo
    endif

    let temp = []
    let scaler = 0

    let incre = a:curNo - 1

    while incre
        let curStr = getline(incre)

        if matchstr(curStr, '\S\s*'. a:dS .'\s*$') != ""
            break
        endif

        if matchstr(curStr, '^\s*'.a:dS .'\s*\S') != ""
            if empty(temp)
                return incre
            endif

            let scaler += 1
            break
        endif

        if matchstr(curStr, '^\s*'. a:dS) != ""
            call add(temp, incre)
            let scaler += 1
        endif

        let incre -= 1
    endwhile

    if scaler % 2 == 0
        return a:curNo
    else
        return temp[0]
    endif
endfunction
"}}}

"s:SameDownFilter(){{{
"
" 相同双符号向下查找过滤
" @param number curNo 操作行号
" @param string dS 相同双符号中的首符号，如 python 的 "'''"
" @param number lastNo 当前文件的最大行号
" @return number 返回行号
"   如果返回的行号是 a:curNo，将当前行号作为范围的结束，并隐含了向下只找到范围
"   的结束行。
"
"   如果返回的不是 a:curNo，将向下查找的第一个带有符号的行号作为范围的结束行，
"   并隐含了向下已经查找到范围的开始行和结束行。
"
function s:SameDownFilter(curNo, dS, lastNo)
    if a:curNo == a:lastNo
        return a:curNo
    endif

    "@ var number 存储 dS 符号开始的行号
    let temp = []

    "@ var nimner 以 dS 符号开始的行数量
    let scaler = 0

    let incre = a:curNo + 1

    while incre
        let curStr = getline(incre)
        " ''' line
        if matchstr(curStr, '^\s*'. a:dS. '\s*\S\+\s*') != ""
            break
        endif

        " line '''
        if matchstr(curStr, '\S\+\s*'. a:dS .'\s*$') != ""
            if empty(temp)
            " '''
            " line '''
                return incre
            endif

            let scaler += 1
            break
        endif

        if matchstr(curStr, '^\s*'. a:dS) != ""
            call add(temp, incre)
            let scaler += 1
        endif

        let incre += 1

        if incre > a:lastNo
            return a:lastNo
        endif
    endwhile

    if scaler % 2 == 0
        return a:curNo
    else
        return temp[0]
    endif
endfunction
"}}}

" s:GetHeadChar() {{{
"
" 获取行首的字符
" @param string haystack 某一行的内容字符串
" @param number lth 单符号或首双符号长度
" @return string 返回和单符号或首双符号相同长度的字符
"
function s:GetHeadChar(haystack, lth)
    return strpart(substitute(a:haystack, '^\s*', "", ""), 0, a:lth)
endfunction
"}}}

" s:GetTailChar() {{{
"
" 获取行尾的字符
" @see <SID>GetHeadChar()
" @param string haystack
" @param string dE 尾双符号
" @return string 返回和尾双符号相同长度的字符
"
function s:GetTailChar(haystack, dE)
    let dE = escape(a:dE, '\/')
    let haystack = matchstr(a:haystack, dE.'\s*$')
    return strpart(haystack, 0, b:dTailLen)
endfunction
"}}}

" s:GetSmallBlankWidth(){{{

" 获取最大或最小空白宽度
" @param number curNo  首行号
" @param number limit  末行号加 1，作为循环界限使用。
" @return list  [number width, bool flag]
"   width 如果都是空白行，返回最大的空白宽度。否则为返回最小的空白宽度。如果第
"          一列模式被启用并正确匹配到。永远返回0。
"   flag 预留设置
"
function s:GetSmallBlankWidth(curNo, limit)
    " @var list temp_1 每一个非空白行的长度
    " @var list temp_2 每一个空白行的长度
    let temp_1 = []
    let temp_2 = []

    let incre = a:curNo
    let limit = a:limit

    while incre < limit
        let curStr = getline(incre)

        let blankLine = <SID>IsBlankLine(incre)

        " 过滤多行中的空行或空白行，允许单行是空行或空白行
        if blankLine && a:curNo != a:limit - 1
            let blankLineLen = strlen(curStr)
            let temp_2 = add(temp_2, blankLineLen)
            let incre += 1
            continue
        endif

        let totalLen = strlen(curStr)
        let diff = totalLen - strlen(substitute(curStr, '^\s*', "", "" ))

        let temp_1 = add(temp_1, diff)
        let incre += 1
    endwhile

    if  len(temp_2) == incre - a:curNo
        return [max(temp_2), 0]
    else
        " 返回最小空白宽度。如果操作的是单行，仅有的一个值被返回
        return [min(temp_1), 1]
    endif
endfunction
"}}}

" s:RestoreCursor(){{{
"
" 恢复光标位置
" @param list cursor 原光标位置信息
" @return void
"
function s:RestoreCursor(curNo, endNo, cursor)
    " 当取消注释操作后光标的位置会发生变化，当光标在首符号行时光标位置不变。当
    " 光标在尾符号行时需要减去两行。当光标在首和尾之间的行时需要减去一行。

    let temp = a:cursor[1]

    if temp == a:endNo
        let a:cursor[1] -= 2
    endif

    if temp > a:curNo && temp < a:endNo
        let a:cursor[1] -=1
    endif

    call setpos('.', a:cursor)
endfunction
"}}}

" s:PadSpace(){{{
"
" 填充双符号的首行或未行
" @param number input 需要操作的行号
" @param string char 已经被转义过的首符号或尾符号
" @param number width 从这个宽度位置之后插入，如果宽度为0，则从第一列插入。
"
function s:PadSpace(input, char, width)
    let temp = ""
    let incre = 0

    while incre < a:width
        let temp .= "\x20"
        let incre = strlen(temp)
    endwhile

    execute a:input .'s/^.*$/'. temp . a:char
endfunction
"}}}

" s:IsPatternFirstMode(){{{
"
" 匹配第一列模式允许的文件类型
" @return bool
"
function s:IsPatternFirstMode()
    if s:isFirstInsert
        for item in split(g:allow_first_column_mode, ',')
            if item == &filetype
                return 1
            endif
        endfor
    endif

    return 0
endfunction
"}}}

" s:IsPatternSemiBlockMode(){{{
"
" 匹配第一列模式允许的文件类型
" @return bool
"
function s:IsPatternSemiBlockMode()
    if s:isSemiBlock
        for item in split(g:allow_semi_block_mode, ',')
            if item == &filetype
                return 1
            endif
        endfor
    endif

    return 0
endfunction
"}}}

" s:IsPatternEachLineMode(){{{
"
" 匹配第一列模式允许的文件类型
" @return bool
"
function s:IsPatternEachLineMode()
    if s:isEachLineInsert
        for item in split(g:allow_each_line_mode, ',')
            if item == &filetype
                return 1
            endif
        endfor
    endif

    return 0
endfunction
"}}}

" 检测仅有首符号的行是否以首符号或空白结尾
"
" @param number curNo 首行号
" @param string dS 首双符号
" @param bool strict 为真时，仅首符号的行并且必须以首符号结尾。为假时仅有首符
"                    号的行并且必须是以首符号或空白字符结尾
" @return bool
"
function s:IsHeadSymEnd(curNo, dS, strict)
    let dS = escape(a:dS, '\/')
    let curStr = getline(a:curNo)

    if a:strict
        return matchstr(curStr, '\V\^\s\*'. dS .'\$') != ''
    else
        return matchstr(curStr, '\V\^\s\*'. dS .'\s\*\$') != ''
    endif
endfunction

" 检测尾符号行是否以尾符号结尾
"
function s:IsTailSymEnd(endNo, dE, strict)
    let dE = escape(a:dE, '\/')
    let endStr = getline(a:endNo)

    if a:strict
        return matchstr(endStr, '\V\^\s\*'. dE .'\$') != ''
    else
        return matchstr(endStr, '\V\^\s\*'. dE .'\s\*\$') != ''
    endif
endfunction

" 是否当前行只有前辍字符
" @return bool
"
function s:IsOnlyPrefix(curNo)
    let prefix = escape(substitute(s:isLinePrefix, '\s*$', "", ""), '\/')
    return matchstr(getline(a:curNo), '\V\^\s\*'. prefix .'\s\*\$') != ''
endfunction

" s:IsStrictFormat(){{{
"
" 是否为严格的列块注释格式
" @param number curNo 首行号
" @param number endNo 末行号
" @return list [bool format, string error_code]
"   format 如果是列块的注释格式为真
"   error_code 预留错误消息内部调试
"
function s:IsStrictFormat(curNo, endNo, dS, dE)
    let headStr = getline(a:curNo)
    let tailStr = getline(a:endNo)

    " 总长度
    let headLen = strlen(headStr)
    let tailLen = strlen(tailStr)

    " 去掉开始空白字符后的长度
    let beforeHeadLen = strlen(substitute(headStr, '^\s*', "", ""))
    let beforeTailLen = strlen(substitute(tailStr, '^\s*', "", ""))

    " 空白长度
    let headBlankLen = headLen - beforeHeadLen
    let tailBlankLen = tailLen - beforeTailLen

    if headBlankLen
        let baseWidth = headBlankLen
        let tailWidth = baseWidth + 1
        let otherWidth = baseWidth + 1
    else
        let baseWidth = 0
        let tailWidth = 1
        let otherWidth = 1
    endif

    " 只检查尾符号行的空白宽度即可，因为是通过首符号行计算的。
    if tailBlankLen != tailWidth | return [0, 'DE1'] | endif

    " 检查首和尾符号行是否以首和尾符号结尾
    let ihse = <SID>IsHeadSymEnd(a:curNo, a:dS, 1)
    let itse = <SID>IsTailSymEnd(a:endNo, a:dE, 1)

    if !ihse | return [0, 'DE2'] | endif
    if !itse | return [0, 'DE2'] | endif

    let incre = a:curNo + 1

    " 检查内行
    while incre < a:endNo
        let inLineStr = getline(incre)
        let inLineLen = strlen(inLineStr)

        let beforeInLineStr = substitute(inLineStr, '^\s*', "", "")
        let beforeInLineLen = strlen(beforeInLineStr)
        let inLineBlankLen = inLineLen - beforeInLineLen

        if s:isLinePrefix != ''
            let prefix = strpart(beforeInLineStr, 0, b:prefixLen)
            let iop = <SID>IsOnlyPrefix(incre)

            " 不检查只有前辍的行
            if iop
                let incre += 1
                continue
            endif

            " 内行前辍字串是否相同
            if prefix != s:isLinePrefix
                return [0, 'DE3']
            endif
        else
            let incre += 1
            continue
        endif

        " 检查内行最小空白宽度
        if inLineBlankLen != otherWidth
            return [0, 'DE4']
        endif

        let incre += 1
    endwhile

    return [1, "TODO"]

    " @var list TODO
    " let inLinePrefixCell = []
endfunction
"}}}

" 是否为空白行
" @return bool 如果是空行或空白行为真
"
function s:IsBlankLine(curNo)
    let char = matchstr(getline(a:curNo), '\S')

    if char != ""
        return 0
    else
        return 1
    endif
endfunction


" TODO 变量 g:add_comment_symbol 纠错
"
" function s:IsValueCorrect()
" endfunction

" 错误输出
"
function s:ErrorHandle(level, index)
    echohl ErrorMsg | echo s:ERROR_CODE[a:level][a:index] | echohl None
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:ft=vim:ff=unix:ts=4:et:fdm=marker:
