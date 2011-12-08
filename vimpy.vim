" Vim Plugin to make navigation across python files easy.
"
" Author: Amit Dev
" Version: 0.1
" License: This file is placed in the public domain.
"

if exists("g:loaded_vimpy")
    finish
endif
let g:loaded_vimpy = 1

if !has('python')
	echo "Error: vimpy requires Vim compiled with python."
	finish
endif

" Key Bindings
nnoremap <leader>om :call <SID>OpenModule()<CR>
nnoremap <leader>oc :call <SID>OpenClass()<CR>
nnoremap <leader>of :call <SID>OpenFun()<CR>
nnoremap <leader>gm :call <SID>GotoModule()<CR>
nnoremap <leader>gc :call <SID>GotoClass()<CR>
nnoremap <leader>gf :call <SID>GotoFun()<CR>

" Open new files in a split or buffer?
let s:EditCmd = "e"

" -- Implementation starts here - modify with care --
let s:bufdetails = { 'module' : ['~Module', 'Enter Module Name: ', '<SID>CloseModule'], 
                        \ 'class'  : ['~Class', 'Enter Class Name: ', '<SID>CloseClass'], 
                        \ 'function'  : ['~Function', 'Enter Function: ', '<SID>CloseFun'] }

au VimLeavePre * call s:WriteIndex()
au BufWritePost *.py,*.pyx call s:UpdateIndex()

python << endpython
import vim
import os
import sys

scriptdir = os.path.dirname(vim.eval('expand("<sfile>")'))
if not scriptdir.endswith('vimpy'):
    scriptdir = os.path.join(scriptdir, 'vimpy')
sys.path.insert(0, scriptdir)
import storage
import vimpy
import tok

def _set_storage(path):
    if os.path.exists(path):
        st.init(path)
        print 'Loaded %d modules which has %d classes and %d functions.' % st.counts()
    else:
        print 'Invalid Project File'

st = storage.storage('')
endpython

if !exists(":VimpyLoad")
    command -nargs=1 -complete=file VimpyLoad :python _set_storage(<q-args>)
endif

if !exists(":VimpyCreate")
    command -nargs=+ -complete=file VimpyCreate :python vimpy.start(<f-args>)
endif

fun! s:UpdateIndex()
python << endpython
if vim.current.buffer.name in st.paths:
    vimpy.st = st
    vimpy.parsefile(vim.current.buffer.name)
endpython
endfun

fun! s:WriteIndex()
python << endpython
st.close()
endpython
endfun

fun! s:GetModule(pfx)
python << endpython
pfx = vim.eval("a:pfx")
#print 'Matching %s in %d modules' % (pfx, len(st.modules.skeys))
matches = [i for i in st.modules.skeys if i.startswith(pfx)]
completions = [{'word' : i, 'menu' : st.modules.d[i]} for i in matches]
vim.command("let l:res = %r" % completions)
endpython
    return l:res
endfun

fun! s:GetClass(pfx)
python << endpython
pfx = vim.eval("a:pfx")
matches = [i for i in st.classes.skeys if i.startswith(pfx)]
completions = [{'word' : i, 'menu' : st.classes.d[i][0]} for i in matches]
vim.command("let l:res = %r" % completions)
endpython
    return l:res
endfun

fun! s:GetFun(pfx)
python << endpython
pfx = vim.eval("a:pfx")
matches = [i for i in st.functs.skeys if i.startswith(pfx)]
completions = [{'word' : i, 'menu' : st.functs.d[i][0]} for i in matches]
vim.command("let l:res = %r" % completions)
endpython
    return l:res
endfun

fun! s:Completer(findstart, base, fn)
      echo a:findstart
	  if a:findstart
	    let line = getline('.')
	    let start = col('.') - 1
	    while start > 0 && line[start - 1] =~ '[^ :]'
	      let start -= 1
	    endwhile
	    return start
	  else
	    return call (a:fn, [a:base])
	  endif
endfun

fun! VimpyCompleteModules(findstart, base)
     return s:Completer(a:findstart, a:base, function('s:GetModule'))
endfun

fun! VimpyCompleteClasses(findstart, base)
     return s:Completer(a:findstart, a:base, function('s:GetClass'))
endfun

fun! VimpyCompleteFuns(findstart, base)
     return s:Completer(a:findstart, a:base, function('s:GetFun'))
endfun

fun! s:OpenBuf(type)
    let bp = s:bufdetails[a:type]
    exe "split " . bp[0]
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    exe "normal i" . bp[1]
    call feedkeys("C")
    setlocal completeopt=longest,menu
    exe 'inoremap <buffer> <silent> <cr> <cr><c-\><c-n>:call <SID>CloseBuf(function("' . bp[2] .'"))<cr>'
    inoremap <buffer> <silent> <tab> <c-x><c-u>
endfun

function! s:OpenClass()
    call s:OpenBuf('class') 
    setlocal completefunc=VimpyCompleteClasses
endfunction

function! s:OpenFun()
    call s:OpenBuf('function') 
    setlocal completefunc=VimpyCompleteFuns
endfunction

function! s:OpenModule()
    call s:OpenBuf('module') 
    setlocal completefunc=VimpyCompleteModules
endfunction

function! s:CloseBuf(fn)
    let s = getline(1)
    let ind = stridx(s, ':')
    if ind != -1
        let name = strpart(s, ind+1)
        let pos = a:fn(name)
        if pos != ''
            exe "bdelete"
            let ind = strridx(pos, ':')
            let path = strpart(pos, 0, ind)
            let line = strpart(pos, ind+1)
            exe s:EditCmd . " " . path
            call cursor(line, 0)
        endif
    else
        exe "bdelete"
    endif
endfunction

function! s:CloseModule(name)
let l:res = ''
python << endpython
k = vim.eval("a:name").strip()
if k in st.modules.d:
    pth = st.modules.d[k]
    vim.command("let l:res = '%s:1'" % pth)
endpython
return l:res
endfunction

function! s:CloseClass(name)
let l:res = ''
python << endpython
k = vim.eval("a:name").strip()
if k in st.classes.d:
    (_, pth, line) = st.classes.d[k]
    #TODO: Check if moving to class name col is better
    vim.command("let l:res = '%s:%d'" % (pth, line))
endpython
return l:res
endfunction

function! s:CloseFun(name)
let l:res = ''
python << endpython
k = vim.eval("a:name").strip()
if k in st.functs.d:
    (_, pth, line) = st.functs.d[k]
    #TODO: Check if moving to class name col is better
    vim.command("let l:res = '%s:%d'" % (pth, line))
endpython
return l:res
endfunction

python << endpython
def open_file(match, path, get):
    vim.command("unlet! l:res")
    line = vim.current.line
    pos  = vim.current.window.cursor[1]
    word = tok.get_token(line, pos)
    if word:
        word = get(word)
        lw = len(word)
        matches = [i for i in match.skeys if i.startswith(word)]
        matches = [i for i in matches if len(i) == lw or i[lw] == ' ']
        if len(matches) == 1:
            _, pth, line = path(word)
            vim.command("e %s" % pth)
            if line:
                vim.current.window.cursor = (line, 0)
        elif len(matches) > 1:
            vim.command("let l:res = '%s'" % word)
        else:
            print 'No match!'
    else:
        print 'No match!'
endpython

function! s:GotoModule()
python << endpython
open_file(st.modules,
          lambda p: (None, st.modules.d[p], None),
          lambda w: "%s%s" % (w, '.py'))
endpython
if exists("l:res")
    call s:OpenModule()
    call feedkeys(l:res)
    call feedkeys("\t")
endif
endfunction

function! s:GotoClass()
python << endpython
open_file(st.classes,
          lambda p: st.classes.d[p],
          lambda w: w)
endpython
if exists("l:res")
    call s:OpenClass()
    call feedkeys(l:res)
    call feedkeys("\t")
endif
endfunction

function! s:GotoFun()
python << endpython
open_file(st.functs,
          lambda p: st.functs.d[p],
          lambda w: w)
endpython
if exists("l:res")
    call s:OpenFun()
    call feedkeys(l:res)
    call feedkeys("\t")
endif
endfunction
