if !has('python')
	echo "Error: vimpy requires Vim compiled with python."
	finish
endif

let s:bufdetails = { 'module' : ['~Module', 'Enter Module Name: ', 'CloseModule'], 
                        \ 'class'  : ['~Class', 'Enter Class Name: ', 'CloseClass'], 
                        \ 'function'  : ['~Function', 'Enter Function: ', 'CloseFun'] }

python << endpython
import storage
import vim
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
	  if a:findstart
	    let line = getline('.')
	    let start = col('.') - 1
	    while start > 0 && line[start - 1] =~ '\a'
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
    exe 'inoremap <silent> <cr> <cr><c-\><c-n>:call ' . bp[2] .'()<cr>'
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

function! CloseModule()
python << endpython
if ':' in vim.current.buffer[0]:
    k = vim.current.buffer[0].split(':')[1].strip()
    if k in st.modules.d:
        pth = st.modules.d[k]
        vim.command("bdelete!")	
        vim.command("e %s" % pth)
endpython
	iunmap <cr>
	iunmap <tab>
endfunction

function! CloseClass()
python << endpython
if ':' in vim.current.buffer[0]:
    k = vim.current.buffer[0].split(':')[1].strip()
    if k in st.classes.d:
        vim.command('iunmap <cr>')
        vim.command('iunmap <tab>')
        (_, pth, line) = st.classes.d[k]
        vim.command("bdelete!")	
        vim.command("e %s" % pth)
        #TODO: Check if moving to class name col is better
        vim.current.window.cursor = (line, 0)
endpython
endfunction

function! CloseFun()
python << endpython
if ':' in vim.current.buffer[0]:
    k = vim.current.buffer[0].split(':')[1].strip()
    if k in st.functs.d:
        (_, pth, line) = st.functs.d[k]
        vim.command("bdelete!")	
        vim.command("e %s" % pth)
        #TODO: Check if moving to class name col is better
        vim.current.window.cursor = (line, 0)
endpython
	iunmap <cr>
	iunmap <tab>
endfunction
