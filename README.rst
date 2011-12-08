VimPy
=====

This Vim plugin is to make navigation of Python files easier with Vim. If you have a large python project, navigating to multiple files may not be easy. There are various ways to make it easier like using ctags/ptags, gf over the python path etc. But it does not work well with multiple files with same name, going to a praticular class/function etc.

Features
========

Currently it provides two functions - Open and Goto.
Open can be used to open any python module in the project by module name, class name or function.
Goto can be used to goto a module name, class name or function based on token in a file.

Usage
=====
Usage is similar to how ctags/ptags work in Vim. Basically there are 2 steps:

1. Create the index file.
   Use `:VimpyCreate <project-name> path [exclude-path]` to create index. (Alternatively, the vimpy.py script can be invoked using python to create the index file. See 'python vimpy.py' for usage.)
   This is a one time operation. The index will be automatically updated if you edit the files using vim, otherwise this can be rerun and only the changed files will be updated.

2. Load the index file in Vim. This can be done using ':VimpyLoad <file-name>' inside Vim. This can automated by adding in the vimrc.
Now it is ready to use! Following commands (the Keybindings can be changed in vimpy.vim) can be used to navigate to any desired module:

    - <leader> om : Open Module. Go to a module with a given name. 
    - <leader> oc : Open Class. Go to a class with a given name. 
    - <leader> of : Open Function. Go to a funtion with a given name. 
    - <leader> gm : Goto Module given by word under cursor (Eg. use this to navigate to a module under an 'import' statement).
    - <leader> gc : Goto Class given by word under cursor. 
    - <leader> gf : Goto Function given by word under cursor. 

All of them has auto completion support, so you just need to type in few characters and press <tab>.
[<leader> is typically the '\' character, but you can change it to anything (One good option is ',')].

TODO
====

There are lots of things to do. Major ones being:

 - Support packages
 - Make the goto option more intelligent
