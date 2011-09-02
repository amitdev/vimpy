#import ast
import StringIO
import tokenize
import token

def get_token(line, pos):
        for tup in tokenize.generate_tokens(StringIO.StringIO(line).readline):
                if tup[0] == token.NAME and pos >= tup[2][1] and pos < tup[3][1]:
                    return tup[1].strip()
        return ''
