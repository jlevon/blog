+++
author = "levon"
published = 2005-11-18T16:02:49.000Z
slug = "2005-11-18-reducing-ctf-overhead"
categories = ["old-sun-blog"]
title = "Reducing CTF overhead"
+++
CTF (Compact C Type Format) encapsulates a reduced form of debugging
information similar to DWARF and the venerable stabs. It describes types
(structures, unions, typedefs etc.) and function prototypes, and is carefully
designed to take a minimum of space in the ELF binaries. The kernel binaries
that Sun ship have this data embedded as an ELF section (<tt>.SUNW_ctf</tt>) so that
tools like <tt>mdb</tt> and <tt>dtrace</tt> can understand types. Of course, it would have been
possible to use existing formats such as DWARF, but they typically have a large
space overhead and are more difficult to process.
</p>
<p>
The CTF data is built from the existing stabs/DWARF data generated by the
compiler's <tt>-g</tt> option, and replaces this existing debugging information in the
output binary (<tt>ctfconvert</tt> performs this job).
</p>
<p>
For the sake of <tt>kmdb</tt> and crash dumps, the CTF data for each kernel binary is
present in the memory image of a booted kernel. This implies it's paramount
that the amount of CTF data is minimised. Since each kernel module will
have references to common types such as <tt>cpu_t</tt>, there's a lot of duplicated type
data in all the CTF sections. To help avoid this duplication, the kernel build
uses a process known rather fancifully as 'uniquification'.
</p>
<h2>Uniquification</h2>
<p>
Each type in the CTF data has an integer ID associated with it. Observe that
the main genunix kernel module has a large number of the common types I mention
above in its CTF data. We can remove the duplicate data found in other modules
by replacing the type data with references to the type data in CTF. This
process is uniquification. Consider the <tt>bmc</tt> driver. After building and
linking the bmc object, we want to add CTF for its types, but we also
uniquify against the <tt>genunix</tt> binary, like so:
</p>
<pre>
ctfmerge -L VERSION -d ../../intel/genunix/debug64/genunix -o debug64/bmc debug64/bmc_fe.o debug64/bmc_kcs.o
</pre>
<p>
This command takes the CTF data in the objects comprising <tt>bmc</tt> (previously
converted from stabs/DWARF by <tt>ctfconvert</tt>) and merges them together (removing
any shared duplicates between the two different objects). Then it passes
through this CTF data, and looks for any types that match ones in the uniqfile
(which we specified with the <tt>-d</tt> option). For each matching type (for example,
<tt>cpu_t</tt>), we replace any references to the local type definition with a reference
to <tt>genunix</tt>'s copy of the type data. Remember that type references are simply
integer IDs, so this is just a matter of changing the type ID to the one found
in <tt>genunix</tt>'s CTF. Let's use <tt>ctfdump</tt> to look at the results:
</p>
<pre>
$ ctfdump $SRC/uts/i86pc/bmc/debug64/bmc >bmc.ctf
$ ggrep -C2 bmc_kcs_send bmc.ctf
- Types ----------------------------------------------------------------------

  &lt;32769&gt; STRUCT bmc_kcs_send (3 bytes)
        fnlun type=113 off=0
        cmd type=113 off=8
        data type=5287 off=16
...
</pre>
<p>
Here we see the first member of the <tt>struct bmc_kcs_send</tt> has a type ID of 113.
Since this type ID isn't in the CTF, it must belong to our parent. We look
for our parent, then find the type ID we're looking for:
</p>
<pre>
$ grep cth_parname bmc.ctf
  cth_parname  = genunix
$ ctfdump $SRC/uts/intel/genunix/debug64/genunix >genunix.ctf
$ grep '&lt;113&gt;' genunix.ctf
  &lt;113&gt; TYPEDEF uint8_t refers to 86
</pre>
<p>
This manual process is similar to how the CTF lookup actually happens. This
uniquification process saves us a significant amount of CTF data, although it
causes us some problems, which we'll discuss next.
</p>
<h2>CTF labels and additive merges</h2>
<p>
As noted above, all our uniquified modules will have type ID's that refer to
the <tt>genunix</tt> shipped along with them. This means, of course, that if any of the
types in <tt>genunix</tt> itself changes without these modules changing too, all the
type references to <tt>genunix</tt> types will be wrong, since it works by type ID. 
So, what happens when we need to release kernel changes?
</p>
<p>
Since we obviously don't want to ship all these modules every time <tt>genunix</tt>
needs to change, we have to keep the existing type IDs in the new <tt>genunix</tt>
binary. But also, we want to have any new or changed types present and correct
too. So, instead of doing a full merge and rewriting the existing CTF data in
<tt>genunix</tt>, we perform an "additive merge". This retains the existing CTF types
(and IDs) so that references from unchanged modules still point to the right
types, and adds on new types.
</p>
<p>
To do an additive merge, we need to pass a 'withfile' to <tt>ctfmerge</tt> via its <tt>-w</tt>
option. This first takes all the CTF in the withfile and adds it into the
output CTF. Then the CTF from the objects passed to <tt>ctfmerge</tt> are uniquified
against this data. Any remaining types after uniquification are then <em>added</em>
on top of the withfile data. This preserves the existing type IDs for any
older modules that uniquified against this <tt>genunix</tt>, whilst also adding the new
types.
</p>
<p>
This 'withfile' is the previous version of <tt>genunix</tt>. When it was built the first time,
we passed <tt>-L VERSION</tt> to <tt>ctfmerge</tt>. This adds a label with the value of the
environment variable <tt>$VERSION</tt>. Typically this is something like <tt>Generic</tt>. When
we do the additive merge, we pass in a different label equal to the patch ID
of the build, and the additional types are marked with this label. For example,
on a Solaris 9 system's <tt>genunix</tt>:
</p>
<pre>
- Label Table ----------------------------------------------------------------

   5001 Generic
   5981 112233-12
...
</pre>
<p>
Labels are nothing but a mapping from a string to a particular type ID. So here
we see that the original types are numbered from 1 to 5001, and we've done an
additive merge on top with the label "112233-12", which added more types.
</p>
<h2>CTF from the <tt>ip</tt> module</h2>
<p>
The <tt>genunix</tt> module contains many common types, but the <tt>ip</tt> module also contains
a lot of types used by many kernel modules, but not found in <tt>genunix</tt>. To
further reduce the amount of CTF in these modules, we merge in the CTF data
found in <tt>ip</tt> into the genunix CTF. The modules can then uniquify against this
combined data, removing many more duplicate types. Note that we don't do this
for patch builds, as the <tt>ip</tt> module might not ship in a patch. Unfortunately
this can cause problems (notably bug 6347000, though this isn't yet
accessible from <a href="http://bugs.opensolaris.org/">opensolaris.org</a>).
</p>
<h2>Further reading</h2>

<ul>
<li><a href="http://cvs.opensolaris.org/source/xref/on/usr/src/uts/Makefile.uts#353">Makefile.uts</a></li>
<li><a href="http://cvs.opensolaris.org/source/xref/on/usr/src/tools/ctf/cvt/ctfmerge.c#30">ctfmerge.c</a></li>
<li><a href="http://opensolaris.org/os/community/mdb/">MDB community</a></li>
</ul>

<p class="tags">Tags: <a href="http://www.technorati.com/tag/OpenSolaris" rel="tag">OpenSolaris</a>
<a href="http://www.technorati.com/tag/CTF" rel="tag">CTF</a>