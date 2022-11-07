---
title: "Fetchmail and Office 365"
date: 2022-11-06T22:27:14Z
---

I [previously](https://movementarian.org/blog/posts/mutt-and-office365/)
described accessing Office365  email (and in particular its `oauth2` flow) via
`davmail`, allowing me to continue using `fetchmail`, `procmail` and `mutt`. As
`davmail` is java, it's a pain to have around, so I thought I'd give some
details on how to do this more directly in `fetchmail`, as all the available
docs I found were a little vague, and it's quite easy to screw up.

As it happens, I came across a [generally better
solution](https://github.com/simonrob/email-oauth2-proxy) shortly after writing
this post, on which more later.

# Fetchmail 7

Unfortunately there is little interest in releasing a Fetchmail version with
`oauth2` support - the maintainer is taking a [political
stance](https://sourceforge.net/p/fetchmail/mailman/message/37724737/) on not
integrating it - so you'll need to check out the `next` branch from git:

```
cd ~/src/
git clone -b next git@gitlab.com:fetchmail/fetchmail.git fetchmail-next
cd fetchmail-next
./autogen.sh && ./configure --prefix=/opt/fetchmail7 && make && sudo make install
```

I used the branch as of `43c18a54 Merge branch 'legacy_6x' into next`. Given
that the maintainer warns us they might remove oauth2 support, you might need
this exact hash...

# Generate a token

We need to go through the usual flow for getting an initial token. There's a
helper script for this, but first we need a config file:

```
user=email@yourcompany.com
client_id=facd6cff-a294-4415-b59f-c5b01937d7bd
client_secret=
refresh_token_file=/home/localuser/.fetchmail-refresh
access_token_file=/home//localuser/.fetchmail-token
imap_server=outlook.office365.com
smtp_server=outlook.office365.com
scope=https://outlook.office365.com/IMAP.AccessAsUser.All https://outlook.office365.com/POP.AccessAsUser.All https://outlook.office365.com/SMTP.Send offline_access
auth_url=https://login.microsoftonline.com/common/oauth2/v2.0/authorize
token_url=https://login.microsoftonline.com/common/oauth2/v2.0/token
redirect_uri=https://login.microsoftonline.com/common/oauth2/nativeclient
```

Replace `email@yourcompany.com` and `localuser` in the above, and put it at
`~/.fetchmail.oauth2.cfg`. It's rare to find somebody mention this, but O365
does *not* need a `client_secret`, and we're just going to borrow `davmail`'s
`client_id` - it's not a secret in any way, and trying to get your own is a
royal pain. Also, if you see a reference to `tenant_id` anywhere, ignore it -
`common` is what we need here.

Run the flow:

```
$ # This doesn't get installed...
$ chmod +x ~/src/fetchmail-next/contrib/fetchmail-oauth2.py
$ # Sigh.
$ sed -i 's+/usr/bin/python+/usr/bin/python3+' ~/src/fetchmail-next/contrib/fetchmail-oauth2.py
$ ~/src/fetchmail-next/contrib/fetchmail-oauth2.py -c ~/.fetchmail.oauth2.cfg --obtain_refresh_token_file
To authorize token, visit this url and follow the directions:
  https://login.microsoftonline.com/common/oauth2/v2.0/authorize?...
Enter verification code:
```

*Unlike* `davmail`, this needs just the code, not the full returned URL, so you'll
need to be careful to dig out just the code from the response URL (watch out for
any `session_state` parameter at the end!).

This will give you an access token that will last for around an hour.

# Fetchmail configuration

Now we need an `oauthbearer` `.fetchmailrc` like this:

```
set daemon 60
set no bouncemail
poll outlook.office365.com protocol IMAP port 993
 auth oauthbearer username "email@yourcompany.com"
 passwordfile "/home/localuser/.fetchmail-token"
 is localuser here
 keep
 sslmode wrapped sslcertck
 folders INBOX
 mda "/usr/bin/procmail -d %T"
```

Replace `email@yourcompany.com` and `localuser`.

At this point, hopefully starting `/opt/fetchmail7/bin/fetchmail` will work!

# Refresh tokens

As per the [OAUTH2
README](https://gitlab.com/fetchmail/fetchmail/-/blob/next/README.OAUTH2),
`fetchmail` itself does *not* take care of refreshing the token, so you need
something like this in your `crontab`:

```
*/2 * * * * $HOME/src/fetchmail-next/contrib/fetchmail-oauth2.py -c $HOME/.fetchmail.oauth2.cfg --auto_refresh
```
