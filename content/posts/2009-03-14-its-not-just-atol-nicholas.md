+++
published = 2009-03-14T12:03:00.004000Z
slug = "2009-03-14-its-not-just-atol-nicholas"
tags = []
title = "It's not just atol(), Nicholas"
+++
Nicholas Nethercote [warns us against
atol()](http://blog.mozilla.com/nnethercote/2009/03/13/atol-considered-harmful/).
Sadly, he recommends using strtol() instead. This interface is almost as
bad. If atol() is [impossible to get
right](http://www.technovelty.org/code/badcode/rusty-hard-to-misuse.html),
strtol() has to be classified under [the obvious use is
wrong](http://www.technovelty.org/code/badcode/rusty-hard-to-misuse.html).  
  
As a perfect example of how horrible strtol() is, let's look at his
example code:  

    int i1 = strtol(s,        &endptr, 0);  if (*endptr != ',')  goto bad;
    int i2 = strtol(endptr+1, &endptr, 0);  if (*endptr != ',')  goto bad;
    int i3 = strtol(endptr+1, &endptr, 0);  if (*endptr != '\0') goto bad;
    ...
    bad: /* error case */

  
Can you spot the bug? What about an input like ",2,3" ? Nicholas does
mention that this code is broken for underflow or overflow (you must
wrap every singe call like this: "errno = 0; strtol(...); if
(errno...)") but either missed this or considered it irrelevant. It's
just too hard to get right.  
  
Just use the \*scanf() family (yes, that's hard to use too). Be
suspicious of any code using <span
style="font-style: italic;">either</span> strtol() or atol().
