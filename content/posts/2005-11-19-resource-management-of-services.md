+++
author = "levon"
published = 2005-11-19T20:00:36.000Z
slug = "2005-11-19-resource-management-of-services"
categories = ["old-sun-blog"]
title = "Resource management of services"
+++
SMF introduced the notion of a service as a first-order object in the Solaris OS. Thus, you have
administration interfaces capable of dealing with services (as opposed to the implicit service
represented by a set of processes, for example). It doesn't seem very well known, but as
<a href="http://cuddletech.com/blog/pivot/entry.php?id=403#comm">Stephen Hahn mentions</a>, this
also applies to the resource management facilities of Solaris.
</p>
<p>
A service can be bound to a project (as well as a resource pool, which I won't go into here). This
allows us to add resource controls to the project which will apply to the service as a whole, which
is significantly more reliable and usable than trying to deal with individual daemons etc. Unfortunately,
it's not as obvious to set up as it should be (of which more later), so here's a simple walkthrough.
</p>
<p>
We're going to set up a simple 'forkbomb' service, which simply runs this program:
</p>
<pre>
#include &lt;unistd.h&gt;
#include &lt;stdlib.h&gt;

int main()
{
        int first = 1;
        while (1) {
                if (fork() &gt; 0 &amp;&amp; first)
                        exit(0);
                first = 0;
        }
}
</pre>
<p>
If you try running this program in an environment
lacking resource controls, don't expect to be able to do much to your box except reboot it.
Note the first parent does an <tt>exit(0)</tt> so that SMF doesn't think the service has failed
(since we'll be a standard contract service). Here's the SMF manifest for our service:
</p>
<pre>
&lt;?xml version="1.0"?&gt;
&lt;!DOCTYPE service_bundle SYSTEM "/usr/share/lib/xml/dtd/service_bundle.dtd.1"&gt;
&lt;service_bundle type='manifest' name='forkbomb'&gt;
&lt;service name='application/forkbomb' type='service' version='1'&gt;
        &lt;exec_method
            type='method'
            name='start'
            exec='/opt/forkbomb/bin/forkbomb'
            timeout_seconds='10'&gt;
                &lt;method_context project='forkbomb'&gt;
                        &lt;method_credential user='root' /&gt;
                &lt;/method_context&gt;
        &lt;/exec_method&gt;

        &lt;exec_method
            type='method'
            name='stop'
            exec=':kill'
            timeout_seconds='10'&gt;
      
        &lt;instance name='default' enabled='false' /&gt;
&lt;/service&gt;
&lt;/service_bundle&gt;
</pre>
<p>
Note that as well as setting the project in the method context, we've set a method credential;
this is a workaround for a problem I'll come to later. Now we need to create the 'forkbomb'
project for the service:
</p>
<pre>
# projadd -K 'project.max-lwps=(privileged,100,deny)' forkbomb
</pre>
<p>
Alternatively we could create a new user for the service to use, set the method credential to use
that user, then change our 'forkbomb' project to allow the user to join it. It's important to note
that this still works even for root, though, so that's what we've done here.
</p>
<p>
Finally, we can import the manifest as a service, then temporarily enable it (so it won't start
next time we boot!):
</p>
<pre>
# svccfg import /opt/forkbomb/manifest/forkbomb.xml
# svcadm enable -t forkbomb
</pre>
<p>
The forkbomb is now running flat out, but under the constraints of the resource controls we set
on its project. Thus we still have a running system, and have enough resources to disable our
'mis-behaving' service. Let's have a look at prstat:
</p>
<pre>
Total: 148 processes, 266 lwps, load averages: 68.06, 20.50, 10.75
   PID USERNAME  SIZE   RSS STATE  PRI NICE      TIME  CPU PROCESS/NLWP
 21145 root      992K  244K run      1    0   0:00:03 1.4% forkbomb/1
 21132 root      992K  244K run     49    0   0:00:03 1.2% forkbomb/1
 21128 root      992K  244K run     31    0   0:00:03 1.1% forkbomb/1
 21113 root      992K  244K run     31    0   0:00:03 1.1% forkbomb/1
 21176 root      992K  244K run     33    0   0:00:03 1.1% forkbomb/1
 21124 root      992K  244K run     53    0   0:00:03 1.1% forkbomb/1
 21119 root      992K  244K run     52    0   0:00:03 1.1% forkbomb/1
 21156 root      992K  244K run     53    0   0:00:03 1.0% forkbomb/1
 21088 root      992K  244K run     52    0   0:00:03 1.0% forkbomb/1
 21136 root      992K  244K run     43    0   0:00:03 1.0% forkbomb/1
 21133 root      992K  244K run     44    0   0:00:03 1.0% forkbomb/1
 21097 root      992K  244K run     52    0   0:00:03 1.0% forkbomb/1
 21103 root      992K  244K run     56    0   0:00:03 1.0% forkbomb/1
 21092 root      992K  244K run     52    0   0:00:03 1.0% forkbomb/1
 21183 root      992K  244K run     53    0   0:00:03 1.0% forkbomb/1
PROJID    NPROC  SIZE   RSS MEMORY      TIME  CPU PROJECT
   100      100   97M   24M   0.6%   0:04:47  95% forkbomb
     1        5   11M 8268K   0.3%   0:00:00 0.0% user.root
    10        3   18M 8060K   0.3%   0:00:00 0.0% group.staff
     0       40  135M   83M   2.6%   0:00:17 0.0% system
Total: 148 processes, 266 lwps, load averages: 70.60, 21.80, 11.24
</pre>
<p>
As we might expect, there's a high system load (since our fork-bomb is ignoring the
errors from <tt>fork()</tt> when it hits its resource limit). Note that the
'forkbomb' project has been clamped to a maximum of 100 LWPs, as you can see in
the <tt>NPROC</tt> field. But most importantly, the
system is still usable, and we can stop the troublesome service:
</p>
<pre>
# svcadm disable forkbomb
</pre>
<p>
After a while for the stop method to finish (or time out, both of which will kill
all processes in the service contract), we're done!
</p>
<p>
I mentioned above that we needed to specify a method credential to work around a bug. This
is <a href="http://bugs.opensolaris.org/bugdatabase/view_bug.do?bug_id=5093847">bug 5093847</a>.
The way the property lookup works currently, if the <tt>use_profile</tt> property on
the service isn't found,
then none of the rest of the method context is examined. Setting the method credential has the
side-effect of creating this property, so things work properly. This bug would also be nice to
fix since we could directly set the <tt>project</tt> property via <tt>svccfg</tt> if the properties
for the method context were always created. Any interested parties are strongly encouraged to have
a go at fixing it - it's not currently being worked on, and I'd happy to help :)
</p>
<p class="tags">Tags: <a href="http://www.technorati.com/tag/OpenSolaris" rel="tag">OpenSolaris</a> <a href="http://www.technorati.com/tag/SMF" rel="tag">SMF</a>
