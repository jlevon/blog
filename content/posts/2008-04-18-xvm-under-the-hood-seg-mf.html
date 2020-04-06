+++
author = "levon"
published = 2008-04-18T14:57:01.000Z
slug = "2008-04-18-xvm-under-the-hood-seg-mf"
categories = ["old-sun-blog"]
title = "xVM Under The Hood: seg_mf"
+++
An occasional series wherein I'll describe a part of the xVM implementation. Today,
I'll be talking about <tt>seg_mf</tt>. You may want to read through
<a href="http://blogs.sun.com/levon/entry/live_migration_of_solaris_instances">my explanation of
live migration and MMU virtualization</a> first.
</p>

<p>
The control domain (dom0) often needs access to memory pages that belong to a running
guest domain. The most obvious example of this is in constructing the domain during
boot, but it's also needed for mapping the shared virtual guest console page, generating
guest domain core dumps, etc.
</p>
<p>
This is implemented via the <tt>privcmd</tt> driver. Each process that needs to map some
area of a guest domain's memory maps a range of anonymous virtual memory. The process then sends a
request to the driver to map in a given range or set of machine frames into the given virtual address
range. The two requests (<a href="http://src.opensolaris.org/source/xref/onnv/onnv-gate/usr/src/uts/i86xpv/io/privcmd.c#129"><tt>IOCTL_PRIVCMD_MMAP</tt></a>
and
<a href="http://src.opensolaris.org/source/xref/onnv/onnv-gate/usr/src/uts/i86xpv/io/privcmd.c#205">
<tt>IOCTL_PRIVCMD_MMAP_BATCH</tt></a>) are more or less the same, although the latter allows
the user to track MFNs that couldn't be mapped (see below). 
</p>
<p>
Both <tt>ioctl()</tt>s hook into the <tt>seg_mf</tt> code. This is a normal Solaris segment driver
(see Solaris Internals) with a hook that's used to store the arrays of MFN
values that each VA range is to be backed by. This segment driver is a little unusual though: it
does not support demand faulting. That is, every page in the segment is faulted in (and locked in)
at the time of the <tt>ioctl()</tt>. This is needed to support the error-reporting interface
described below, but it also helps simplify the driver significantly. 
</p>
<p>
To fault the range, we go through each page-size chunk in the mapping. We need to establish a 
mapping from the virtual address of the chunk to the actual machine frame holding the page owned
by the guest domain. This happens in <a href="http://src.opensolaris.org/source/xref/onnv/onnv-gate/usr/src/uts/i86xpv/vm/seg_mf.c#189">
<tt>segmf_faultpage()</tt></a>. The HAT isn't used to our strange request, so we load a temporary
mapping at the given VA, and replace that with a mapping to the real underlying MFN via
<tt>HYPERVISOR_update_va_mapping_otherdomain()</tt>.
</p>
<p>
Normally, the MFNs given via the <tt>ioctl()</tt> should be mappable. One exception is
HVM live migration. This was implemented, somewhat confusingly, to use the same interfaces
but pass GMFNs not MFNs. In particular, for HVM guests, a guest MFN (what a guest thinks
is a real machine frame number) is actually a pseudo-physical frame number. As a result,
due to ballooning, or PV drivers, etc., this GMFN may not have a real MFN backing it, so the
attempt to map it will fail. We mark the MFN as failed in the outgoing array of <tt>IOCTL_PRIVCMD_MMAP_BATCH</tt>
and let the client deal with it. This is generally OK, since the iterative nature of live migration
means we can still get to all the pages we need.
</p>

<p>
One nice enhancement would be to extend <tt>pmap</tt> to recognise such mappings. In particular
<tt>qemu-dm</tt> has a bunch of such mappings. It'd be relatively easy to mark such mappings as
coming from <tt>seg_mf</tt>. Extra marks for listing the MFN ranges too, though that's a little
harder :)
</p>

<p class="tags">Tags: <a href="http://www.technorati.com/tag/Xen" rel="tag">Xen</a>
<a href="http://www.technorati.com/tag/OpenSolaris" rel="tag">OpenSolaris</a>
<a href="http://www.technorati.com/tag/xVM" rel="tag">xVM</a>
