import sys
import ast
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
        #print 'Adding class %s in %s' % (self.klass, self.module)
        st.addclass(node.name, self.module, self.path, node.lineno)
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


def walk(folder):
    for root, dirs, files in os.walk(folder, topdown=False):
        for name in files:
            if name.endswith('.py'):
                parse(name, os.path.join(root, name))

def start(roots, exclude=[]):
    print 'Start Indexing'
    sys.stdout.write ("Processing ")
    processed = set(exclude)
    for p in roots:
        if os.path.isdir(p) and p not in processed:
            processed.add(p)
            walk(p)
    st.close()
    print '\nDone'
    if errors:
        sys.stderr.write('%d modules could not be indexed because of syntax errors: \n' % len(errors))
        for error in errors:
            sys.stderr.write(error)

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print 'Usage: python %s <result> <source folder> [<exclude folder>]' % sys.argv[0]
    st = storage.storage(sys.argv[1])
    exclude = []
    if len(sys.argv) == 4:
        exclude = [sys.argv[3]]
    start([sys.argv[2]], exclude)
