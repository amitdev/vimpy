if !has('python')
	echo "Error: vimpy requires Vim compiled with python."
	finish
endif

python << endpython
import storage
st = storage.storage('pyth')
endpython

fun! GetMatch(a)
python << endpython
import vim
a = vim.eval("a:a")
c = [i for i in st.modules.d if i.startswith(a)]
d = [{'word' : i, 'menu' : st.modules.d[i]} for i in c]
#d = [i for i in st.modules if i.startswith(a)]
vim.command("let l:res = %r" % d)
endpython
return l:res
endfun

fun! CompleteModules(findstart, base)
	  if a:findstart
	    let line = getline('.')
	    let start = col('.') - 1
	    while start > 0 && line[start - 1] =~ '\a'
	      let start -= 1
	    endwhile
	    return start
	  else
	    return GetMatch(a:base)
	  endif
endfun

function! OpenClass()
exe "split ~"
exe "normal iEnter Class Name: "
call feedkeys("i")
setlocal completefunc=CompleteModules
exe 'inoremap <silent> <cr> <cr><c-\><c-n>:call CloseModule()<cr>'
exe 'inoremap <silent> <tab> <c-x><c-u>'
endfunction

function! OpenModule()

python << endpython
import vim
vim.command("split ~")
vim.command("normal iEnter Module Name: ")
#if st.modules:
    #it = st.modules.iteritems()
    #k, v = it.next()
    #it = None
    #vim.command("let l:slen = '%s (%s)'" % (k, v[0]))
    #l = len('%s in %s' % (k, v[0]))
    #l = len(st.modules[0])
vim.eval('feedkeys("i")')
#vim.eval('feedkeys("")')
#if st.modules:
#    for i in xrange(l):
#        vim.eval('feedkeys("")')
endpython
setlocal completefunc=CompleteModules
"exe 'inoremap <silent> <cr> <cr><c-\><c-n>:call CloseModule()<cr>'
"exe 'inoremap <silent> <tab> <c-x><c-u>'
endfunction

function! CloseModule()
	let s = getline(1)
	let pth = strpart(s, stridx(s, ' in ')+4)
	execute ":bdelete!"	
	execute ":e " . pth
	iunmap <cr>
	iunmap <tab>
endfunction
