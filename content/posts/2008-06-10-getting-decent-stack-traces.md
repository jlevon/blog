+++
author = "John Levon"
published = 2008-06-10T23:41:00.002000+01:00
slug = "2008-06-10-getting-decent-stack-traces"
tags = []
title = "Getting decent stack traces"
+++
Reading through [this
bug](https://bugzilla.novell.com/show_bug.cgi?id=390722) is seriously
depressing to read (until Michael Matz steps in).  
It was always complete madness to strip symbols from shipping binaries;
it was always  
madness to disable the frame pointer too. (The debuginfo trick is an
excellent solution  
to the problems of source-level debugging, by the way, it's just taken
way, way, too far).  
  
This is why you have to install a 1Gb debuginfo RPM in order to run
OProfile on the kernel. Crazy.  
  
It's a good read if you like to see certain people behaving like asshats
to their fellow community  
members too.
