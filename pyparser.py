import sys
import ast
import _ast
import os
import storage

st = None
count = 0
errors = []

class visitor(ast.NodeVisitor):

    def startModule(self, node, val, pth):
        self.module = val
        self.path = pth
        self.klass = None
        #print '\nAdding Module %s in %s----------' % (self.module, self.path)
        st.addmodule(self.module, self.path)
        ast.NodeVisitor.generic_visit(self, node)
        #print 'Done Module %s in %s----------\n' % (self.module, self.path)

    def visit_ClassDef(self, node):
        self.klass = node.name
        #print 'Adding class %r in %s' % (node, self.module)        
        st.addclass(node.name, self.module, self.path, node.lineno)
        for base in node.bases:
            if isinstance(base, _ast.Name):
                st.addsub(node.name, base.id)
            elif isinstance(base, _ast.Attribute):
                st.addsub(node.name, base.attr)
            else:
                # The superclass is an expresion. Atleast log it later.
                pass
        ast.NodeVisitor.generic_visit(self, node)
        self.klass = None

    def visit_FunctionDef(self, node):
        module = self.module
        if self.klass is not None:
            module = '%s :: %s' % (self.module, self.klass)
        st.addfunction(node.name, module, self.path, node.lineno)

def parse(filename, pth):
    global count
    if st.ismodified(pth):
        count += 1
        if count != 1:
            sys.stdout.write('\b\b\b\b\b\b') 
        sys.stdout.write("%06d" % count) 
        f = file(pth)
        try:
            visitor().startModule(ast.parse(f.read(), filename), filename, pth)
        except SyntaxError as err:
            errors.append('Cannot Parse %s because of %r \n' % (pth, err))
        st.modified(pth)


def walk(folder, processed):
    for root, dirs, files in os.walk(folder, topdown=False):
        if root in processed:
            continue
        processed.add(root)
        for name in files:
            if name.endswith('.py'):
                parse(name, os.path.join(root, name))

def start(roots, exclude=[]):    
    roots = [p.strip() for p in roots]
    exclude = [p.strip() for p in exclude]
    sys.stdout.write ("Indexing ")
    processed = set(exclude)
    for p in roots:
        walk(p, processed)
    st.close()
    print ' Done.\nTotal %d modules which has %d classes and %d functions.' % st.counts()
    if errors:
        sys.stderr.write('%d modules could not be indexed because of syntax errors: \n' % len(errors))
        for error in errors:
            sys.stderr.write(error)

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print 'Usage: python %s <proj-file> <source folders> [<exclude folders>]' % sys.argv[0]
        print '       <proj-file> is the result which can be used in vimpy'
        print '       <source folders> and <exclude folders> can be comma separated list of folders as well'
        exit(1)
    st = storage.storage(sys.argv[1])
    exclude = []
    if len(sys.argv) == 4:
        exclude = sys.argv[3].split(',')        
    start(sys.argv[2].split(','), exclude)
