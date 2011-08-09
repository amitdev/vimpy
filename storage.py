import os
import bisect
from collections import defaultdict
#from __future__ import with_statement

try:
    import cPickle as pickle
except:
    import pickle

class storage(object):
    
    def __init__(self, filename):
        self.modules = []
        self.classes = defaultdict(list)
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
        self.classes[name].append((module, path, line))
        
    def addmodule(self, name, path):
        bisect.insort_left(self.modules, name + ' in ' + path)
        
    def _init(self):
        with open(self.filename) as f:
            try:
                self.modules = pickle.load(f)
                self.classes = pickle.load(f)
                self.modifiedtime = pickle.load(f)
            except EOFError:
                print 'Error while reading %s' % self.filename                
    
    def close(self):
        with open(self.filename, 'w') as f:
            pickle.dump(self.modules, f)
            pickle.dump(self.classes, f)
            pickle.dump(self.modifiedtime, f)  
