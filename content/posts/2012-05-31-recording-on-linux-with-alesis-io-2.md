+++
published = 2012-05-31T16:39:00+01:00
slug = "2012-05-31-recording-on-linux-with-alesis-io-2"
tags = []
title = "Recording on Linux with Alesis io|2"
+++
A little note for myself: to get low-latency monitoring, and more
importantly, record at the right rate, you need to set the
Configuration-Profile to "Digital Stereo Input" in `pavucontrol`!  
  
Update: you also need this in ~/.pulse/daemon.conf :  
  
 default-sample-rate=48000  
  
Another update: PA/ALSA often seems to forget the sensible default
devices, and ocenaudio starts  
trying to record from the monitor devices. Solution seems to be to run
pavucontrol, start ocenaudio recording, and change the drop down box to
select io|2 Digital Stereo.
