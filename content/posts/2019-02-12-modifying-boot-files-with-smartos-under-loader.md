+++
published = 2019-02-12T15:15:00.001000Z
slug = "2019-02-12-modifying-boot-files-with-smartos-under-loader"
tags = []
title = "Modifying boot files with SmartOS under Loader"
+++
With the advent of [newboot in
SmartOS/Triton](https://www.listbox.com/member/archive/247449/2019/02/sort/time_rev/page/1/entry/1:14/20190211172850:6613C40C-2E4C-11E9-8B8A-A8C2ED59BD25/),
newly-installed systems will use `loader` as the bootloader, replacing
`grub`. See [RFD
156](https://github.com/joyent/rfd/tree/master/rfd/0156) for some
technical background on the motivation of the switch.

It's often the case that people want to make some modification to an
`/etc` file in subsequent SmartOS boots. As we boot from ramdisk, we
can't just directly modify the files. As originally described [on
Keith's
blog](http://dtrace.org/blogs/wesolows/2013/12/28/anonymous-tracing-on-smartos/)
the way to get around this problem involves specifying specific files to
over-ride the default.

Obviously this has changed under `loader`. Let's presume we want to
over-ride `/etc/system` to set `kmem_flags`. First, let's take a copy of
our file and edit it:

    # sdc-usbkey mount
    /mnt/usbkey
    # mkdir -p /mnt/usbkey/bootfs/etc/ # or whatever
    # cp /etc/system /mnt/usbkey/bootfs/etc/system    # or /mnt/usbkey/bootfs/dtrace.conf etc.
    # echo "set kmem_flags=0xf" >>/mnt/usbkey/bootfs/etc/system

Now we want `loader` to prepare this file as a bootfs module. In grub,
we used something like
"`module /bootfs/etc/system type=file name=etc/system`". For loader,
it's similar:

    # cd /mnt/usbkey/boot
    # echo etc_system_load=YES >>loader.conf.local
    # echo etc_system_type=file >>loader.conf.local
    # echo etc_system_name=/bootfs/etc/system >>loader.conf.local
    # echo etc_system_flags=\"name=/etc/system\" >>loader.conf.local

The prefix (`etc_system_`) is fairly arbitrary, though often named after
the module. For each file you want, you'd want a `_load`, `_type`,
`_name` and `_flag` line specified. The `_name` entry is the path to the
file for loader to use; the `name` *flag* is the `/system/boot/...` path
you want the modified file to be available at after booting.

If this all worked OK, then we should see during boot something like:

    Loading /os/20190207T125627Z/platform/i86pc/kernel/amd64/unix...
    Loading /os/20190207T125627Z/platform/i86pc/amd64/boot_archive...
    Loading /os/20190207T125627Z/platform/i86pc/amd64/boot_archive.hash...
    Loading /bootfs/etc/system...
    Booting...
    SunOS Release 5.11 Version joyent_20190207T125627Z 64-bit
    Copyright (c) 2010-2019, Joyent Inc. All rights reserved.
    WARNING: High-overhead kmem debugging features enabled (kmem_flags = 0xf)...

And we should find a copy of our modified file here:

    # tail /system/boot/etc/system 
    ...
    set kmem_flags=0xf
