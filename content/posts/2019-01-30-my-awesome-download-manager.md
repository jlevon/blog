+++
published = 2019-01-30T09:33:00Z
slug = "2019-01-30-my-awesome-download-manager"
tags = []
title = "My awesome download manager"
+++
Since Liferea in more recent versions requires a download manager (it
does not attempt to deal with the constant "new" podcast downloads on
broken RSS feeds), I tried a few different ones. None of them
worked. The best of a bad bunch was uGet, but that still often got stuck
on a busy loop, forgot where to download, failed to handle duplicates
etc.

I realised that in fact the best option was this marvellous piece of
engineering:

```bash
#!/bin/bash

url="$1"

readonly LOG_FILE="/var/tmp/download.log"
touch $LOG_FILE
exec 1>>$LOG_FILE
exec 2>&1

#set -x

if grep "$1" ~/.downloaded >/dev/null; then
	echo "$(date): skipping $1"
	exit 0
fi

echo "$(date): downloading $1"

echo "$1" >>~/.downloaded

cd $my_download_dir

curl -RksSLJO "$1" 
```

Not exactly stunning but it *works*.
