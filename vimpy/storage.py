from __future__ import with_statement
import os
import zipfile
import cStringIO
from operator import itemgetter

try:
    import cPickle as pickle
except:
    import pickle

class DictWrapper(object):

    def __init__(self):
        self.counter = {}
        self.d = {}
        self.skeys = {}

    def add(self, key, val):
        if key in self.d and key not in self.counter:
            self.counter[key] = 1
            self.d["%s (1)" % key] = self.d[key]
            del self.d[key]
        if key in self.counter:
            self.counter[key] += 1
            key = "%s (%d)" % (key, self.counter[key])
        self.d[key] = val

    def sort(self):
        self.skeys = sorted(self.d.keys())

class Entry(object):

    def __init__(self, name=None):
        self.time = 0
        self.module = name
        self.cls = []
        self.funs = []

class storage(object):

    def __init__(self, filename):
        self.reset()
        self.paths = {}
        self.init(filename)
        self.changed = False

    def ismodified(self, path):
        mt = os.path.getmtime(path)
        return path not in self.paths or mt - self.paths[path].time > 1e-6

    def modified(self, path):
        if path in self.paths:
            self.paths[path].time = os.path.getmtime(path)
            self.changed = True

    def addfunction(self, name, module, path, line):
        self.paths[path].funs.append((name, line))

    def addclass(self, name, module, path, line):
        self.paths[path].cls.append((name, line))

    def addmodule(self, name, path):
        self.paths[path] = Entry(name)

    def addsub(self, subclass, superclass):
        self.sub[superclass].add(subclass)

    def resort(self):
        self.modules.sort()
        self.classes.sort()
        self.functs.sort()

    def reset(self):
        self.modules = DictWrapper()
        self.classes = DictWrapper()
        self.functs  = DictWrapper()

    def _init(self):
        self.reset()
        #self.revmap = {}
        for path, entry in self.paths.iteritems():
           #self.revmap[path] = Entry(self.modules.add(entry.module, path))
           self.modules.add(entry.module, path)
           for c,l in entry.cls:
               #self.revmap[path].cls.add(self.classes.add(c, (entry.module, path, l)))
               self.classes.add(c, (entry.module, path, l))
           for f,l in entry.funs:
               #self.revmap[path].funs.add(self.functs.add(f, (entry.module, path, l)))
               self.functs.add(f, (entry.module, path, l))
        self.resort()

    def init(self, filename):
        self.filename = filename
        if not os.path.exists(self.filename):
            return
        try:
            tmpfile = os.path.basename(self.filename)+".tmp"
            zf = zipfile.ZipFile(self.filename, mode="r")
            f = cStringIO.StringIO(zf.read(tmpfile))
            self.paths = pickle.load(f)
            self._init()
        except Exception,e:
            print 'Error while reading %r' % e
            self.reset()
        finally:
            try:
                zf.close()
            except Exception:
                pass

    def close(self):
        if not self.paths or not self.filename:
            return
        tmpfile = os.path.basename(self.filename)+".tmp"
        try:
            zf = zipfile.ZipFile(self.filename, mode="w", compression=zipfile.ZIP_DEFLATED)
            f = cStringIO.StringIO()
            pickle.dump(self.paths, f)
            zf.writestr(tmpfile, f.getvalue())
        finally:
            zf.close()

    def counts(self):
        return len(self.modules.d), len(self.classes.d), len(self.functs.d)
