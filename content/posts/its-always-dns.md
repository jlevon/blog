---
title: "It's Always DNS"
date: 2024-06-23T15:15:40Z
---

The meme is real, but I think this particular case is sort of interesting,
because it turned out, ultimately, to not be due to DNS *configuration*, but an
honest-to-goodness bug in `glibc`.

As [previously
mentioned](https://movementarian.org/blog/posts/a-headless-office-365-proxy/), I
heavily rely on [email-oauth2-proxy](https://github.com/simonrob/email-oauth2-proxy/) for my work
email. Every now and then, I'd see a failure like this:

```
Email OAuth 2.0 Proxy: Caught network error in IMAP server at [::]:1993 (unsecured) proxying outlook.office365.com:993 (SSL/TLS) - is there a network connection? Error type <class 'socket.gaierror'> with message: [Errno -2] Name or service not known
```

This always coincided with a change in my network, but - and this is the issue -
the app never recovered. Even though other processes - even Python ones - could
happily resolve `outlook.office365.com` - this long-running daemon remained
stuck, until it was restarted.

A bug in the proxy?
-------------------

My first suspect here was this bit of code:

```
1761     def create_socket(self, socket_family=socket.AF_UNSPEC, socket_type=socket.SOCK_STREAM):
1762         # connect to whichever resolved IPv4 or IPv6 address is returned first by the system
1763         for a in socket.getaddrinfo(self.server_address[0], self.server_address[1], socket_family, socket.SOCK_STREAM):
1764             super().create_socket(a[0], socket.SOCK_STREAM)
1765             return
```

We're looping across the gai results, but returning after the first one, and
there's no attempt to account for the first address result being unreachable,
but later ones being fine.

Makes no sense, right? My guess was that somehow `getaddrinfo()` was returning
IPv6 results first in this list, as at the time, the IPv6 configuration on the
host was a little wonky. Perhaps I needed to tweak
[gai.conf](https://man7.org/linux/man-pages/man5/gai.conf.5.html) ?

However, while [this was a proxy bug](https://github.com/simonrob/email-oauth2-proxy/commit/1686f09831524d389b2f141b2ea718208ce4a0b0),
it was *not* the cause of my issue.

DNS caching?
------------

Perhaps, then, this is a local DNS cache issue? Other processes work OK, even
Python test programs, so it didn't seem likely to be the system-level resolver
caching stale results. Python itself [doesn't seem to cache
results](https://github.com/python/cpython/blob/3b7fe117fab91371f6b621e9efd02f3925f5d53b/Modules/socketmodule.c#L6671).

This case triggered (sometimes) when my VPN connection died. The `openconnect`
`vpnc` script had correctly updated `/etc/resolv.conf` back
to the original configuration, and as there's no caching in the way, then the
overall system state looked correct. But somehow, this process still had wonky
DNS?

A live reproduction
-------------------

I was not going to get any further until I had a live reproduction *and*
the spare time to investigate it before restarting the proxy.

The running proxy in this state could be triggered easily by waking up
`fetchmail`, which made it much easier to investigate what was happening each
time.

So what was the proxy doing on line :1763 above? Here's an `strace` snippet:

```
[pid  1552] socket(AF_INET, SOCK_DGRAM|SOCK_CLOEXEC|SOCK_NONBLOCK, IPPROTO_IP) = 7
[pid  1552] setsockopt(7, SOL_IP, IP_RECVERR, [1], 4) = 0
[pid  1552] connect(7, {sa_family=AF_INET, sin_port=htons(53), sin_addr=inet_addr("ELIDED")}, 16) = 0
[pid  1552] poll([{fd=7, events=POLLOUT}], 1, 0) = 1 ([{fd=7, revents=POLLOUT}])
[pid  1552] sendto(7, "\250\227\1 \0\1\0\0\0\0\0\1\7outlook\toffice365\3c"..., 50, MSG_NOSIGNAL, NULL, 0) = 50
[pid  1552] poll([{fd=7, events=POLLIN}], 1, 5000) = 1 ([{fd=7, revents=POLLERR}])
[pid  1552] close(7)                    = 0
```

As we might expect, we're opening a socket, connecting over UDP to port 53,
and sending out a request to the DNS server.

This indicated the proximal issue: the DNS server IP address was wrong - the
DNS servers used were the ones originally set up by `openconnect` still. The
process wasn't incorrectly caching DNS *results* but the DNS *servers*. Forever.

Nameserver configuration itself is not something that applications typically
control, so the next question was - how does this work normally? When I update
`/etc/resolv.conf`, or the thousand other ways to configure name resolution in
modern Linux systems, what makes `getaddrinfo()` continue to work, normally?

/etc/resolv.conf and glibc
--------------------------

So, how does `glibc` account for changes in resolver configuration?

The contents of the `/etc/resolv.conf` file are the canonical location for
DNS server addresses for processes (like Python ones) using the standard `glibc`
resolver. Logically then, there must be a way for updates to the file to affect
running processes.

In `glibc`, such configuration is represented by `struct resolv_context`. This
is lazily initialized via `__resolv_context_get()->maybe_init()`, which [looks
like
this](https://github.com/bminor/glibc/blob/5aa2f79691ca6a40a59dfd4a2d6f7baff6917eb7/resolv/resolv_context.c#L71):

```
 68 /* Initialize *RESP if RES_INIT is not yet set in RESP->options, or if
 69    res_init in some other thread requested re-initializing.  */
 70 static __attribute__ ((warn_unused_result)) bool
 71 maybe_init (struct resolv_context *ctx, bool preinit)
 72 {
 73   struct __res_state *resp = ctx->resp;
 74   if (resp->options & RES_INIT)
 75     {
 76       if (resp->options & RES_NORELOAD)
 77         /* Configuration reloading was explicitly disabled.  */
 78         return true;
 79
 80       /* If there is no associated resolv_conf object despite the
 81          initialization, something modified *ctx->resp.  Do not
 82          override those changes.  */
 83       if (ctx->conf != NULL && replicated_configuration_matches (ctx))
 84         {
 85           struct resolv_conf *current = __resolv_conf_get_current ();
 86           if (current == NULL)
 87             return false;
 88
 89           /* Check if the configuration changed.  */
 90           if (current != ctx->conf)
...
```

Let's take a look at `__resolv_conf_get_current()`:

```
123 struct resolv_conf *
124 __resolv_conf_get_current (void)
125 {
126   struct file_change_detection initial;
127   if (!__file_change_detection_for_path (&initial, _PATH_RESCONF))
128     return NULL;
129
130   struct resolv_conf_global *global_copy = get_locked_global ();
131   if (global_copy == NULL)
132     return NULL;
133   struct resolv_conf *conf;
134   if (global_copy->conf_current != NULL
135       && __file_is_unchanged (&initial, &global_copy->file_resolve_conf))
```

This is the file change detection code we're looking for: `_PATH_RESCONF` is
`/etc/resolv.conf`, and `__file_is_unchanged()` compares the cached values of
things like the file `mtime` and so on against the one on disk.

If it has in fact changed, then `maybe_init()` is supposed to go down the
"reload configuration" path.

Now, in my case, this wasn't happening. And the reason for this is line 83
above: the `replicated_configuration_matches()` call.

Resolution options
------------------

We already briefly mentioned
[`gai.conf`](https://man7.org/linux/man-pages/man5/gai.conf.5.html). There is
also, as the [`resolver.3` man
page](https://man7.org/linux/man-pages/man3/resolver.3.html) says, this
interface:

```
The resolver routines use configuration and state information
contained in a __res_state structure (either passed as the statep
argument, or in the global variable _res, in the case of the
older nonreentrant functions).  The only field of this structure
that is normally manipulated by the user is the options field.
```

So an application can dynamically alter options too, outside of whatever
static configuration there is. And (I think) that's why we have the
[`replicated_configuration_matches()`](https://github.com/bminor/glibc/blob/5aa2f79691ca6a40a59dfd4a2d6f7baff6917eb7/resolv/resolv_context.c#L60) check:

```
static bool
replicated_configuration_matches (const struct resolv_context *ctx)
{
  return ctx->resp->options == ctx->conf->options
    && ctx->resp->retrans == ctx->conf->retrans
    && ctx->resp->retry == ctx->conf->retry
    && ctx->resp->ndots == ctx->conf->ndots;
}
```

The idea being, if the application has explicitly diverged its options, it
doesn't want them to be reverted just because the static configuration changed.
Our Python application isn't changing anything here, so this should still
work as expected.

In fact, though, we find that it's returning `false`: the dynamic configuration
has somehow acquired the extra options `RES_SNGLKUP` and `RES_SNGLKUPREOP`.
We're now very close to the source of the problem!

A hack that bites
-----------------

So what could possibly set these flags? Turns out the `send_dg()` function
[does](https://github.com/bminor/glibc/blob/dff8da6b3e89b986bb7f6b1ec18cf65d5972e307/resolv/res_send.c#L999):

```
 999                   {
1000                     /* There are quite a few broken name servers out
1001                        there which don't handle two outstanding
1002                        requests from the same source.  There are also
1003                        broken firewall settings.  If we time out after
1004                        having received one answer switch to the mode
1005                        where we send the second request only once we
1006                        have received the first answer.  */
1007                     if (!single_request)
1008                       {
1009                         statp->options |= RES_SNGLKUP;
1010                         single_request = true;
1011                         *gotsomewhere = save_gotsomewhere;
1012                         goto retry;
1013                       }
1014                     else if (!single_request_reopen)
1015                       {
1016                         statp->options |= RES_SNGLKUPREOP;
1017                         single_request_reopen = true;
1018                         *gotsomewhere = save_gotsomewhere;
1019                         __res_iclose (statp, false);
1020                         goto retry_reopen;
1021                       }
```

Now, I don't believe the relevant nameservers have such a bug. Rather, what
seems to be happening is that when the VPN connection drops, making the servers
inaccessible, we hit this path. And these flags are treated by `maybe_init()` as
if the client application set them, and has thus diverged from the static
configuration. As the application itself has no control over these options being
set like this, this seemd like a real `glibc` bug.

The fix
-------

I originally [reported this to the list back in
March](https://inbox.sourceware.org/libc-alpha/Ze7KCkIzR5PuErba@movementarian.org/);
I was not confident in my analysis but the maintainers [confirmed the
issue](https://sourceware.org/bugzilla/show_bug.cgi?id=31476). More recently,
they [fixed
it](https://inbox.sourceware.org/libc-alpha/87ikyhqfwy.fsf@oldenburg.str.redhat.com/T/#u).
The actual fix was pretty simple: apply the workaround flags to
`statp->_flags` instead, so they don't affect the logic in `maybe_init()`.
Thanks DJ Delorie!
