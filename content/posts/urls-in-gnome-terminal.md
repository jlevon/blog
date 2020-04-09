---
title: "URLs in gnome-terminal and mutt"
date: 2020-04-09T14:35:04Z
---

For some time now, `gnome-terminal` amongst others has had a heuristic
that guesses at URLs, and allows you to control-click to directly open
it. However, this was easily foxed by applications doing line-wrapping
instead of letting the terminal do so.

A few years ago, `gnome-terminal` gained [ANSI escape sequences for URL
highlighting](https://purpleidea.com/blog/2018/06/29/hyperlinks-in-gnome-terminal/).
It requires applications to output the necessary escape codes, but works
far more reliably.

Annoyingly, you still need to control-click, but that is [easily
fixed](https://github.com/jlevon/gnome-terminal/tree/hyperlink-click).
I rebuilt Ubuntu's build with this change like so:

```
sudo apt build-dep gnome-terminal
apt source gnome-terminal
cd gnome-terminal-3.28.2
dpkg-buildpackage --no-sign -b
sudo dpkg -i ../gnome-terminal_3.28.2-1ubuntu1~18.04.1_amd64.deb
```

This would be most useful if `mutt` supported the sequences, but
unfortunately its built-in pager is stuck behind `libncurses` and can't
easily get out from under it. Using an external pager with `mutt` is not
great either, as you lose all the integration.

There's also [no support in
`w3m`](https://github.com/tats/w3m/issues/116). Even though it
thankfully avoids `libncurses`, it's a bit of a pain to implement, as
instead of just needing to track individual bits for bold on/off or
whatever, there's a whole URL target that needs mapping onto the
(re)drawn screen lines.

So instead there's the somewhat ersatz:

```console
$ grep email-html ~/.muttrc
macro pager,index,attach k "<pipe-message>email-html<Enter>"
```

where

```bash
$ cat email-html
#!/bin/bash

dir=$(mktemp -d -p /tmp)

ripmime -i - -d $dir --name-by-type

cat $dir/text-html* | w3m -no-mouse -o display_link \
    -o display_link_number -T text/html | \
    sed 's!https*://.*!\x1B]8;;&\x1B\\&\x1B]8;;\x1B\\!g' | less -rX

rm -rf $dir
```

It'll have to do.
