+++
author = "levon"
published = 2008-12-10T14:24:00.000Z
slug = "2008-12-10-opensolaris-2008-11-as-a-para-virtual-xen-guest"
categories = ["old-sun-blog"]
title = "OpenSolaris 2008.11 as a para-virtual Xen guest"
+++
<b>UPDATE</b>: the canonical location for this information is now <a href="http://opensolaris.org/os/community/xen/docs/opensolaris_domu/">here</a> - please check there, as it will be updated as necessary, unlike this blog entry.
</p>
<p>
As well obviously working with <a href="http://www.virtualbox.org">VirtualBox</a>, OpenSolaris can also run
as a guest domain under Xen. The installation CD ships with the paravirtual extensions so you can
run it as a fully para-virtualized guest. This provides a significant advantage over fully-virtualized guests,
or even guests with para-virtual drivers like Solaris 10 Update 6. Of course, if you choose to, you can
still run OpenSolaris fully-virtualized (a.k.a. HVM mode), but there's little advantage to doing so.
</p>
<p>
One slight wrinkle is that Solaris guests don't yet implement the <a href="http://bugs.opensolaris.org/bugdatabase/view_bug.do?bug_id=6634617">virtual framebuffer</a> that the Xen infrastructure supports. Since OpenSolaris
doesn't yet have a text-mode install, this means that to install such a PV guest, we need a way to bring up
a graphical console.
</p>
<p>
With 2008.11, this is considerably easier. Presuming we're running a Solaris dom0 (either Nevada or OpenSolaris, of course), let's start an install of 2008.11:
</p>
<pre>
# zfs create rpool/zvol
# zfs create -V 10G rpool/zvol/domu-220-root
# virt-install --nographics --paravirt --ram 1024 --name domu-220 -f /dev/zvol/dsk/rpool/zvol/domu-220-root -l /isos/osol-2008.11.iso
</pre>
<p>
This will drop you into the console for the guest to ask you the two initial questions. Since they're not really important in this circumstance, you can just choose the defaults.
This example presumes that you have a DHCP server set up to give out dynamic addresses. If you only hand out addresses statically based on MAC address, you can also specify the <tt>--mac</tt> option. As OpenSolaris more-or-less assumes DHCP, it's recommended to set one up.
</p>
<p>
Now we need a graphical console in order to interact with the OpenSolaris installer. If the guest domain successfully finished booting the live CD, a VNC server should be running. It has recorded the details of this server in XenStore.
This is essentially a name/value config database used for communicating between guest domains and the control domain (dom0). We can start a VNC session as follows:
</p>
<pre>
# domid=`virsh domid domu-220`
# ip=`/usr/lib/xen/bin/xenstore-read /local/domain/$domid/ipaddr/0`
# port=`/usr/lib/xen/bin/xenstore-read /local/domain/$domid/guest/vnc/port`
# /usr/lib/xen/bin/xenstore-read /local/domain/$domid/guest/vnc/passwd
DJP9tYDZ
# vncviewer $ip:$port
</pre>

<p>
At the VNC password prompt, enter the given password, and this should bring up a VNC session, and you can merrily install away.
</p>

<h2>Implementation</h2>

<p>
The live CD runs a transient SMF service <tt>system/xvm/vnc-config</tt>. If it finds itself running on a live CD,
it will generate a random VNC password, configure <tt>application/x11/x11-server</tt> to start <tt>Xvnc</tt>, and
write the values above to XenStore. When <tt>application/graphical-login/gdm</tt> starts, it will read these service
properties and start up the VNC server. The service <tt>system/xvm/ipagent</tt> tracks the IPv4 address given to the first running interface and writes it to XenStore.
</p>
<p>
By default, the VNC server is configured not to run post-installation due to security concerns. This can be changed though, as follows:
</p>
<pre>
# svccfg -s x11-server
setprop options/xvm_vnc = "true"
</pre>

<p>
Please remember that VNC is not secure. Since you need elevated privileges to read the VNC password from XenStore,
that's sufficiently protected, as long as you always run the VNC viewer locally on the dom0, or via SSH tunnelling or
some other secure method.
</p>

<p>
Note that this works even with a Linux dom0, although you can't yet use <tt>virt-install</tt>, as the upstream version
doesn't yet "know about" OpenSolaris (more on this later).
</p>

<p class="tags">Tags: <a href="http://www.technorati.com/tag/OpenSolaris" rel="tag">OpenSolaris</a>
<a href="http://www.technorati.com/tag/Xen" rel="tag">Xen</a>
<a href="http://www.technorati.com/tag/xVM" rel="tag">xVM</a>
