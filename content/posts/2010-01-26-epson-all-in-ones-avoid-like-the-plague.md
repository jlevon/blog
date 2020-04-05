+++
author = "John Levon"
published = 2010-01-26T23:36:00.002000Z
slug = "2010-01-26-epson-all-in-ones-avoid-like-the-plague"
tags = []
title = "Epson all-in-ones: avoid like the plague"
+++
Browsing the net, you might get the impression that Epson Stylus
All-in-ones are well supported under Linux. Unfortunately this is not
the case. The pipslite driver you have to install is extremely flaky,
and Fedora SELinux doesn't work properly with it. There's no "draft"
mode for some bizarre reason; printing is extremely slow and often
randomly cancels half-printed jobs due to USB resets  
  
The scanner doesn't work at all with the iscan software, despite claims
to the contrary.
