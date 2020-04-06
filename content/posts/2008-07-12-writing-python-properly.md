+++
published = 2008-07-12T14:33:00.002000+01:00
slug = "2008-07-12-writing-python-properly"
tags = []
title = "Writing Python Properly"
+++
What are people's approaches to writing Python correctly? The library
documentation basically doesn't document the set of exceptions the
routines can throw, which makes it very difficult to catch the right
things, and do the right thing\[1\] ([for
example](http://docs.python.org/lib/module-popen2.html)). What do people
do to deal with this problem?  
  
\[1\] on that note, if you're writing a command line tool in Python,
<span style="font-style: italic;">please</span> catch KeyboardInterrupt
and exit quietly. Drives me crazy!
