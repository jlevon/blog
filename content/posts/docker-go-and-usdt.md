---
title: "Docker, Go and USDT"
date: 2020-08-06T09:09:13Z
---

We have what should be a simple task: we're on CentOS 7, and we want to
deploy a Go binary that will have [USDT
tracepoints](https://lwn.net/Articles/753601/). USDT is an attractive
option for a few debugging purposes. It allows applications to define
tracepoints with higher levels of stability and semantic meaning than
more ad-hoc methods like dynamic uprobes.

Usage of USDT tracepoints tends to have a different focus from other
monitoring techniques like logging, Prometheus, OpenTracing etc. These
might identify a general issue such as a poor latency metric: you'd then
use USDT probes to dig further into the problems in a production system,
to identify precisely what's happening at a particular endpoint or
whatever.

# USDT in Go

The normal model for USDT involves placing the trace points at specific
places in the binary: they are *statically* defined and built, but
*dynamically* enabled. This is typically done via the `DTRACE_PROBE()`
family of macros.

The only (?) USDT facility for Go is
[salp](https://github.com/mmcshane/salp). This uses
[libstapsdt](https://github.com/sthima/libstapsdt) under the hood. This
library dynamically creates probes at runtime, even though Go is a
compiled language.  Yes, this is dynamic static dynamic tracing.

We're going to use `salpdemo` in our experiment. This has two USDT
probes, `p1` and `p2` that we'd like to be able to dynamically trace,
using `bcc-tools`' handy `trace` wrapper. CentOS 7 doesn't appear to have
support for the later USDT support in `perf probe`.

# Setting up a Docker container for dynamic tracing

For a few different reasons, we'd like to be able to trace from inside
the container itself. This has security implications, given what's
implemented today, but bear in mind we're on CentOS 7, so even if
there's a finer-grained current solution, there's a good chance it
wouldn't work here. In reality, we would probably use an ad-hoc
debugging sidecar container, but we're going to just use the one
container here.

First, we're going to deploy the container with ansible for
convenience:

```
$ cat hosts
localhost ansible_connection=local
$ cat playbook.yml
---

- hosts: localhost
  become: yes
  tasks:
    - docker_container:
        name: usdt_test
        image: centos:7
        state: started
        command: sleep infinity
        network_mode: bridge
        ulimits:
          - memlock:8192000:8192000
        capabilities:
          - sys_admin
        volumes:
          - /sys/kernel/debug:/sys/kernel/debug
$ ansible-playbook -i hosts ./playbook.yml
```

Note that we're using `sleep infinity` here to keep our container
running so we can play around.

We need the `sys_admin` capability to be able to program the probes,
and the BPF compiler needs the locked memory limit bumping. We also
need to mount `/sys/kernel/debug` read-write (!) in order to be able to
write to `/sys/kernel/debug/tracing/uprobe_events`.

Now let's install everything we need to be able to trace these probes:

```
$ docker exec -it usdt_test yum -y install \
    kernel-devel-$(uname -r) kernel-$(uname -r) bcc-tools
```

Yes, it's a lot, but unavoidable. You can, in theory, use mounted
volumes for the kernel sources, as described
[here](https://github.com/iovisor/bcc/blob/master/QUICKSTART.md);
however, the read-only mounts break packaging inside the container, so
we're not doing that here.

# Tracing the probes in the container

The above was a big hammer, but we should be good to go right? Let's
start up the demo binary:

```
$ docker cp ~/salpdemo usdt_test:/root/
$ docker exec -it usdt_test bash
[root@8ccf34663dd2 /]# ~/salpdemo &
[1] 18166
 List the go probes in this demo with
	sudo tplist -vp "$(pgrep salpdemo)" "salp-demo*"
Trace this process with
	sudo trace -p "$(pgrep salpdemo | head -n1)" 'u::p1 "i=%d err=`%s` date=`%s`", arg1, arg2, arg3' 'u::p2 "j=%d flag=%d", arg1, arg2'
	or
	sudo trace -p "$(pgrep salpdemo | head -n1)" 'u::p1 (arg1 % 2 == 0) "i=%d err='%s'", arg1, arg2'
```

We can indeed list the probes:

```
[root@8ccf34663dd2 /]# /usr/share/bcc/tools/tplist -vp $(pgrep salpdemo) | head
salp-demo:p1 [sema 0x0]
  1 location(s)
  3 argument(s)
salp-demo:p2 [sema 0x0]
  1 location(s)
  2 argument(s)
libc:setjmp [sema 0x0]
...
```

So let's try the suggested `trace` invocation:

```
# /usr/share/bcc/tools/trace -p "$(pgrep salpdemo | head -n1)" 'u::p1 (arg1 % 2 == 0) "i=%d err='%s'", arg1, arg2'

perf_event_open(/sys/kernel/debug/tracing/events/uprobes/p__tmp_salp_demo_I8qitQ_so_0x270_18166_bcc_18175/id): Invalid argument
Failed to attach BPF to uprobe
```

Huh. This doesn't seem to be a permissions issue, since we got `EINVAL`.
In addition, running from the host has the same problem.

I haven't proved it, but I think our basic issue here is that Centos 7
is missing this kernel fix:

[ tracing/uprobe: Add support for overlayfs](https://github.com/torvalds/linux/commit/f0a2aa5a2a406d0a57aa9b320ffaa5538672b6c5)

I spent way too long trying to work around this by placing the binary
somewhere other than overlayfs, before I finally dug a little bit more
into how `libstapsdt` actually works, and figured out the problem.

## Working around overlayfs and libstapsdt

To build probes dynamically at runtime, `libstapsdt` does something
[slightly
crazy](https://github.com/sthima/libstapsdt/blob/master/docs/how-it-works/internals.rst):
it generates a temporay ELF shared library at runtime that contains
the USDT probes and uses `dlopen()` to bring it into the running binary.
Let's have a look:

```
[root@8ccf34663dd2 /]# grep salp-demo /proc/$(pgrep salpdemo)/maps
7fa9373b5000-7fa9373b6000 r-xp 00000000 fd:10 1506373                    /tmp/salp-demo-I8qitQ.so
7fa9373b6000-7fa9375b5000 ---p 00001000 fd:10 1506373                    /tmp/salp-demo-I8qitQ.so
7fa9375b5000-7fa9375b6000 rwxp 00000000 fd:10 1506373                    /tmp/salp-demo-I8qitQ.so
```

The process has mapped in this temporary file, named after the provider.
It's on `/tmp`, hence `overlay2` filesystem, explaining why moving the
`salpdemo` binary itself around made no difference.

So maybe we can be more specific?

```
[root@8ccf34663dd2 /]# /usr/share/bcc/tools/trace -p "$(pgrep salpdemo | head -n1)" 'u:/tmp/salp-demo-I8qitQ.so:p1 (arg1 % 2 == 0) "i=%d err='%s'", arg1, arg2'
perf_event_open(/sys/kernel/debug/tracing/events/uprobes/p__tmp_salp_demo_I8qitQ_so_0x270_18166_bcc_18188/id): Invalid argument
Failed to attach BPF to uprobe
```

Still not there yet. The above bug means that it still can't find the
uprobe given the binary image path. What we really need is the *host*
path of this file. We can get this from Docker:

```
$ docker inspect usdt_test | json -a GraphDriver.Data.MergedDir
/data/docker/overlay2/77c1397db72a7f3c7ba3f8af6c5b3824dc9c2ace9432be0b0431a2032ea93bce/merged
```

This is not good, as obviously we can't reach this path from inside the
container. Hey, at least we can run it on the host though.

```
$ sudo /usr/share/bcc/tools/trace 'u:/data/docker/overlay2/77c1397db72a7f3c7ba3f8af6c5b3824dc9c2ace9432be0b0431a2032ea93bce/merged/tmp/salp-demo-I8qitQ.so:p1 (arg1 % 2 == 0) "i=%d err='%s'", arg1, arg2'
Event name (p__data_docker_overlay2_77c1397db72a7f3c7ba3f8af6c5b3824dc9c2ace9432be0b0431a2032ea93bce_merged_tmp_salp_demo_I8qitQ_so_0x270) is too long for buffer
Failed to attach BPF to uprobe
```

SIGH. Luckily, though:

```
$ sudo /usr/share/bcc/tools/trace 'u:/data/docker/overlay2/77c1397db72a7f3c7ba3f8af6c5b3824dc9c2ace9432be0b0431a2032ea93bce/diff/tmp/salp-demo-I8qitQ.so:p1 (arg1 % 2 == 0) "i=%d err='%s'", arg1, arg2'
PID     TID     COMM            FUNC             -
19862   19864   salpdemo        p1               i=64 err=An error: 64
19862   19864   salpdemo        p1               i=66 err=An error: 66
```

It worked! But it's not so great: we wanted to be able to trace inside a
container. If we mounted `/data/docker` itself inside the container, we
could do that, but it's still incredibly awkward.

## Using tmpfs?

Instead, can we get the generated file onto a different filesystem type?
`libstapsdt` [hard-codes
`/tmp`](https://github.com/sthima/libstapsdt/blob/99911c5a44ea40fd14d99c52c5dacf4328aa463c/src/libstapsdt.c#L86)
which limits our options.

Let's start again with `/tmp` inside the container on `tmpfs`:

```
$ tail -1 playbook.yml
        tmpfs: /tmp:exec
```

We need to force on `exec` mount flag here: otherwise, we can't
`dlopen()` the generated file. Yes, not great for security again.

```
$ docker exec -it usdt_test bash
# ~/salpdemo &
...
[root@1f56af6e7bee /]# /usr/share/bcc/tools/trace -p "$(pgrep salpdemo | head -n1)" 'u::p1 "i=%d err=`%s` date=`%s`", arg1, arg2, arg3' 'u::p2 "j=%d flag=%d", arg1, arg2'
PID     TID     COMM            FUNC             -

```

Well, we're sort of there. It started up, but we never get any output.
Worse, we get the same if we try this in the host now!  I don't know
what the issue here is.

## Using a volume?

Let's try a volume mount instead:

```
$ tail -3 playbook.yml
        volumes:
          - /sys/kernel/debug:/sys/kernel/debug
          - /tmp/tmp.usdt_test:/tmp
```

If we run `trace` in the host now, we can just use `u::p1`:

```
$ sudo /usr/share/bcc/tools/trace -p "$(pgrep salpdemo | head -n1)" 'u::p1 "i=%d err=`%s` date=`%s`", arg1, arg2, arg3' 'u::p2 "j=%d flag=%d", arg1, arg2'
PID     TID     COMM            FUNC             -
6864    6866    salpdemo        p2               j=120 flag=1
...
```

But we still need a bit of a tweak inside our container:

```
# /usr/share/bcc/tools/trace -p "$(pgrep salpdemo | head -n1)" 'u::p1 "i=%d err=`%s` date=`%s`", arg1, arg2, arg3'
PID     TID     COMM            FUNC             -
<no output>
```

```
[root@d72b822cab0f /]# cat /proc/$(pgrep salpdemo | head -n1)/maps | grep /tmp/salp-demo*.so | awk '{print $6}' | head -n1
/tmp/salp-demo-6kcugm.so
[root@d72b822cab0f /]# /usr/share/bcc/tools/trace -p  "$(pgrep salpdemo | head -n1)" 'u:/tmp/salp-demo-6kcugm.so:p1 "i=%d err=`%s` date=`%s`", arg1, arg2, arg3'
PID     TID     COMM            FUNC             -
11593   11595   salpdemo        p1               i=-17 err=`An error: -17` date=`Thu, 06 Aug 2020 13:12:57 +0000`
...
```

I don't have any clear idea why the name is required inside the
container context, but at least, finally, we managed to trace those USDT
probes!
