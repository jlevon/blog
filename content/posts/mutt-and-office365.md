---
title: "Mutt and Office365"
date: 2020-11-06T11:50:39Z
---

For reasons, I now need to interact with Office365 mail and calendar.  It should
go without saying that the Outlook webapp is almost painfully unusable (there
really is no key binding for "next unread email"). Thus began the quest to get
mutt interacting with the O365 server. This was a rather painful process: so
much of the information on the web refers to earlier authentication schemes,
Microsoft-special protocols, things that don't support 2FA, dead Linux software,
useless Linux software, etc.

After many false starts, I eventually found a working solution that allows mutt
usage (and my treasured key binding for "mark current thread as read and move to
the next unread email"). That solution is
[davmail](http://davmail.sourceforge.net/). Yes, it's on sourceforge, and yes,
it's Java, but it works perfectly.

It's not very well-documented, but you *can* run it in headless mode and still
do the interactive OAuth2 flow needed with modern O365. Your settings should
include:

```
davmail.mode=O365Manual
davmail.url=https://outlook.office365.com/EWS/Exchange.asmx
```

When `davmail` starts, it will ask you to visit a URL and paste the resulting URL
back - this contains the necessary OAuth2 tokens it needs. No need for any GUI!

Once `davmail` is running, your `.fetchmailrc` can be:

```
poll localhost protocol IMAP port 1143
 auth password username "username@company.com"
 is localuser here
 sslmode none
 keep
 mda "/usr/bin/procmail -d %T"
 folders INBOX,etc,etc
```

Note that since `davmail` is running locally, there's not really any need for SSL,
though you can set that up if you like.

When you start `fetchmail`, enter your password, and that will initiate the auth
flow against the `davmail` instance. Note that you're not storing passwords
anywhere, unlike the old-style app password approach you might have used
previously on gmail and the like.

I don't need to send mail often, so I have `mutt` set up like this:

```
set smtp_url= "smtp://username@company.com@localhost:1025/"
unset smtp_pass
set ssl_starttls=no
set ssl_force_tls=no
```

Having to enter my password each time is not a big deal for me.

Equally I have my calendar app set up to pull over caldav from `davmail`. Works
great. I'd love to be able to pull my O365 calendar into Google Calendar, but
apparently Google and Microsoft are unable - or more likely unwilling - to
make this work in any meaningful way.

I'm pretty sure it's possible to adapt Google's OAuth2 scripts to directly use
`fetchmail` with O365's modern auth stuff, but I'm not sure I have the energy to
figure it out - and as far as I can find, nobody else has?

