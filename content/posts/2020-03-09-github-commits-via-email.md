+++
author = "John Levon"
published = 2020-03-09T00:40:00Z
slug = "2020-03-09-github-commits-via-email"
tags = []
title = "github commits via email"
+++
I'm the old-fashioned type who still likes getting email: I can process
it at my leisure while still handling high volume. Unfortunately github
itself can't email you when commits are made to a particular repo
(unless you own it and can configure hooks). So I need to resort to the
atom feeds, and [rss2email](https://github.com/rss2email/rss2email):

    $ r2e new jlevon@movementarian.org
    $ vi .rss2email/config.py
       # set local (sendmail) delivery, disable HTML mail, etc.
    $ r2e opmlimport subscriptions.xml
    $ declare -f github-commits
    github-commits () 
    { 
        r2e add $(basename $1) "https://github.com/$1/commits/master.atom"
    }
    $ crontab -l | grep r2e
    */10 * * * * r2e run
    $ tail -3 .procmailrc 
    :0
    * User-Agent: rss2email
    commits/

So every 10 minutes, we'll get new commits from all the watched repos,
and procmail them into a `commits` folder.

Private repositories
--------------------

It's pretty ghetto, but if you look at the source for
`https://github.com/me/privaterepo/commits/master`, you'll find an Atom
link including a token that you can use for getting notifications from
private repos. At least you're not handing it off to a third-party like
IFTT with the above approach...
