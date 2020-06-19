---
title: "ctags, vim and C"
date: 2020-06-19T11:07:35Z
---

Going to the first matching tag in vim with `Control-]` can be rather
annoying. The `exuberant-ctags` secondary sort key is the filename, not
the tag kind. If you have a struct type that's also a common member
name, you're forced into using `:tselect` to find the struct instead of
all the members. Most of the time, the struct definition is what you
want.

To avoid this issue, I sort the tags file such that any `kind == "s"`
entries come first for that tag. It's a little annoying due to the
format of the file, but it does work:

```bash
#!/bin/bash

# ctags, but sub-sorted such that "struct request" comes first, rather than
# members with the same name.

# we can't use "-f -", as that elides the TAG_FILE_SORTED preamble
ctags -R -f tags.$$

awk '
BEGIN {
	FS="\t"
	entry=""
	struct=""
	buf=""
}

$1 != entry {
	if (entry != "") {
		printf("%s%s", struct, buf);
	}
	entry=$1;
	struct="";
	buf="";
}

/^.*"\ts/ {
	struct=struct $0 "\n"
	next
}

$1 == entry {
	buf=buf $0 "\n"
}

END {
	printf("%s%s", struct, buf);
}' <tags.$$ >tags

rm tags.$$
```
