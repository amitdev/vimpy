from __future__ import with_statement
import os
import zipfile
import cStringIO

try:
    import cPickle as pickle
except:
    import pickle

class DictWrapper(object):

    def __init__(self, d):
        self.d = d
        self.counter = {}
        self.skeys = sorted(d.keys())

    def add(self, key, val):
        if key in self.d:
            if key not in self.counter:
                self.counter[key] = 1
                self.d["%s (1)" % key] = self.d[key]
                del self.d[key]
            self.counter[key] += 1
            key = "%s (%d)" % (key, self.counter[key])
        self.d[key] = val
        return key

class storage(object):

    def __init__(self, filename):
        self.reset()
        self.init(filename)
        self.changed = False

    def ismodified(self, path):
        mt = os.path.getmtime(path)
        return path not in self.modifiedtime or mt - self.modifiedtime[path] > 1e-6

    def modified(self, path):
        self.modifiedtime[path] = os.path.getmtime(path)
        self.changed = True

    def addfunction(self, name, module, path, line):
        self.functs.add(name, (module, path, line))

    def addclass(self, name, module, path, line):
        return self.classes.add(name, (module, path, line))

    def addmodule(self, name, path):
        self.modules.add(name, path)

    def addsub(self, subclass, superclass):
        self.sub[superclass].add(subclass)

    def reset(self):
        self.modules = DictWrapper({})
        self.classes = DictWrapper({})
        self.functs  = DictWrapper({})
        #self.sub     = defaultdict(set)
        self.modifiedtime = {}

    def init(self, filename):
        self.filename = filename
        if not os.path.exists(self.filename):
            return
        try:
            tmpfile = os.path.basename(self.filename)+".tmp"
            zf = zipfile.ZipFile(self.filename, mode="r")
            f = cStringIO.StringIO(zf.read(tmpfile))
            self.reset()
            self.modules = DictWrapper(pickle.load(f))
            self.classes = DictWrapper(pickle.load(f))
            self.functs  = DictWrapper(pickle.load(f))
            #self.sub     = pickle.load(f)
            self.modifiedtime = pickle.load(f)
        except Exception,e:
            print 'Error while reading %r' % e
            self.reset()
        finally:
            try:
                zf.close()
            except Exception:
                pass

    def close(self):
        if not self.modules.d:
            return
        tmpfile = os.path.basename(self.filename)+".tmp"
        try:
            zf = zipfile.ZipFile(self.filename, mode="w", compression=zipfile.ZIP_DEFLATED)
            f = cStringIO.StringIO()
            pickle.dump(self.modules.d, f)
            pickle.dump(self.classes.d, f)
            pickle.dump(self.functs.d, f)
            #pickle.dump(self.sub, f)
            pickle.dump(self.modifiedtime, f)
            zf.writestr(tmpfile, f.getvalue())
        finally:
            zf.close()

    def counts(self):
        return len(self.modules.d), len(self.classes.d), len(self.functs.d)
