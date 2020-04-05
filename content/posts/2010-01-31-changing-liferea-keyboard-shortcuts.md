+++
author = "John Levon"
published = 2010-01-31T17:26:00.003000Z
slug = "2010-01-31-changing-liferea-keyboard-shortcuts"
tags = []
title = "Changing liferea keyboard shortcuts"
+++
Liferea has no keyboard shortcut editor itself, but "Toggle unread
status" demands the wrist-breaking chord action of Control-U. It expects
you to be able to edit the shortcuts via the editable menu feature of
GTK+.  

  
Unfortunately that's disabled on all modern GNOME installs, and there's
no UI for re-enabling it. As usual, `gconf-editor` to the rescue. The
key you need to change is `/desktop/gnome/interface/can_change_accels`.
After re-starting Liferea, you can then edit via hovering over the menu
item and pressing the combination. Of course, this in itself is buggy:
if it clashes with a menu accelerator (as 'r' is), it will perform that
action instead.  

  
It's simpler to directly edit the `accels` file in your Liferea dot dir.
