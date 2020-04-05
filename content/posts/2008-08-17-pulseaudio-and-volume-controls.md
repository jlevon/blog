+++
author = "John Levon"
published = 2008-08-17T17:03:00.002000+01:00
slug = "2008-08-17-pulseaudio-and-volume-controls"
tags = []
title = "PulseAudio and volume controls"
+++
For those wondering how on earth to access an underlying real device
when PulseAudio is enabled (yes, both alsamixer and pavucontrol only
show one mixer control - brilliant!), you can do this:  
  
<span style="font-family: courier new;"><span
style="font-family: courier new;">alsamixer -c 0</span>  
  
Of course, this behaviour isn't documented anywhere. I don't know how
people are supposed to discover this.</span>
