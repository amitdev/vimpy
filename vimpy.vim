if !has('python')
	echo "Error: vimpy requires Vim compiled with python."
	finish
endif

python << endpython
import storage
import vim
st = storage.storage('pyth')
endpython

fun! GetMatch(pfx)
python << endpython
pfx = vim.eval("a:pfx")
matches = [i for i in st.modules.d if i.startswith(pfx)]
completions = [{'word' : i, 'menu' : st.modules.d[i]} for i in matches]
vim.command("let l:res = %r" % completions)
endpython
return l:res
endfun

fun! GetClass(pfx)
python << endpython
pfx = vim.eval("a:pfx")
matches = [i for i in st.classes.d if i.startswith(pfx)]
completions = [{'word' : i, 'menu' : st.classes.d[i][0]} for i in matches]
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

function! OpenClass()
exe "split ~"
exe "normal iEnter Class Name: "
call feedkeys("i")
setlocal completefunc=CompleteClasses
exe 'inoremap <silent> <cr> <cr><c-\><c-n>:call CloseClass()<cr>'
exe 'inoremap <silent> <tab> <c-x><c-u>'
endfunction

function! OpenModule()
exe "split ~"
exe "normal iEnter Class Name: "
call feedkeys("i")
setlocal completefunc=CompleteModules
exe 'inoremap <silent> <cr> <cr><c-\><c-n>:call CloseModule()<cr>'
exe 'inoremap <silent> <tab> <c-x><c-u>'
endfunction

function! CloseModule()
    let l:pth = ''
python << endpython
if ':' in vim.current.buffer[0]:
    k = vim.current.buffer[0].split(':')[1].strip()
    if k in st.modules.d:
        vim.command("let l:pth = '%s'" % st.modules.d[k])
endpython
    echomsg 'Got ' . l:pth
	execute ":bdelete!"	
	execute ":e " . l:pth
	iunmap <cr>
	iunmap <tab>
endfunction

function! CloseClass()
    let l:pth = ''
python << endpython
if ':' in vim.current.buffer[0]:
    k = vim.current.buffer[0].split(':')[1].strip()
    if k in st.classes.d:
        vim.command("let l:pth = '%s'" % st.modules.d[k][1])
endpython
    echomsg 'Got ' . l:pth
	execute ":bdelete!"	
	execute ":e " . l:pth
	iunmap <cr>
	iunmap <tab>
endfunction
