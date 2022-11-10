---
title: "A Headless Office 365 Proxy"
date: 2022-11-09T23:47:56Z
---

As I mentioned in my [last
post](https://movementarian.org/blog/posts/fetchmail-and-office-365/), I've been
experimenting with replacing `davmail` with Simon Robinson's super-cool
[email-oauth2-proxy](https://github.com/simonrob/email-oauth2-proxy), and
hooking `fetchmail` and `mutt` up to it. As before, here's a specific rundown of
how I configured O365 access using this.

# Configuration

We need some small tweaks to the shipped configuration file. It's used for both
permanent configuration and acquired tokens, but the static part looks something
like this:

```
[email@yourcompany.com]
permission_url = https://login.microsoftonline.com/common/oauth2/v2.0/authorize
token_url = https://login.microsoftonline.com/common/oauth2/v2.0/token
oauth2_scope = https://outlook.office365.com/IMAP.AccessAsUser.All https://outlook.office365.com/POP.AccessAsUser.All https://outlook.office365.com/SMTP.Send offline_access
redirect_uri = https://login.microsoftonline.com/common/oauth2/nativeclient
client_id = facd6cff-a294-4415-b59f-c5b01937d7bd
client_secret =
```

We're re-using `davmail`'s `client_id` again. We'll configure `fetchmail` as
follows:

```
poll localhost protocol IMAP port 1993
 auth password username "email@yourcompany.com"
 is localuser here
 keep
 sslmode none
 mda "/usr/bin/procmail -d %T"
 folders INBOX
```

and `mutt` like this:

```
set smtp_url = "smtp://email@yourcompany.com@localhost:1587/"
unset smtp_pass
set ssl_starttls=no
set ssl_force_tls=no
```

When you first connect, you will get a GUI pop-up and you need to interact with
the tray menu to follow the authorization flow. After that, the proxy will
refresh tokens as necessary.

# Running in systemd

Here's my `service` file I use, slightly modified from the upstream's README:

```
$ cat /etc/systemd/system/emailproxy.service
[Unit]
Description=Email OAuth 2.0 Proxy

[Service]
ExecStart=/home/localuser/src/email-oauth2-proxy/emailproxy.py --external-auth --no-gui --config-file /home/localuser/src/email-oauth2-proxy/my.config
Restart=always

[Install]
WantedBy=multi-user.target
```

# Headless operation

In the upstream project, only initial authorizations require the GUI.
Unfortunately, for truly headless operation, things are a bit more complicated.
In theory, you can use the `--local-server-auth` with a localhost
`redirect-uri`, but this is awkward enough to use that it seems useless: the
`README` talks vaguely about log monitoring, and this hack isn't permitted by
the `davmail` `client_id` anyway.

The maintainer isn't interested in supporting headless in any other way, so I
have a fork with this in [my no-gui-external
branch](https://github.com/jlevon/email-oauth2-proxy/tree/no-gui-external).

This does what `davmail` does when an authorization is needed, like this:

```
$ sudo systemctl stop emailproxy
$ ./emailproxy.py --no-gui --config-file /home/localusr/src/email-oauth2-proxy/my.config --external-auth
# Now connect from mutt or fetchmail
2022-11-09 23:44:25: Authorisation request received for email@yourcompany.com (interactive mode)
Please visit the following URL to authenticate account email@yourcompany.com: https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=...
Please paste the full resulting redirection URL:
# ...
2022-11-09 23:44:42: SMTP (localhost:1587; email@yourcompany.com) [ Successfully authenticated SMTP connection - releasing session ]
^C
$ sudo systemctl start emailproxy
```

Obviously, you'll need to do this interactively from the terminal, then restart
in daemon mode.

So far this is working well for me, but it's certainly ugly. I wish there a
better way to do this...
