import os
from collections import defaultdict
#from __future__ import with_statement

try:
    import cPickle as pickle
except:
    import pickle

class DictWrapper(object):

    def __init__(self, d):
        self.d = d
        self.counter = {}

    def add(self, key, val):
        if key in self.d:
            if key not in self.counter:
                self.counter[key] = 1
                self.d["%s (1)" % key] = self.d[key]
                del self.d[key]
            self.counter[key] += 1
            key = "%s (%d)" % (key, self.counter[key])
        self.d[key] = val

class storage(object):
    
    def __init__(self, filename):
        self.modules = DictWrapper({})
        self.classes = DictWrapper({})
        self.modifiedtime = {}
        self.filename = filename        
        if os.path.exists(self.filename):
            self._init()
        self.changed = False
    
    def ismodified(self, path):
        mt = os.path.getmtime(path)
        return path not in self.modifiedtime or mt - self.modifiedtime[path] > 1e-6
    
    def modified(self, path):
        self.modifiedtime[path] = os.path.getmtime(path)
        self.changed = True        
    
    def addclass(self, name, module, path, line):
        self.classes.add(name, (module, path, line))
        
    def addmodule(self, name, path):
        self.modules.add(name, path)

    def _init(self):
        with open(self.filename) as f:
            try:
                self.modules = DictWrapper(pickle.load(f))
                self.classes = DictWrapper(pickle.load(f))
                self.modifiedtime = pickle.load(f)
            except EOFError:
                print 'Error while reading %s' % self.filename                
    
    def close(self):
        with open(self.filename, 'w') as f:
            pickle.dump(self.modules.d, f)
            pickle.dump(self.classes, f)
            pickle.dump(self.modifiedtime, f)  
