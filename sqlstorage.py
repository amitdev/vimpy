import sqlite3
import os

class storage(object):
    
    def __init__(self, filename):
        self.conn = sqlite3.connect(filename)
        self.c = self.conn.cursor()
        self.modifiedtime = {}
        self.changed = False        
        if not self.tables():
            self.c.execute("create table times (file TEXT, time REAL)")
            self.c.execute("create table classes (name TEXT, module TEXT, path TEXT, line INTEGER)")
            self.c.execute("create table modules (name TEXT, path TEXT)")
        else:
            self.c.execute("select * from times")
            for row in self.c:
                self.modifiedtime[row[0]] = row[1]                

    def tables(self):
        self.c.execute("SELECT name FROM sqlite_master WHERE name='classes'")
        return [r for r in self.c]

    def addclass(self, name, module, path, line):
        self.c.execute("INSERT INTO classes VALUES ('%s', '%s', '%s', %d)" % (name, module, path, line))

    def addmodule(self, name, path):
        self.c.execute("INSERT INTO modules VALUES ('%s', '%s')" % (name, path))

    def modules(self, name):
        self.c.execute("SELECT * from modules where name like '%s%%'" % name)
        return [r for r in self.c]
        
    def printclasses(self):
        self.c.execute("SELECT * FROM classes")
        for r in self.c:
            print r
        
    def classes(self, classname, modulename=None):
        modulepart = ''
        if modulename is not None:
            modulepart = " and module = '" + modulename + "'"
        self.c.execute("SELECT * from classes where name like '%s%%'%s" % (classname, modulepart))
        return (r for r in self.c)

    def ismodified(self, file):
        mt = os.path.getmtime(file)
        return file not in self.modifiedtime or mt - self.modifiedtime[file] > 1e-6
    
    def modified(self, file):
        self.modifiedtime[file] = os.path.getmtime(file)
        self.changed = True

    def close(self):
        if self.changed:
            self.c.execute("DELETE from times")
            for k, v in self.modifiedtime.iteritems():
                self.c.execute("INSERT into times values ('%s', %f)" % (k, v))
        self.conn.commit()
        self.c.close()

