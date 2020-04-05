+++
author = "John Levon"
published = 2018-10-26T13:11:00+01:00
slug = "2018-10-26-pci-pass-through-support-with-bhyve-and-smartos"
tags = []
title = "PCI pass-through support with bhyve and SmartOS"
+++
Some prompting on IRC led me to do this write-up on how to configure PCI
passthrough for a bhyve instance running on SmartOS. Please be aware
this isn't necessarily fully supported or tested; it may work for you,
it also may not.  
Some of this is covered under [RFD
114](https://github.com/joyent/rfd/tree/master/rfd/0114); the below is
more of a HOWTO.

Global zone configuration
-------------------------

To allow a bhyve zone to access a PCI device, we need to prevent the
global zone's access to it, and make it available to bhyve zones. To do
this, we need to make two overlay files available to the system via
[boot
modules](http://dtrace.org/blogs/wesolows/2013/12/28/anonymous-tracing-on-smartos/).
Remember that the SmartOS root is an ephemeral ramdisk: as we need to
change two files in `/etc`, we'll have to modify our grub configuration:

### Modify grub to include PPT config files

    # mount our USB key (modify as needed, see diskinfo output)
    mount -F pcfs -o foldcase /dev/dsk/c1t0d0p1 /mnt
    vim /mnt/boot/grub/menu.lst

We want to modify the menu entry we're booting to be something like
this:

    title my entry
        kernel$ /os/20181023T131405Z/platform/i86pc/kernel/amd64/unix ...
        module /os/20181023T131405Z/platform/i86pc/amd64/boot_archive type=rootfs name=ramdisk
        module /20181023T131405Z/platform/i86pc/amd64/boot_archive.hash type=hash name=ramdisk
        module /overlay/etc/ppt_aliases type=file type=file name=etc/ppt_aliases
        module /overlay/etc/ppt_matches type=file type=file name=etc/ppt_matches

Make sure to add the `type` entry on all `module` lines! Before we
reboot, though, we need to actually populate these two files.

### Setting `ppt_matches`

This file is a list of \*all\* devices that we might want to
pass-through, in PCI ID form:

    # cat /mnt/overlay/etc/ppt_matches
    pciex10de,a65
    pciex10de,be3

This file should contain the PCI ID of the type of device you want to
pass through. (Please ignore all PCI specifics here, this is just for
illustration.). Every device on the system that has these IDs will be
listed (after a reboot) in `pptadm list -a`.

### Setting `ppt_aliases`

The second file is used to actually reserve specific devices for
pass-through, based on physical path. For example:

    # cat /mnt/overlay/etc/ppt_aliases 
    ppt "/pci@0,0/pci8086,151@1/display@0"
    ppt "/pci@0,0/pci8086,151@1/pci1462,2291"

This binds the "ppt" driver to the given paths under `/devices`. On a
reboot, the kernel will process this and attach ppt as needed. This
driver stub makes sure that the host kernel won't try to process the
device itself.

### Reboot the host

After we reboot, we should find our files are processed. They are
visible under the path `/system/boot` - the existing `/etc/ppt_matches`
will be over-ridden. The `pptadm(1m)` tool is a handy way of listing
this configuration:

    # pptadm list -a -o dev,vendor,device,path
    DEV        VENDOR DEVICE PATH
    /dev/ppt0  10de   a65    /pci@0,0/pci8086,151@1/display@0
    /dev/ppt1  10de   be3    /pci@0,0/pci8086,151@1/pci1462,2291

We can see that two specific devices are now available for pass-through.

Zone configuration
------------------

Now we need to configure our VM to actually use this device. In the JSON
for the VM, this looks something like this:

      "pci_devices": [
         {
           "path": "/devices/pci@0,0/pci8086,151@1/display@0",
           "pci_slot": "0:8:0"
         },
         {
           "path": "/devices/pci@0,0/pci8086,151@1/pci1462,2291",
           "pci_slot": "0:8:1"
         }
      ]

where `path` is the physical path, and the PCI slot is what the guest
will see (the usual bus,device,function triple). Passing the new JSON
into `vmadm update` should allow the VM to boot with the new
configuration.  
You can check `/zones/$uuid/logs/platform.log` for any problems.
