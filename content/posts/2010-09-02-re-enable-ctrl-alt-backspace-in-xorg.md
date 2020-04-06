+++
published = 2010-09-02T01:05:00.001000+01:00
slug = "2010-09-02-re-enable-ctrl-alt-backspace-in-xorg"
tags = []
title = "Re-enable Ctrl-Alt-Backspace in Xorg"
+++
Create the following as `/etc/hal/fdi/policy/30user/10-x11-zap.fdi`:  
  
&lt;?xml version="1.0" encoding="UTF-8"?&gt;  
&lt;deviceinfo version="0.2"&gt;  
&lt;device&gt;  
&lt;!--  
Default X.org input configuration is defined in:  
/etc/hal/fdi/policy/30user/10-x11-input.fdi  
Settings here modify or override the default configuration.  
See comment in the file above for more information.  
  
To see the currently active hal X.org input configuration  
run lshal or hal-device(1m) and search for "input.x11\*" keys.  
  
Hal and X must be restarted for changes here to take any effect  
--&gt;  
&lt;match key="info.capabilities" contains="input.keys"&gt;  
&lt;merge key="input.x11\_options.XkbOptions"
type="string"&gt;terminate:ctrl\_alt\_bksp&lt;/merge&gt;  
&lt;/match&gt;  
&lt;/device&gt;  
&lt;/deviceinfo&gt;  
  
and then restart hald and Xorg.
