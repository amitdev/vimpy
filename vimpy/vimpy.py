import sys
import _ast
import os
import storage
import compiler
from compiler import visitor as ast

try:
    import vim
except:
    pass

st = None
count = 0
modcount = 0
errors = []
DEBUG = False
from_vim = True

class visitor(ast.ASTVisitor):

    def __init__(self, val, pth):
        self.module = val
        self.path = pth
        self.klass = None
        #print '\nAdding Module %s in %s----------' % (self.module, self.path)
        st.addmodule(self.module, self.path)
        #print 'Done Module %s in %s----------\n' % (self.module, self.path)

    def visitClass(self, node):
        self.klass = node.name
        #print 'Adding class %r in %s' % (node.name, self.module)
        st.addclass(node.name, self.module, self.path, node.lineno)
        #self.addSub(node)
        compiler.walk(node.code, self)
        self.klass = None

    def addsub(self, node):
        for base in node.bases:
            if isinstance(base, _ast.Name):
                st.addsub(node.name, base.id)
            elif isinstance(base, _ast.Attribute):
                st.addsub(node.name, base.attr)
            else:
                # The superclass is an expresion. Atleast log it later.
                pass

    def visitFunction(self, node):
        module = self.module
        if self.klass is not None:
            module = '%s :: %s' % (self.module, self.klass)
        #print 'Adding fun %r in %s' % (node.name, module)
        st.addfunction(node.name, module, self.path, node.lineno)

def parsepyx(lines, filename, pth):
    """ Heuristic based simple pyrex/cython file parser. """
    for n, line in enumerate(lines):
        l = line.strip()
        try:
            if (l.startswith('class') or l.startswith('cdef class')) and l[-1] == ':':
                end = l.find('(')
                st.addclass(l[l.rfind(' ',0, end)+1:end], filename, pth, n+1)
            elif l.startswith('def') or l.startswith('cdef'):
                    fn = l.split('(')
                    if fn[-1][-1] == ':':
                        st.addfunction(fn[0].split(' ')[-1], filename, pth, n+1)
        except Exception:
            pass

def parsefile(pth, ispython=True, errs=None, filename=None):
    if filename is None:
        filename = os.path.basename(pth)
        ispython = filename.endswith('.py')
        if not ispython and not filename.endswith('.pyx'):
            return
    if st.ismodified(pth):
        is_update = pth in st.paths
        if ispython:
            try:
                compiler.walk(compiler.parseFile(pth), visitor(filename, pth))
            except Exception, err:
                if errs is not None:
                    errs.append('Cannot Parse %s because of %r \n' % (pth, err))
        else:
            st.addmodule(filename, pth)
            f = open(pth)
            parsepyx(f.readlines(), filename, pth)
        st.modified(pth)
        if is_update:
            st._init()
        return 1
    return 0

def parse(filename, pth):
    ispython = filename.endswith('.py')
    if not ispython and not filename.endswith('.pyx'):
        return
    global count, modcount
    count += 1
    if not from_vim:
        if count != 1:
            sys.stdout.write('\b\b\b\b\b\b')
        sys.stdout.write("%06d" % count)
    else:
        vim.command('redraw | echo "Indexing %06d"' % count)
    modcount += parsefile(pth)

def excluded(folder, exclude):
    fs = folder.split(os.path.sep)
    for exs in exclude:
        if len(exs) <= len(fs) and all((fs[i]==exs[i] for i in xrange(len(exs)))):
            return True
    return False

def walk(folder, exclude):
    processed = set()
    for root, dirs, files in os.walk(folder, topdown=False):
        if root in processed or excluded(root, exclude):
            continue
        processed.add(root)
        for name in files:
            parse(name, os.path.join(root, name))

def start(prj, roots, exclude=""):
    global st, from_vim
    st = storage.storage(prj)
    roots = roots.split(',')
    if exclude:
        exclude = exclude.split(',')
    else:
        exclude = []
    roots = [os.path.realpath(p.strip()) for p in roots]
    exclude = [os.path.realpath(p.strip()).split(os.path.sep) for p in exclude]
    if not from_vim:
        sys.stdout.write ("Indexing ")
    else:
        vim.command('redraw | echo "Indexing "')
    for p in roots:
        walk(p, exclude)
    st.close()
    print ' Done. Processed %d Modules, %d modules changed.' % (count, modcount)
    if errors:
        sys.stderr.write('%d modules could not be indexed because of syntax errors. Use --debug option to see details.\n' % len(errors))
        if DEBUG:
            for error in errors:
                sys.stderr.write(error)

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print 'Usage: python %s <proj-file> <source folders> [<exclude folders>] [--debug]' % sys.argv[0]
        print '       <proj-file> is the result which can be used in vimpy'
        print '       <source folders> and <exclude folders> can be comma separated list of folders as well [Optional]'
        print '       --debug will show errors if any during indexing. [Optional]'
        exit(1)

    from_vim = False
    if len(sys.argv) >= 4:
        if not sys.argv[3] == '--debug':
            exclude = sys.argv[3]

    DEBUG = sys.argv[-1] == '--debug'
    start(sys.argv[1], sys.argv[2], exclude)
