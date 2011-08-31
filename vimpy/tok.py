import ast
import StringIO
import tokenize
import token

class ImportVisitor(ast.NodeVisitor):
        def __init__(self, line, pos):
                self.result = ''
                self.line = line
                self.pos = pos
                try:
                    self.generic_visit(ast.parse(line))
                except:
                    pass

        def visit_Import(self, node):
                self.get_result(['import', 'as', '*', ',', ';'], '')

        def visit_ImportFrom(self, node):
                self.get_result(['import', 'from', 'as', '*', ',', ';'], 'import')

        def get_result(self, ignore, terminate):
                for tup in tokenize.generate_tokens(StringIO.StringIO(self.line).readline):
                        if tup[1] == terminate:
                                return
                        if (self.pos >= tup[2][1] and
                            self.pos < tup[3][1] and
                            tup[1] not in ignore):
                                self.result = tup[1].strip()

def get_token(line, pos):
        for tup in tokenize.generate_tokens(StringIO.StringIO(line).readline):
                if tup[0] == token.NAME and pos >= tup[2][1] and pos < tup[3][1]:
                    return tup[1].strip()
        return ''
