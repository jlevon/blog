---
title: "Scroll wheel behaviour in vim with gnome-terminal"
date: 2023-11-04T16:21:50Z
---

I intentionally have mouse support disabled in `vim`, as I find not being able to
select text the same way as in any other terminal screen unergonomic.

However, this has an annoying problem as a `libvte` / `gnome-terminal` user: the
terminal, on switching to an "alternate screen" application like `vim` that has
mouse support disabled, "helpfully" maps scroll wheel events to arrow up/down
events.

This is possibly fine, except I use the scroll wheel click as middle-button
paste, and I'm constantly accidentally pasting something in the wrong place as a
result.

This is unfixable from within `vim`, since it only sees normal arrow key
presses (not `ScrollWheelUp` and so on).

However, you *can* turn this off in `libvte`, by the magic escape sequence:

```
echo -ne '\e[?1007l'
```

Also known as `XTERM_ALTBUF_SCROLL`.  This is mentioned in passing in [this
ticket](https://gitlab.gnome.org/GNOME/gnome-terminal/-/issues/27).
Documentation in general is - at best - sparse, but you can always [go to the
source](https://github.com/amosbird/libvte/blob/master/src/modes.py#L1187).
