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

We're re-using `davmail`'s `client_id` again.

**Updated 2023-10-10**: `emailproxy` now supports a proper headless mode, as
discussed below.

**Updated 2022-11-22**: you also want to set
[delete_account_token_on_password_error](https://github.com/simonrob/email-oauth2-proxy/blob/73f7d8aa44d7404d9a7a3a6f7e9b3f6388c956fc/emailproxy.config#L199)
to `False`: otherwise, a typo will delete the tokens, and you'll need to
re-authenticate from scratch.

We'll configure `fetchmail` as follows:

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
ExecStart=/usr/bin/python3 /home/localuser/src/email-oauth2-proxy/emailproxy.py --external-auth --no-gui --config-file /home/localuser/src/email-oauth2-proxy/my.config
Restart=always
User=joebloggs
Group=joebloggs

[Install]
WantedBy=multi-user.target
```

# Headless operation

Typically, only initial authorizations require the GUI, so you could easily do
the initial dance then use the above systemd service.

Even better, with current versions of `email-oauth2-proxy`, you can operate in
an entirely headless manner! With the above `--external-auth` and `--no-gui`
options, the proxy will prompt on `stdin` with a URL you can copy into your
browser; pasting the response URL back in will authorize the proxy, and store
the necessary access and refresh tokens in the config file you specify.

For example:


```
$ sudo systemctl stop emailproxy

$ python3 ./emailproxy.py --external-auth --no-gui --config-file /home/localuser/src/email-oauth2-proxy/my.config

# Now connect from mutt or fetchmail.

Authorisation request received for email@yourcompany.com (external auth mode)
Email OAuth 2.0 Proxy No-GUI external auth mode: please authorise a request for account email@yourcompany.com
Please visit the following URL to authenticate account email@yourcompany.com: https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=...

Copy+paste or press [↵ Return] to visit the following URL and authenticate account email@yourcompany.com: https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=...
then paste here the full post-authentication URL from the browser's address bar (it should start with https://login.microsoftonline.com/common/oauth2/nativeclient):

# Paste the updated URL bar contents from your browser in response:

https://login.microsoftonline.com/common/oauth2/nativeclient?code=...

SMTP (localhost:1587; email@yourcompany.com) [ Successfully authenticated SMTP connection - releasing session ]
^C
$ sudo systemctl start emailproxy
```

Obviously, you'll need to do this interactively from the terminal, then restart
in daemon mode.
