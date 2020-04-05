+++
author = "John Levon"
published = 2018-02-26T11:32:00Z
slug = "2018-02-26-pcid-support-on-illumos"
tags = []
title = "PCID support on Illumos"
+++
I joined Joyent at the start of the year while Meltdown was breaking
news; it was certainly an "interesting" time to start a new job. Luckily
by my first week, Alex and Robert had pretty much figured out how the
changes should look and made good inroads on the implementation. So I
began working with Alex on his KPTI trampoline code (mainly involving
breaking it with my old friend KMDB). I also picked up the PCID work
which I describe here.

As you can probably tell from [Alex's blog
post](https://blog.cooperi.net/a-long-two-months), Meltdown is unusual
for a security issue: aside from the usual operational pains of any
security patch, the fix itself involved some pretty significant code
changes to the low-level core of the kernel.

There's also another potential impact, and that's performance. While the
actual overhead is heavily workload-dependent - and some of the reports
out there seem pretty alarmist - having to switch page tables (i.e.
reloading `%cr3`) on every kernel entry and exit has a non-trivial
impact on system call cost. Nor can we keep the kernel state in the TLB.
Previously, we would set `PT_GLOBAL` on kernel mappings so they're not
flushed across a `%cr3` reload, but as the CPU would happily use these
TLB entries to speculate into the kernel, we must flush them.

The good news is that there's a CPU feature on reasonably recent Intel
CPUs called Process Context IDs. This lets you load the lower bits of
`%cr3` with a small integer value. This ID is used as a tag in any TLB
lookups or fills. This feature is somewhat similar to ASIDs seen on
other architectures, with one notable difference. The PCID applies to
TLB state implicitly, that is, there's no way to say "load from memory
using this ID" in `ddi_copyin()` and the like.

One way of using PCIDs is to associate an ID with a `struct as`: that
is, each time we load a process's address space into the HAT, we will
use a specific PCID for it, and avoid having to flush the mappings for
the previous processes. This isn't really a viable option for Illumos,
though: if nothing else we suspect that the additional shootdown flushes
needed (since we'd maintain TLB entries even after switching away from a
process's `struct as`) would counteract any performance gain.

Instead we define two fixed PCID values. `PCID_KERNEL`, defined as `0`
mainly to keep the boot process simple, is used for the kernel `%cr3`.
Thus, all TLB loads while in the kernel will be tagged with this value.
`PCID_USER` is used when in userspace. Now, when we switch `%cr3` on
kernel entry or exit, we can do a non-flushing load. This lets us keep
both the kernel and the userspace mappings around across kernel/user
transitions.

When we *do* need to invalidate TLB entries, though, things are now
slightly more complicated. We are by definition in the kernel (and hence
using `PCID_KERNEL`), but we have to account for memory addresses below
`USERLIMIT`. In this case, we have to flush both `PCID_USER` (for
anything that ran in user mode) and `PCID_KERNEL` (for any accesses the
kernel may have made such as with `ddi_copyin()`). `hat_switch()` is
also a little more complicated. As the `%cr3` load there is
non-invalidating, we have to explicitly flush everything if we're
switching away from a non-`kas` HAT, to clear out now-stale user-space
mappings. (Note that this has always been done eagerly on Illumos, even
when switching to a `kas` HAT).

The `INVPCID` instruction is what enable us to flush `PCID_USER` while
in the kernel. Unfortunately, support for `INVPCID` came quite some time
after `PCID` itself. On such systems, we have to emulate, and the only
way Intel gives us to do this is to load the ID into `%cr3` before
invalidating the TLB entries. We don't want to "pollute" `PCID_USER`
with any extraneous kernel mappings, so this means we need to switch to
the user page tables when loading `PCID_USER`. But, remember, KPTI
requires us not to have kernel text (or stack!) mapped into these page
tables. So we have to first make sure we're in the trampoline text
before doing the invalidations: see `tr_mmu_flush_user_range`.

For those interested, Alex posted a [draft
webrev](https://us-east.manta.joyent.com/arekinath/public/webrevs/kpti-20180222/pcid/index.html)
of the PCID changes.
