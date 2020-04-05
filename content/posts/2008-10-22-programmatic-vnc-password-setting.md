+++
author = "John Levon"
published = 2008-10-22T14:50:00.004000+01:00
slug = "2008-10-22-programmatic-vnc-password-setting"
tags = []
title = "Programmatic VNC password setting"
+++
I had this problem recently: I was generating automatic VNC passwords
via /dev/urandom, and needed to obfuscate them. Stupidly, vncpasswd is
only interactive, and I wasn't in any kind of mood for hacking up the
sources. A co-worker kindly pointed me to the solution:  
  
printf "%s\\n%s\\n" "$PASSWD" "$PASSWD" | vncpasswd /tmp/vncpasswd  
  
In my head, the use of getpass() means this couldn't work, but it does.
It doesn't appear to be on Google, so I thought I'd mention it. Of
course, as all know, the obfuscation done by vncpasswd is entirely
pointless, but Xvnc at least will only take such "encrypted" password
files.
