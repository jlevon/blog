+++
author = "John Levon"
published = 2010-01-17T16:33:00.007000Z
slug = "2010-01-17-liferea-strict-feed-validation-tip"
tags = []
title = "Liferea strict feed validation tip"
+++
New versions of Liferea refuse to parse any feed that fails to validate,
even for relatively "minor" problems (the libxml2 recovery facility is
no longer used; besides, it abandons the rest of the feed when it hits
such problems). I don't want to use Google Reader, since I don't like
the interface.  

  
Typically bad feeds have things like high-bit chars or bare ampersands.
Thankfully, there's a "conversion filter" feature that you can use to
work around the bad feeds. On the two bad feeds, I run this filter:  

    [moz@pent ~]$ cat bin/fix-ampersands 
    #!/bin/bash

    sed 's/\o226/&amp;/g' | sed 's/& /\&amp;/g' | sed 's/\o243/GBP/g'
