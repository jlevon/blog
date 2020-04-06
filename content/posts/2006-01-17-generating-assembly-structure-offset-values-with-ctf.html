+++
author = "levon"
published = 2006-01-17T01:44:16.000Z
slug = "2006-01-17-generating-assembly-structure-offset-values-with-ctf"
categories = ["old-sun-blog"]
title = "Generating assembly structure offset values with CTF"
+++
The Solaris kernel contains a fair amount of assembly, and this often
needs to access C structures (and in particular know the size of such
structures, and the byte offsets of their members). Since the assembler
can't grok C, we need to provide constant values for it to use. This also
applies to the C library and kmdb.
</p><p>
In the kernel, the header <tt>assym.h</tt> provides these values; for example:
</p>
<pre>
#define T_STACK 0x4
#define T_SWAP  0x68
#define T_WCHAN 0x44
</pre>
<p>
These values are the byte offset of certain members into <tt>struct
_kthread</tt>. For each of the types we want to reference from assembly,
a template is provided in one of the <em>offsets.in</em> files. For the above,
we can see in <a href="http://cvs.opensolaris.org/source/xref/on/usr/src/uts/i86pc/ml/offsets.in">usr/src/uts/i86pc/ml/offsets.in</a>:
</p>
<pre>
_kthread        THREAD_SIZE
        t_pcb                   T_LABEL
        t_lock
        t_lockstat
        t_lockp
        t_lock_flush
        t_kpri_req
        t_oldspl
        t_pri
        t_pil
        t_lwp
        t_procp
        t_link
        t_state
        t_mstate
        t_preempt_lk
        t_stk                   T_STACK
        t_swap
        t_lwpchan.lc_wchan      T_WCHAN
        t_flag                  T_FLAGS
</pre>
<p>
This file contains structure names as well their members. Each
of the members listed (which do not have to be in order, nor does the list need
to be complete) cause a define to be generated; by default, an uppercase
version of the member name is used. As can be seen, this can be overridden by
specifying a <tt>#define</tt> name to be used. The <tt>THREAD_SIZE</tt> define
corresponds to the bytesize of the entire structure (it's also possible to
generate a "shift" value, which is <tt>log<sub>2</sub>(size)</tt>).
</p>
<p>
To generate the header with the right offset and size values we need, a script
is used to generate CTF data for the needed types, which then uses this data to
output the <tt>assym.h</tt> header. This is a Perl script called
<a href="http://cvs.opensolaris.org/source/xref/on/usr/src/tools/scripts/genoffsets.pl">genoffsets</a>, and the build invokes it with a command line akin
to:
</p><pre>
genoffsets -s ctfstabs -r ctfconvert cc &lt; offsets.in &gt; assym.h
</pre>
<p>
The hand-written <tt>offsets.in</tt> file serves as input to the script, and it
generates the header we need. The script takes the following steps:
</p>
<ol>
<li>Two temporary files are generated from the input. One is a C file consisting of
<tt>#include</tt>s and any other pre-processor directives. The other contains
the meat of the offsets file.</li>
<li>The C file containing all the includes is built with the compile line given
(I have stripped the compiler options above for readability).</li>
<li><a href="http://cvs.opensolaris.org/source/xref/on/usr/src/tools/ctf/cvt/">ctfconvert</a> is run on the built <tt>.o</tt> file.</li> 
<li>The pre-processor is run across the second file (the temporary offsets
file)</li>
<li>This pre-processed file is passed to <tt>ctfstabs</tt> along with the
<tt>.o</tt> file.</li>
</ol>

<p>
<a href="http://cvs.opensolaris.org/source/xref/on/usr/src/tools/ctf/stabs/">ctfstabs</a> reads the input offsets file, and for each entry,
looks up the relevant value in the CTF data contained in the <tt>.o</tt> file
passed to it. It has two output modes (which I'll come to shortly), and in
this case we are using the <a href="http://cvs.opensolaris.org/source/xref/on/usr/src/tools/ctf/stabs/common/genassym.c">genassym</a> driver to output the
C header. As you can see, this is a fairly simple process of processing
each line of the input and looking up the type data in the CTF contained
in the <tt>.o</tt> file.
</p>

<p>
A similar process is used for generating forth debug files for use when
debugging the kernel via the SPARC PROM. This takes a different format
of offsets file more appropriate to generating the forth debug macros,
described in the <a href="http://cvs.opensolaris.org/source/xref/on/usr/src/tools/ctf/stabs/common/forth.c">forth driver</a>.
</p>

<p>
To finish off the output header, the output from a small program called
<a href="http://cvs.opensolaris.org/source/xref/on/usr/src/uts/i86pc/ml/genassym.c">genassym</a>
(or, on SPARC, <a href="http://cvs.opensolaris.org/source/xref/on/usr/src/uts/sun4/ml/genconst.c">genconst</a>) is appended.
It contains a bunch of <tt>printf</tt>s of constants. A lot of those
don't actually need to be there since they're simple constant defines, and
the assembly file could just include the right header, but others are still
there for reasons such as:
</p>
<ul>
<li>The macros which hide assembler syntax differences such as <a href="http://cvs.opensolaris.org/source/xref/on/usr/src/uts/intel/ia32/sys/asm_linkage.h#61">_MUL</a> aren't implemented for the C compiler
</li>
<li>
The value is an enum type, which <tt>ctfstabs</tt> doesn't support
</li>
<li>
The constant is a complicated composed macro that the assembler can't grok
</li></ul>
<p>
and other reasons. Whilst a lot of these could be cleaned up and removed from
these files, it's probably not worth the development effort except as a gradual
change.
</p><p class="tags">Tags: <a href="http://www.technorati.com/tag/OpenSolaris" rel="tag">OpenSolaris</a> <a href="http://www.technorati.com/tag/CTF" rel="tag">CTF</a>
