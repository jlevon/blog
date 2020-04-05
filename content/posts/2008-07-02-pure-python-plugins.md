+++
author = "John Levon"
published = 2008-07-02T03:17:00.002000+01:00
slug = "2008-07-02-pure-python-plugins"
tags = []
title = "Pure Python Plugins"
+++
After some searching and asking around I didn't find any good
explanation of the simplest way to implement plugins in Python. So, for
posterity's sake, here's my solution. I'm sure there's a better way: I'd
love to hear your suggestions.  
  
First, the requirements. The code cannot have knowledge of how the
plugins are named (.so files, .py, package dirs, etc.). I don't want to
hard-code the list of plugins, as this defeats its dynamic nature
altogether. I have to be able to iterate across all plugins. Any user
should be able to use the module without knowing that it's got plugins.
Finally, it's got to be as simple as possible.  
  
First up, we have `whatever/__init__.py`:  
  

    import pkgutil
    import imp
    import os

    plugin_path = [os.path.join(__path__[0], "plugins/")]

    for loader, name, ispkg in pkgutil.iter_modules(plugin_path):
        file, pathname, desc = imp.find_module(name, plugin_path)
        imp.load_module(name, file, pathname, desc)

  
  
This basically uses Python's module search to find all contents of the
`plugins` sub-directory and load them. Now we have some more scaffolding
in the same directory, as `whatever/whatever.py`:  
  

    plugins = []

    class plugin(object):
       """Abstract plugin base class."""
       ...

    def register_plugin(plugin)
        global plugins
        plugins += [ plugin ]

    # utility functions to iterate across and use plugins...

  
  
Finally, each plugin looks something like this, in `plugins/foo.py`:  
  

    from whatever/whatever import *

    class fooplugin(plugin):
        """Concrete class for foo plugin."""
        ...

    register_plugin(fooplugin)

  
  
Simple enough, but it took a while to work it out. Unfortunately, it
doesn't seem possible to merge `whatever.py` into `__init__.py` as we
have a recursive import problem.
