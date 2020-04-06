---
title: "Migrated Blog"
date: 2020-04-06T11:33:36Z
---

With my Coronavirus-related CFT I finally got around to migrating off
Blogger. I lost comments, but I think I'll probably keep it like that:
there's twitter, and Blogger's anti-spam facilities were pretty much
hopeless.

My first attempt used [jekyll](https://jekyllrb.com). I
suppose this works best with Github Pages, because I gave up on it
pretty quickly: various irritating Ruby version incompatibilities,
random tracebacks from modules, import not working well at all etc.

Next stop was [hugo](https://gohugo.io/) which was much, much
nicer. Although it was still a little tedious to import (there's not
really integration, so you need 3rd party tools like the one I used
to import the Blogger content -
[blog2md](https://github.com/palaniraja/blog2md).

The base theme I ended up using was [Strange
Case](https://themes.gohugo.io/strange-case/). Having battled with
impenetrable Wordpress themes in the past, it was refreshing to be able
to modify something so eminently hackable, and being based on the
familiar [bootstrap](https://getbootstrap.com/) was a big plus as well.

It took me a while to fix up a few things (like making Recent Posts
show only posts, instead of all pages), and getting used to the way
hugo searches the layout files took a bit of time, but it was all in all
a good experience.

It seemed a little tricky to create all the necessary `301 Redirect`
directives for the old Blogger-style permalinks, so I crapped out and
just manually added a few that I know people might actually want to find
via Google.

I spent far too long trying to find an Atom feed importer for my [old
Sun blog](https://movementarian.org/blog/categories/old-sun-blog/).
Seems like there isn't a general one, so I threw
[roller2hugo](https://github.com/jlevon/roller2hugo) together instead,
which works just enough.
