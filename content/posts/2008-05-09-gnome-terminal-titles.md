+++
author = "John Levon"
published = 2008-05-09T01:58:00.002000+01:00
slug = "2008-05-09-gnome-terminal-titles"
tags = []
title = "gnome-terminal titles"
+++
This finally annoyed me enough to find a solution.  
  
If I set a title on a gnome-terminal tab, then it gets forgotten next
time I log in. Aside from the GNOME default to not save your session
(whuh?), the problem is this: on Fedora, /etc/bashrc forces
PROMPT\_COMMAND to set the xterm title.  
  
This wouldn't really be a problem, if I could disable setting of dynamic
titles in gnome-terminal preferences. However, gnome-terminal thinks
that a manually-set (Terminal-&gt;Set Title) title is somehow "dynamic",
so if you do that, you can never set the title to anything else.  
  
Seeing as I use the tab titles to work what machine I'm on, that's quite
annoying.  
  
The "solution" was to just edit /etc/bashrc so it doesn't force a
PROMPT\_COMMAND I don't want.
