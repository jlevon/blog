+++
published = 2010-01-26T17:28:00.003000Z
slug = "2010-01-26-setting-up-jack-on-fedora-12"
tags = []
title = "Setting up JACK on Fedora 12"
+++
Audacity is somewhat of a broken joke these days, so I needed to use
Ardour to record. And that meant setting up JACK. Since JACK insists on
exclusivity, I also needed to route pulseaudio through JACK so I could
use other apps at the same time. Unfortunately, this is a bit of a pig
to figure out. I hacked it as follows:  

  
First edit `/etc/pulse/default.pa`, you need to add two lines:  
  

    load-module module-jack-sink
    load-module module-jack-source

  
In theory now, a restart of pulseaudio should start using JACK for
recording and playback, if jackd is running. However, it tends not to
work very well: you might find PA hanging and you have to kill -9 it.  

  
This isn't enough of course, now when you log in again, gnome-session
will try to start pulseaudio, but not jackd, so nothing works. It's far
from the right way, but I edited `/usr/bin/start-pulseaudio-x11` (which
is started from a `/etc/xdg/autostart/` script), as follows:  

    amixer -c 0 sset 'Input Source' 'Line'

    nohup jackd -d alsa &

    sleep 5

    /usr/bin/pulseaudio --start "$@"

  
Note that I have to set the input source by hand: something in desktop
start up used to do this for me, but now I'm going through JACK it has
to be done by hand.
