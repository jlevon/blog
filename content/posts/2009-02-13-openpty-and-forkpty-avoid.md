+++
author = "John Levon"
published = 2009-02-13T01:56:00.007000Z
slug = "2009-02-13-openpty-and-forkpty-avoid"
tags = []
title = "openpty() and forkpty(): avoid"
+++
After dealing with more code that gets it wrong I was reminded of the
numerous reasons why `openpty() is such a broken API.` The prototype of
this "convenience" function is this:  

    int openpty(int *amaster, int *aslave, char *name, struct termios *termp, struct winsize *winp);

  
Now, sin number one should be obvious: the interface isn't
const-correct. You're passing in the `winp` values, but there's no
indication of that. Worse, you're doing the same with `termp`. Why
worse? Well, think about how you use this API. Typically, you want to
create the master/slave pair of the pseudo-terminal, then change the
terminal settings of the slave. (Let's leave the master out of this for
now - but the settings are not always symmetrical.)  
  
But where do we get the terminal settings from? We don't have an open
slave to base them on yet! So you [find
code](http://xenbits.xensource.com/xen-unstable.hg?file/32b154137492/tools/console/daemon/io.c)
doing a `cfmakeraw()` on stack junk and passing that in, because the API
almost insists you do the wrong thing.  
  
Indeed, doing it right, namely with a
`tcgetattr()/cfmakeraw()/tcsetattr()` stanza, you'd expect `term` to be
an out parameter, that you could then use - precisely opposite to how it
actually works, and what const correctness suggests to the user. You can
see some
[other](http://www.google.com/codesearch/p?hl=en#PE_24GxN6Yw/wine-990225/console/xterm.c&q=openpty%20lang:c&l=125)
[amusing](http://www.google.com/codesearch/p?hl=en#hpsIVejYA1Y/uim-1.4.1/fep/uim-fep.c&q=openpty%20lang:c&l=402)
[examples](http://www.google.com/codesearch/p?hl=en#_Q5tCkxUtCc/kgdbtunnel-1.0a1/kgdbtunnel.c&q=openpty%20lang:c&l=183)
of how people worked around the API though.  
  
I'm sure you will have spotted by now that the `name` parameter is
outgoing, but has no `len`. It's therefore impossible to use without the
risk of buffer overflow.  
  
This API is not going to score well on the [Rusty
scale](http://www.pointy-stick.com/blog/2008/01/09/api-design-rusty-levels/).
What's worst of all about `openpty()`, though, is that it's
non-standard, so almost every piece of code out there keeps its own
private copy of this broken, pointless interface. Yay!
