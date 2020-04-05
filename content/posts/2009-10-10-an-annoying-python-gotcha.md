+++
author = "John Levon"
published = 2009-10-10T17:05:00.003000+01:00
slug = "2009-10-10-an-annoying-python-gotcha"
tags = []
title = "An annoying Python gotcha"
+++
Imagine you have this in mod.py:  

    import foo

    class bar(object):
       ...

       def __del__(self):
           foo.cleanup(self.myhandle)

  
Seems fine right? In fact, there's a nasty bug here. If I try to use
this module in client.py like so:  

    import mod
    mybar = bar()

  
  
Then you're likely to get an exception when the program exits. This is
because Python, for some bizarre reason, Nones out the globals in
`mod.py` when taking down the interpreter. The actual `__del__` method
can be called sometime *after* this, and it ends up trying
`None.cleanup()`, with the resultant `AttributeError`. It seems
extremely bizarre that it happens in this order, but it does ([a real
example](http://mail.python.org/pipermail/python-bugs-list/2009-January/069209.html)).
