if !has('python')
	echo "Error: vimpy requires Vim compiled with python."
	finish
endif

" Key Bindings
nnoremap <leader>om :call OpenModule()
nnoremap <leader>oc :call OpenClass()
nnoremap <leader>of :call OpenFun()
nnoremap <leader>gm :call GotoModule()
nnoremap <leader>gc :call GotoClass()
nnoremap <leader>gf :call GotoFun()

let s:bufdetails = { 'module' : ['~Module', 'Enter Module Name: ', 'CloseModule'], 
                        \ 'class'  : ['~Class', 'Enter Class Name: ', 'CloseClass'], 
                        \ 'function'  : ['~Function', 'Enter Function: ', 'CloseFun'] }

python << endpython
import storage
import vim
import tok
st = storage.storage('pyth')
endpython

fun! GetMatch(pfx)
python << endpython
pfx = vim.eval("a:pfx")
matches = [i for i in st.modules.skeys if i.startswith(pfx)]
completions = [{'word' : i, 'menu' : st.modules.d[i]} for i in matches]
vim.command("let l:res = %r" % completions)
endpython
    return l:res
endfun

fun! GetClass(pfx)
python << endpython
pfx = vim.eval("a:pfx")
matches = [i for i in st.classes.skeys if i.startswith(pfx)]
completions = [{'word' : i, 'menu' : st.classes.d[i][0]} for i in matches]
vim.command("let l:res = %r" % completions)
endpython
    return l:res
endfun

fun! GetFun(pfx)
python << endpython
pfx = vim.eval("a:pfx")
matches = [i for i in st.functs.skeys if i.startswith(pfx)]
completions = [{'word' : i, 'menu' : st.functs.d[i][0]} for i in matches]
vim.command("let l:res = %r" % completions)
endpython
    return l:res
endfun

fun! Completer(findstart, base, fn)
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

fun! CompleteModules(findstart, base)
     return Completer(a:findstart, a:base, function('GetMatch'))
endfun

fun! CompleteClasses(findstart, base)
     return Completer(a:findstart, a:base, function('GetClass'))
endfun

fun! CompleteFuns(findstart, base)
     return Completer(a:findstart, a:base, function('GetFun'))
endfun

fun! OpenBuf(type)
    let bp = s:bufdetails[a:type]
    exe "split " . bp[0]
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    exe "normal i" . bp[1]
    call feedkeys("i")
    setlocal completeopt=longest,menu
    exe 'inoremap <silent> <cr> <cr><c-\><c-n>:call CloseBuf(function("' . bp[2] .'"))<cr>'
    inoremap <silent> <tab> <c-x><c-u>
endfun

function! OpenClass()
    call OpenBuf('class') 
    setlocal completefunc=CompleteClasses
endfunction

function! OpenFun()
    call OpenBuf('function') 
    setlocal completefunc=CompleteFuns
endfunction

function! OpenModule()
    call OpenBuf('module') 
    setlocal completefunc=CompleteModules
endfunction

function! CloseBuf(fn)
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
            exe "e " . path
            call cursor(line, 0)
        endif
    endif
    iunmap <cr>
    iunmap <tab>
endfunction

function! CloseModule(name)
let l:res = ''
python << endpython
k = vim.eval("a:name").strip()
if k in st.modules.d:
    pth = st.modules.d[k]
    vim.command("let l:res = '%s:1'" % pth)
endpython
return l:res
endfunction

function! CloseClass(name)
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

function! CloseFun(name)
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
        matches = [i for i in match.skeys if i.startswith(word)]
        if len(matches) == 1:
            _, pth, line = path(word)
            vim.command("e %s" % pth)
            if line:
                vim.current.window.cursor = (line, 0)
        elif len(matches) > 1:
            vim.command("let l:res = '%s'" % word)
    else:
        print 'No match!'
endpython

function! GotoModule()
python << endpython
open_file(st.modules,
          lambda p: (None, st.modules.d[p], None),
          lambda w: "%s%s" % (w, '.py'))
endpython
if exists("l:res")
    call OpenModule()
    call feedkeys(l:res)
    call feedkeys("\t")
endif
endfunction

function! GotoClass()
python << endpython
open_file(st.classes,
          lambda p: st.classes.d[p],
          lambda w: w)
endpython
if exists("l:res")
    call OpenClass()
    call feedkeys(l:res)
    call feedkeys("\t")
endif
endfunction

function! GotoFun()
python << endpython
open_file(st.functs,
          lambda p: st.functs.d[p],
          lambda w: w)
endpython
if exists("l:res")
    call OpenFun()
    call feedkeys(l:res)
    call feedkeys("\t")
endif
endfunction
