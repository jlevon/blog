+++
author = "levon"
published = 2008-07-29T22:28:27.000Z
slug = "2008-07-29-direct-mounting-of-files"
categories = ["old-sun-blog"]
title = "Direct mounting of files"
+++
As part of my work on <a href="http://opensolaris.org/jive/thread.jspa?threadID=58816&amp;tstart=30">Least
Privilege for xVM</a>, I worked on implementing <a href="http://mail.opensolaris.org/pipermail/opensolaris-arc/2008-April/008462.html">direct file mounts</a>. The idea is that we'd modify the Solaris support in <tt>virt-install</tt>
to use these direct mounts, instead of the more laborious older method required.
</p>
<p>
A long-standing peeve of Solaris users is that in order to mount a file system image (in particular a DVD ISO image),
it's a two-step process. This was less than ideal, as many other UNIX OS's made it simple to do: you'd just pass
the file to the <tt>mount</tt> command, along with a special option or two, and it mounts it directly.
</p>
<p>
With my putback of <a href="http://bugs.opensolaris.org/bugdatabase/view_bug.do?bug_id=6384817">6384817 Need persistent lofi based mounts and direct <tt>mount(1m)</tt> support for lofi</a>, this is now possible (in fact, a little easier) in Solaris.
Instead of doing this:
</p>
<pre>
# device=`lofiadm -a /export/solarisdvd.iso`
# mount -F hsfs $device /mnt/iso
...
# umount /mnt/iso
# lofiadm -d /export/solarisdvd.iso
</pre>
<p>
it's just:
</p>
<pre>
# mount -F hsfs /export/solarisdvd.iso /mnt/iso
...
# umount /export/solarisdvd.iso
</pre>

<p>
Under the hood, this still uses the <tt>lofi</tt> driver, it's just automatically used at <tt>mount</tt> and <tt>unmount</tt> time. There's no need for an <tt>-o loop</tt> option as on Linux.
</p>
<p>
This is supported for most of the file systems you might need in Solaris, namely ufs, hsfs, udfs, and pcfs. This
doesn't work for ZFS, as this has its <a href="http://mail.opensolaris.org/pipermail/opensolaris-arc/2008-April/008470.html">own method for mounting file system images</a>.
</p>
<p>
I was asked a couple of times why I implemented this in the kernel at all (which meant requiring file system support via <a href="http://src.opensolaris.org/source/xref/onnv/onnv-gate/usr/src/uts/common/fs/vfs.c#4681">vfs_get_lofi()</a>. This was primarily to allow non-root users to access file mounts; in fact this was
the primary motivation for implementing this feature from the point of view of the xVM work. In particular, if you have <a href="http://docs.sun.com/app/docs/doc/816-5175/privileges-5?l=en&amp;a=view"><tt>PRIV_SYS_MOUNT</tt></a>, you can do direct file mounts as well as normal mounts. This is important for <tt>virt-install</tt>, which we want to avoid running as root, but needs to be able to mount DVDs to grab the booting information for when installing a guest.
</p>
<p>
As always, there's more work that could be done. <tt>mount</tt> is not smart about relative paths, and should
notice (and correct) early if you try pass a relative path as the first argument. Solaris has always (rather annoyingly) required an <tt>-F</tt> option to identify what kind of file system you're mounting, which is particularly pedantic of it. Equally the <tt>lofi</tt> driver doesn't comprehend <tt>fdisk</tt> or <tt>VTOC</tt> layouts.

</p>

<p class="tags">Tags: <a href="http://www.technorati.com/tag/Xen" rel="tag">Xen</a>
<a href="http://www.technorati.com/tag/OpenSolaris" rel="tag">OpenSolaris</a>
<a href="http://www.technorati.com/tag/xVM" rel="tag">xVM</a>
