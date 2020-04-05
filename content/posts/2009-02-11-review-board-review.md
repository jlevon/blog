+++
author = "John Levon"
published = 2009-02-11T05:09:00.004000Z
slug = "2009-02-11-review-board-review"
tags = []
title = "Review board review"
+++
I was bored so played around with [Review
Board](http://www.review-board.org/) a little more, including
[installing it myself](http://cr.movementarian.org/).  
  
Things seem to have got easier to install, at least to some degree. You
can use <span style="font-family:courier new;">easy\_install</span>,
though at least  
for CentOS 5.2, you'll need to install a newer version of setuptools
first. It's also far from automated, missing  
out basic dependencies like pysqlite2, patchutils, and even patch
itself. Discovering these can be, and in my case was, rather tedious
work.  
  
After that it's pretty easy to install, for the sqlite version anyway.
The documentation isn't exactly clear on  
what permissions changes you need to make: you need to chown all of db/
to the apache user as well for anything to work. Expect to set up a
virtual host for the installation, like I did above.  
  
Don't forget to enable logging in the admin interface whilst you're
messing around.  
  
Sadly, the Mercurial support seems some way behind. For example, it
doesn't pick up changeset comments.  
  
The diff parser (how is this not in a library by now?) can't handle git
diffs, and the failure mode is horrible (basically, silent failure, with
no debugging messages). This is because hg git diffs don't contain the
revisions being diffed, so Review Board can't pull the files from the
repo. Undoubtedly a Mercurial misfeature, but it does make Review Board
near useless for my purposes unfortunately.  
  
It can handle ssh repositories (which is all
[opensolaris.org](http://opensolaris.org/os/get/) provides), but there's
a horrible work around needed: you have to set up a correct known\_hosts
file in the apache user's home directory. Yuck.  
  
As for the main interface, it's generally pretty slick. I can imagine it
getting cumbersome quickly with large code reviews though. Compare and
contrast Review Board's [diff
viewer](http://cr.movementarian.org/r/6/diff/#index_header) with
[webrev](http://cr.opensolaris.org/%7Ecmynhier/4775687.2/). The latter
to me at least, is much more scalable, even though the actual diff
mechanism is less smart. In particular, I can review each file with
webrev in a separate tab, whereas Review Board insists on one big (very
big!) screen. I'd still give my right arm for a webrev-based Review
Board :)  
  
Another thing I'd like to see is more integration with the repository,
so I can click on a file and it will take me off to the repo browser for
looking through history.
