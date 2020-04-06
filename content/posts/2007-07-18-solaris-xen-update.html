+++
author = "levon"
published = 2007-07-18T23:29:07.000Z
slug = "2007-07-18-solaris-xen-update"
categories = ["old-sun-blog"]
title = "Solaris Xen update"
+++
After an undesirably long time, I'm happy to say that another drop of Solaris on Xen is 
<a href="http://www.sun.com/download/products.xml?id=4691b249">available here</a>.
Sources and other sundry parts are <a href="http://dlc.sun.com/osol/xen/downloads/20070712/">here</a>.
Documentation can
be found at our <a href="http://www.opensolaris.org/os/community/xen/docs/">community site</a>, and
you can read 
<a href="http://blogs.sun.com/cwb/entry/starting_out_with_solaris_on">Chris Beal</a> describe how to
get started with the new bits.
</p>
<p>
As you might expect, there's been a massive amount of change
since the last OpenSolaris release.
This time round, we are based on Xen 3.0.4 and build 66 of Nevada. As always, we'd love to hear about
your experiences if you try it out, either on the <a href="http://mail.opensolaris.org/mailman/listinfo/xen-discuss">mailing list</a> or the <a href="irc://irc.oftc.net/solaris-xen">IRC channel</a>.
</p>
<p>
In many ways, the most significant change is the huge effort we've put in to stabilize our codebase; a
significant number of potential hangs, crashes, and core dumps have been resolved, and we hope we're
converging on a good-quality release. We've started looking seriously at performance issues, and filling
in the implementation gaps. Since the last drop, notable improvements include:
</p>
<dl>
<dt>PAE support</dt>
<dd>
By default, we now use PAE mode on 32-bit, aiding compatibility with other domain 0 implementations; we also
can boot under either PAE or non-PAE, if the Xen version has 'bi-modal' support. This has probably been the
most-requested change missing from our last release.
</dd>

<dt>HVM support</dt>
<dd>
If you have the right CPU, you can now run fully-virtualized domains such as Windows using a Solaris dom0! Whilst
more work is needed here, this does seem to work pretty well already. Mark Johnson has some <a href="http://blogs.sun.com/mrj/entry/the_latest_solaris_on_xen">useful tips on using HVM domains</a>.
</dd>

<dt>New management tools</dt>
<dd>
We have integrated the virt- suite of management tools. <a href="http://virt-manager.org/">virt-manager</a> provides
a simple GUI for controlling guest domains on a single host. <tt>virt-install</tt> and <tt>virsh</tt> are simple CLIs
for installing and managing guest domains respectively. Note that parts of these tools are pre-alpha, and we still
have a significant amount of work to do on them. Nonetheless, we appreciate any comments...
</dd>

<dt>PV framebuffer</dt>
<dd>
Solaris dom0 now supports the SDL-based paravirt framebuffer backend, which can be used with domUs that have PV framebuffer support.
</dd>

<dt>Virtual NIC support</dt>
<dd>
The Ethernet bridge used in the previous release has been replaced with virtual NICs from the 
<a href="http://www.opensolaris.org/os/project/crossbow/">Crossbow project</a>. This enables future work
around smart NICs, resource controls, and more.
</dd>

<dt>Simplified Solaris guest domain install</dt>
<dd>
It's now easy to install a new Solaris guest domain using the DVD ISO. The temporary tool in the last release,
<tt>vbdcfg</tt>, has disappeared now as a result. William Kucharski has a <a href="http://blogs.sun.com/kucharsk/entry/the_xen_of_domu_installation">walk-through</a>.
</dd> 

<dt>Better SMF usage</dt>
<dd>
Several of the xend configuration properties are now controlled using the SMF framework.
</dd>

<dt>Managed domain support</dt>
<dd>
We now support xend-managed domain configurations instead of using <tt>.py</tt> configuration files. Certain
parts of this don't work too well yet (unfortunately all versions of Xen have similar problems), but we are
plugging in the gaps here one by one.
</dd>

<dt>Memory ballooning support</dt>
<dd>Otherwise known as support for dynamic <tt>xm mem-set</tt>, this allows much greater flexibility in partitioning
the physical memory on a host amongst the guest domains. Ryan Scott has <a href="http://blogs.sun.com/rscott/entry/changing_a_domain_s_memory">more details</a>.
</dd>

<dt>Vastly improved debugging support</dt>
<dd>
Crash dump analysis and debugging tools have always been a critical feature for Solaris developers. With this release,
we can use Solaris tools to debug both hypervisor crashes and problems with guest domains. I talk a little bit about
the latter feature below.
</dd>

<dt><tt>xvbdb</tt> has been renamed</dt>
<dd>
To simply be <tt>xdb</tt>. This was a very exciting change for certain members of our team.
</dd>

</dl>

<p>
We're still working hard on finishing things up for our phase 2 putback into Nevada (where "phase 1"
was the separate <a href="http://blogs.sun.com/JoeBonasera/entry/opensolaris_on_xen">dboot</a> putback). As well as
finishing this work, we're starting to look at further enhancements, in particular some features that are available
in other vendors' implementations, such as a hypervisor-copy based networking device, blktap support, 
para-virtualized drivers for HVM domains (a huge performance fix), and more.
</p>

<h3>Debugging guest domains</h3>
<p>
Here I'll talk a little about one of the more minor new features that has nonetheless proven very useful.
The <tt>xm dump-core</tt> command generates an image file of a running domain. This file is a dump of all
memory owned by the running domain, so it's somewhat similar to the standard Solaris crash dump files.
However, <tt>dump-core</tt> does <em>not</em> require any interaction with the domain itself, so we can grab
such dumps even if the domain is unable to create a crash dump via the normal method (typically, it hangs
and can't be interacted with), or something else prevents use of the standard Solaris kernel debugging facilities
such as <tt>kmdb</tt> (an in-kernel debugger isn't very useful if the console is broken).
</p>
<p>
However, this also means that we have no control over the format used by the image file. With Xen 3.0.4,
it's rather basic and difficult to work with. This is much improved in Xen 3.1, but I haven't yet written
the support for the new format.
</p>
<p>
To add support for debugging such image files of a Solaris domain, I modified mdb(1) to understand the format
of the image file (the alternative, providing a conversion step, seemed unneccessarily awkward, and would have had to
throw away information!). As you can see if you look around <tt>usr/src/cmd/mdb</tt> in the source drop,
mdb(1) loads a module called <tt>mdb_kb</tt> when debugging such image files. This provides simple methods for
reading data from the image file. For example, to read a particular virtual address, we need to use the contents of
the domain's page tables in the image file to resolve it to a physical page, then look up the location of that page
in the file. This differs considerably from how <tt>libkvm</tt> works with Solaris crash dumps: there, we have a
big array of address translations, which is used directly, instead of the page table contents.
<p>
In most other respects, debugging a kernel domain image is much the same as a crash dump:
</p>
<pre>
# xm dump-core solaris-domu core.domu
# mdb core.domu
mdb: warning: dump is from SunOS 5.11 onnv-johnlev; dcmds and macros may not match kernel implementation
Loading modules: [ unix genunix specfs dtrace xpv_psm scsi_vhci ufs ... sppp ptm crypto md fcip logindmux nfs ]
> ::status
debugging domain crash dump core.domu (64-bit) from sxc16
operating system: 5.11 onnv-johnlev (i86pc)
> ::cpuinfo
 ID ADDR             FLG NRUN BSPL PRI RNRN KRNRN SWITCH THREAD           PROC
  0 fffffffffbc4b7f0  1b   40    9 169  yes   yes t-1408926 ffffff00010bfc80 sched
> ::evtchns
Type          Evtchn IRQ IPL CPU ISR(s)
evtchn        1      257 1   0   xenbus_intr
evtchn        2      260 9   0   xenconsintr
virq:debug    3      256 15  0   xen_debug_handler
virq:timer    4      258 14  0   cbe_fire
evtchn        5      259 5   0   xdf_intr
evtchn        6      261 6   0   xnf_intr
evtchn        7      262 6   0   xnf_intr
> ::cpustack -c 0
cbe_fire+0x5c()
av_dispatch_autovect+0x8c(102)
dispatch_hilevel+0x1f(102, 0)
switch_sp_and_call+0x13()
do_interrupt+0x11d(ffffff00010bfaf0, fffffffffbc86f98)
xen_callback_handler+0x42b(ffffff00010bfaf0, fffffffffbc86f98)
xen_callback+0x194()
av_dispatch_softvect+0x79(a)
dispatch_softint+0x38(9, 0)
switch_sp_and_call+0x13()
dosoftint+0x59(ffffff0001593520)
do_interrupt+0x140(ffffff0001593520, fffffffffbc86048)
xen_callback_handler+0x42b(ffffff0001593520, fffffffffbc86048)
xen_callback+0x194()
sti+0x86()
_sys_rtt_ints_disabled+8()
intr_restore+0xf1()
disp_lock_exit+0x78(fffffffffbd1b358)
turnstile_wakeup+0x16e(fffffffec33a64d8, 0, 1, 0)
mutex_vector_exit+0x6a(fffffffec13b7ad0)
xenconswput+0x64(fffffffec42cb658, fffffffecd6935a0)
putnext+0x2f1(fffffffec42cb3b0, fffffffecd6935a0)
ldtermrmsg+0x235(fffffffec42cb2b8, fffffffec3480300)
ldtermrput+0x43c(fffffffec42cb2b8, fffffffec3480300)
putnext+0x2f1(fffffffec42cb560, fffffffec3480300)
xenconsrsrv+0x32(fffffffec42cb560)
runservice+0x59(fffffffec42cb560)
queue_service+0x57(fffffffec42cb560)
stream_service+0xdc(fffffffec42d87b0)
taskq_d_thread+0xc6(fffffffec46ac8d0)
thread_start+8()
</pre>

<p>
Note that both <tt>::cpustack</tt> and <tt>::cpuregs</tt> are capable of using the actual register set at
the time of the dump (since the hypervisor needs to store this for scheduling purposes). You can also
see the <tt>::evtchns</tt> dcmd in action here; this is invaluable for debugging interrupt problems (and
we've fixed a <em>lot</em> of those over the past year or so!).
</p>
<p>
Currently, <tt>mdb_kb</tt> only has support for image files of para-virtualized Solaris domains. However,
that's not the only interesting target: in particular, we could support mdb in live
crash dump mode against a running Solaris domain, which opens up all sorts of interesting debugging
possibilities. With a small tweak to Solaris, we can support debugging of fully-virtualized Solaris instances.
It's not even impossible to imagine adding Linux kernel support to mdb(1), though it's hard to imagine there
would be a large audience for such a feature...
</p>

<p class="tags">Tags: <a href="http://www.technorati.com/tag/Xen" rel="tag">Xen</a> <a href="http://www.technorati.com/tag/OpenSolaris" rel="tag">OpenSolaris</a>
