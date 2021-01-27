+++
published = 2019-10-22T22:32:00.001000+01:00
slug = "2019-10-22-open-all-links-in-gerrit"
tags = []
title = "Open all links in Gerrit"
+++
Newer versions of Gerrit, somewhat insanely, lack the old "Open All"
button to open each file in its own tab. Here's a bookmarklet that does
so:

```js
javascript: (
  function() {
    var n_to_open = 0;
    // just this for older gerrit versions
    var dl = document.querySelectorAll(".pathLink");
    // or more current
    var dl = document.querySelector('body > gr-app')
      .shadowRoot.querySelector('gr-app-element')
      .shadowRoot.querySelector('gr-change-view')
      .shadowRoot.querySelector('gr-file-list')
      .shadowRoot.querySelectorAll('.pathLink');

    var dll = dl.length;
    if (!dll) {
      alert('no links');
    } else {
      if (confirm('Open ' + dll + ' links in new windows?')) {
        for (var i = 0; i < dll; ++i) {
          window.open(dl[i].href);
        }
      }
    }
  }
)();
```

(Add the above as the "Location" of a bookmark.) If somebody knows a
less shitty way to traverse all the new shadow roots, I'd love to hear
it.

2021-01-27: updated to fix a javascript error
