+++
author = "John Levon"
published = 2019-01-24T11:06:00Z
slug = "2019-01-24-wodim-under-ubuntu"
tags = []
title = "wodim under Ubuntu"
+++
wodim/k3b are unusable on Ubuntu: after making sure you're in the cdrom
group, you need to add to `/etc/security/limits.conf`:

    @cdrom - memlock unlimited

(Or some limit, I suppose, if you're bothered.)
