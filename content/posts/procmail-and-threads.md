---
title: "procmail and threads"
date: 2020-09-14T19:13:05Z
---

I'm apparently old-school enough to find `gmail` and co painfully inefficient for
handling significant amounts of mail. I still find `procmail`+`mutt`
hard to beat. One thing `mutt` can't do, however, is filter threads
automatically - there's no "mute" facility like `gmail` has; threads
have to processed manually.

Equally, `procmail` itself has no threading facilities or understanding
of `Message-Id` or `References`.

# Matching email threads

It can be done, though, with some cheesy awk:

```bash
#!/bin/bash

#
# If a mail message has a References: value found in the refs file, then
# add the requested header.
#
# Usage:
#
# cat mail_msgs | match-thread.sh ~/.mail.refs.muted "Muted: true"
#

ref_file="$1"
header="$2"

mail=/tmp/match-thread.mail.$$
cat - >$mail

newrefs="$(cat $mail | formail -x references -x message-id | tr -d '\n')"

touch $ref_file

cat $ref_file | awk -v newrefs="$newrefs" '

	BEGIN {
		found = 0;
		split(newrefs, tmp);
		for (i in tmp) {
			refs[tmp[i]]++;
		}
	}

	# Each thread will have one line in the ref file, with
	# space-separated references. So we just need to look for any
	# reference from the mail.
	{
		for (ref in refs) {
			if (index($0, ref) != 0) {
				found = 1;
				exit(0);
			}
		}
	}

	END {
		exit(found ? 0 : 1);
	}
'

if [[ $? = 0 ]]; then
	cat $mail | formail -i "$header"
else
	cat $mail
fi

rm $mail
```

Essentially, we record all the `References` in the thread we're trying
to act on. Then we can trigger the above to see if the new mail is part
of the thread of interest.

(This seems like the sort of thing `formail` could do, given its `-D`
option has a message ID cache, but I haven't even bothered to take a
look at how hard that would be...)

# `procmail` usage

In `.procmailrc`, we'd use this like so:

```
:0 Wfh: formail.lock
| $HOME/src/procmail-thread/match-thread.sh $HOME/.refs.muted "Procmail-Muted: true"

:0 Wfh: formail.lock
| $HOME/src/procmail-thread/match-thread.sh $HOME/.refs.watched "Procmail-Watched: true"
```

This will add the given header if we find any of the email's
`References` values in our "database".

Then, we can do what we like with the mails, like deliver them as
already-read, carbon copy them to the inbox, etc.:

```
:0
* Procmail-Muted: true
{
        SWITCHRC=$HOME/.procmailrc.markread
}

:0
* Procmail-Watched: true
{
        :0 c:
        $DEFAULT

        SWITCHRC=$HOME/.procmailrc.markread
}

:0
$DEST/
```

# `mutt` usage

To actually watch or mute a thread, we add a couple of `mutt` macros:

```
macro index,pager "M" "|~/src/procmail-thread/add-thread.sh ~/.refs.muted<return>"
macro index,pager "W" "|~/src/procmail-thread/add-thread.sh ~/.refs.watched<return>"
```

The `add-thread.sh` script is similar to the above, but populates the
refs file with all message IDs found in the given email.

I put all this in [a git repo](https://github.com/jlevon/procmail-thread).
