+++
author = "John Levon"
published = 2014-01-10T11:53:00.001000Z
slug = "2014-01-10-ripping-vinyl-on-linux"
tags = []
title = "Ripping vinyl on Linux"
+++
I've been ripping a lot of stuff from vinyl to FLAC recently. Here's
how I do it.  
  
I have an Alesis I/O 2, which works well and seems fairly decent
quality.  
  
First, most important, step, is to stop trying to use Audacity. It's
incredibly broken and unreliable. Go get ocenaudio instead. It's fairly
new, but it works reliably.  
  
After monitoring your levels, record the whole thing into ocenaudio.  
  
First trim any obviously loud clicks such as when landing the needle.
ocenaudio doesn't seem to have a "draw sample" function yet, the only
thing I miss from Audacity, but deleting just a few samples is usually
fine.  
  
Normalise everything.  
  
Then select a whole track using Shift-arrows (and Control to go faster).
Press Control-K to convert it into a region, and name it if you like.  
You'll see references to using zero-crossing finders to split tracks.
This is always a bad idea - it's simply not reliable enough, especially
with an old crackly record, isopropyl'd or not.  
  
Zoom all the way out again, make sure the number of tracks is right.  
  
Then File-&gt;Export Audio From Regions, making sure that the "separate
files" checkbox is set.  
  
Now it's tagging time: run "kid3 yourdirwithflacs". First import from
discogs, presuming it has the release (it usually will) File-&gt;Import
From Discogs. Then click 'Tag 2' in the Format Up part, along with the
format you need. Save all those, then use Tools-&gt;Rename Directory to
rename the containing directory. You're done.
