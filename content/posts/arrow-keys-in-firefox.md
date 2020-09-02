---
title: "Arrow Keys in Firefox"
date: 2020-09-02T18:01:26Z
---

I'm not the only one disappointed in the way the web has worked out
in lots of ways. From `<blink>` onwards, so much semantic information is
missing from the average website, sometimes wilfully it appears. Why is
there so little structural data on what the components of a page are?

One particular peccadillo I dislike is "Previous/Next Page" elements on
a list page. Nobody *ever* uses
[`<a rel="next" ...>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Link_types).
If you're lucky, there's an `aria-label` attribute for accessibility
purposes, but as it's a free-form text, and there isn't even a
convention, it could be pretty much anything.

For reasons unclear to me, almost no sites make use of the left/right
arrow keys for navigation. So if I want to map those keys to prev/next,
instead of a nice little bit of configuration, I have to resort to
[this user
script](https://greasyfork.org/en/scripts/410676-arrow-key-nexter):

```javascript
(function() {
    'use strict';

    /* NB: we already tested for prefix/suffix, so this RE is OK. */
    function wholeWordMatch(haystack, needle) {
        let r = new RegExp("\\s" + needle + "\\s");
        return r.test(haystack);
    };

    const LEFT_KEY_CODE = 37;
    const RIGHT_KEY_CODE = 39;

    const prevStrings = [
        "previous page",
        "previous",
        "prev"
    ];

    const nextStrings = [
        "next page",
        "next"
    ];

    document.addEventListener("keyup", function(e) {

        if (!e) {
            e = window.event;
        }

        if (e.isComposing) {
            return;
        }

        switch (e.target.tagName) {
            case "TEXTAREA":
            case "INPUT":
                return;
        }

        const key = e.keyCode ? e.keyCode : e.which;

        var matches = undefined;

        if (key == LEFT_KEY_CODE) {
            matches = prevStrings;
        } else if (key == RIGHT_KEY_CODE) {
            matches = nextStrings;
        } else {
            return;
        }

        let found = undefined;
        let score = 0;

        document.querySelectorAll("a").forEach((link) => {
            let strs = [ link.textContent ];

            if (!link.href) {
                return;
            }

            /* This is often a good match if the text itself isn't. */
            if (link.attributes["aria-label"]) {
                strs.push(link.attributes["aria-label"].nodeValue);
            }

            for (let str of strs) {
                if (typeof str === "undefined") {
                    return;
                }

                str = str.toLowerCase();

                /*
                 * There's no perfect way to find the "best" link, but in
                 * practice this works on a reasonable number of sites: an exact
                 * match, or exact prefix or suffix, always wins; otherwise, we
                 * match a whole-word sub-string: "Go to prev <<" will match,
                 * but not "dpreview.com".
                 */
                for (let match of matches) {
                    if (str === match) {
                        found = link;
                        break;
                    }

                    if (str.startsWith(match) || str.endsWith(match)) {
                        found = link;
                        break;
                    }

                    if (score < 1 && wholeWordMatch(str, match)) {
                        found = link;
                        score = 1;
                    }
                }
            }
        });

        if (found) {
            found.click();
        }

  }, true);
})();
```

Yet again, hacky, but it mostly works. It's pretty cool that this is
even possible though.
