+++
published = 2011-01-05T23:39:00.005000Z
slug = "2011-01-05-avoid-vps247-hosting"
tags = []
title = "Avoid vps247 hosting"
+++
Late last year, I was forced to find a new host for
[movementarian.org](http://movementarian.org/), as my previous hosting
provider (Blue Room Hosting, who were really great) were shutting down.
I went with [VPS247](http://vps247.com), as they were local to
Manchester and seemed reasonable.

  
Unfortunately my experience has been terrible. They've failed to keep
the machines on the net, regularly causing ssh sessions to die. The
dmesg is full of warnings about the block drivers failing to write for
more than two minutes: evidently the SAN setup they have is totally
unreliable.

  
My VM went down for a significant amount of time and support were very
slow to respond. During the total outage, there were no status updates,
and no response on the support tickets or the forums. The penultimate
straw was when my filesystem was massively corrupted. Even though my VM
is hardly critical, I can't be doing with unreliability like this,
especially when they're not reachable when problems occur.

  
My final straw, though, was when I discovered they'd deleted all the
negative comments from the [Client Comments section of their
forum](http://www.vps247.com/forums/forumdisplay.php?10-Client-Comments).
That's really, really, not on.

  
I'm now with linode and happy (so far).
