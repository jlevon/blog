+++
published = 2010-09-02T01:13:00.003000+01:00
slug = "2010-09-02-pbranch-curiosities"
tags = []
title = "pbranch curiosities"
+++
I've started using [pbranch](http://arrenbrecht.ch/mercurial/pbranch/)
extension for `hg` more seriously. It works nicely but is a little rough
around the edges, in particular:  
  

  
No hg qpop/push equivalent  
  
  
I really miss this. I find myself constantly doing `hg pgraph` to figure
out where I am and then typing the patch above or below.  

  
No way to shelve a patch  
  
  
With MQ, I can easily guard a patch to temporarily remove it from the
queue. There doesn't seem to be a simple way to do that with pbranch.  

  
Editing patch messages.  
  
  
You use peditmessage, but because this modifies the repository, you then
have to always `hg pmerge -all`. This pops to the top and causes a bunch
of extra changesets, and it gets annoying quickly. And frustratingly,
these patch messages do \*not\* appear in the repo history. So your code
reviews of the main repo are just showered in useless merge messages,
instead of the actual commit message you care about.  

  
No pfinish  
  
  
I don't know why, but there's no way to automatically commit a patch as
a single changeset on the root default tip, then close the patch
branch.  

  
Inserting and deleting patches is horrible  
  
  
[Yuck](http://arrenbrecht.ch/mercurial/pbranch/insert.htm) - I really
hope this gets easier soon.  

  
Showing the current patch history  
  
  
A little tip not mentioned on the pbranch site: the way to show the
changelog history of the current patch is to do `hg log -b patchname`.
