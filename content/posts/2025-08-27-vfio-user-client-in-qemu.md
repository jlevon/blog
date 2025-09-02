---
title: "vfio-user client in QEMU 10.1"
date: 2025-08-27T17:21:13+01:00
---

The recent release of [QEMU
10.1](https://lore.kernel.org/qemu-devel/175625036608.469964.4138433906168641553@amd.com/)
now comes with its very own `vfio-user` client. You can try this out yourself
[relatively easily](https://github.com/nutanix/libvfio-user/blob/master/docs/spdk.md) -
please give it a go![^1]

`vfio-user` is a framework that allows implementing PCI devices in userspace.
Clients (such as QEMU) talk the `vfio-user` protocol over a UNIX socket to a
device server; it looks something like this:

![vfio-user architecture](/blog/posts/images/vfio-user.drawio.png)

[^1]: unfortunately, due to a late-breaking
[regression](https://lore.kernel.org/qemu-devel/20250827190810.1645340-1-john.levon@nutanix.com/), you'll need to use
something a little bit more recent than the actual 10.1 release.

To implement a virtual device for a guest VM, there are generally two parts
required: "frontend" driver code in the guest VM, and a "backend" device
implementation.

The driver is usually - but by no means always - implemented in the guest OS
kernel, and can be the same driver real hardware uses (such as a SATA
controller), or something special for a virtualized platform (such as
`virtio-blk`).

The job of the backend device implementation is to emulate the device in various
ways: respond to register accesses, handle mappings, inject interrupts, and so
on.

An alternative to virtual devices are so-called "passthrough" devices, which
provide a thin virtualization layer on top of a real physical device, such as an
SR-IOV Virtual Function from a physical NIC. For PCI devices, these are
typically handled via the [VFIO
framework](https://www.kernel.org/doc/html/latest/driver-api/vfio.html).

Other backend implementations can live in all sorts of different places: the
host kernel, the emulator process, a hardware device, and so on.

For various reasons, we might want a userspace software device implementation,
but *not* as part of the VMM process (such as QEMU) itself.

The rationale
-------------

For `virtio`-based devices, such "out of process device emulation" is usually done via
[vhost-user](https://qemu-project.gitlab.io/qemu/interop/vhost-user.html#introduction).
This allows a device implementation to exist in a separate process,
shuttling the necessary messages, file descriptors, and shared mappings between
QEMU and the server.

However, this protocol is specific to `virtio` devices such as `virtio-net` and
so on. What if we wanted a more generic device implementation framework? This is
what `vfio-user` is for.

It is explicitly modelled on the `vfio` interface used for communication between
QEMU and the Linux kernel `vfio` driver, but it has no kernel component: it's
all done in userspace. One way to think of `vfio-user` is that it smushes
`vhost-user` and `vfio` together.

In the diagram above, we would expect much of the device setup and management to
happen via `vfio-user` messages on the UNIX socket connecting the client to the
server SPDK process: this part of the system is often referred to as the
"control plane". Once a device is set up, it is ready to handle I/O requests -
the "data plane". For performance reasons, this is often done via sharing device
memory with the VM, and/or guest memory with the device. Both `vhost-user` and
`vfio-user` support this kind of sharing, by passing file descriptors to
`mmap()` across the UNIX socket.


libvfio-user
------------

While it's entirely possible to implement a `vfio-user` server from scratch, we
have implemented a [C library](https://github.com/nutanix/libvfio-user) to make
this easier: this handles the basics of implementing a typical PCI device,
allowing device implementers to focus on the specifics of the emulation.

SPDK
----

At Nutanix, one of the main reasons we were interested in building all this was
to implement virtual storage using the NVMe protocol. To do this we make use of
[SPDK](https://spdk.io/). SPDK's NVMe support was originally designed for use in
a storage server context (NVMe over Fabrics). As it happens, there are lots of
similarities between such a server, and how an NVMe PCI controller needs to work
internally.

By re-using this `nvmf` subsystem in SPDK, alongside `libvfio-user`, we can
emulate a high-performance virtualized NVMe controller for use by a VM. From the
guest VM's operating system, it looks just like a "real" NVMe card, but on the
host, it's using the `vfio-user` protocol along with memory sharing, ioeventfds,
irqfds, etc. to talk to an SPDK server.

The Credits
-----------

While I was responsible for getting QEMU's `vfio-user` client upstreamed, I was
by no means the only person involved. My series was heavily based upon previous
work by Oracle by John Johnson and others, and the original work on `vfio-user`
in general was done by Thanos Makatos, Swapnil Ingle, and several others. And
big thanks to Cédric Le Goater for all the reviews and help getting the series
merged.

Further Work
------------

While the current implementation is working well in general, there's an awful
lot more we could be doing. The client side has enough implemented to cover our
immediate needs, but undoubtedly there are other implementations that need
extensions. The [libvfio-user issues
tracker](https://github.com/nutanix/libvfio-user/issues?q=sort%3Aupdated-desc+is%3Aissue+is%3Aopen)
captures a lot of the generic protocol work as well some library-specific
issues. In terms of virtual NVMe itself, we have lots of ideas for how to
improve the SPDK implementation, across performance, correctness, and
functionality.

There is an awful lot more I could talk about here about how this all works
"under the hood"; perhaps I will find time to write some more blog posts...
