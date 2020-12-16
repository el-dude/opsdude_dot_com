*Posted on June 19, 2013 by El Duderino — No Comments ↓*	

# Software RAID mirror the OS Drives with ZFS

I have been tasked with setting up a new storage server for a Lab for use with a new Virtual [KVM](http://www.linux-kvm.org/page/Main_Page)cluster. I looked at several options and decided to go with a ZFS solution. I picked [OpenIndiana](https://www.openindiana.org/),[Illumian](http://web.archive.org/web/20141217172543/http://illumian.org/),[OmniOS](https://omniosce.org/)&[FreeNAS](https://www.freenas.org/)to test against each other. We are not looking at Nexenta as an option, it’s a Lab, we don’t want to pay for a license. But if I were going to do this in production, I would suggest Nexenta.

I have some experience with ZFS from my previous job I supported 4 NAS devices I built with white Box hardware running[Nexentastor](https://nexenta.com/products/nexentastor)totaling 140TB in space.

If you’re thinking about building your own white box Storage array I would recommend using [Thinkmate](https://www.thinkmate.com/)they are a great company and I have been working with them for several years now. They even offer some good storage solutions, readymade. If you are thinking about using ZFS, here are some good links to get started with:

- [ZFS on linux](https://zfsonlinux.org/index.html)
- [freeBSD ZFS Tuning Guide](https://wiki.freebsd.org/ZFSTuningGuide)
- [illumos](https://illumos.org/docs/about/)
- [ZFS Best Practices Guide](http://web.archive.org/web/20141217015352/http://www.solarisinternals.com/wiki/index.php/ZFS_Best_Practices_Guide)
- [ZFS Evil Tuning Guide](http://web.archive.org/web/20141216152447/http://www.solarisinternals.com/wiki/index.php/ZFS_Evil_Tuning_Guide)


After installing OpenIndiana on my test system (not final hardware) to kick the tires, I found that the installer left some things to be desired, like only installing onto a single disk. This post will describe the steps needed to move the install onto a ZFS Software Raid Mirror.

**Step one, figure out what drives are what?**

-  Use the cfgadm command and grep for disk to get the list:
```
root@openindiana:~# cfgadm -al|head -c1 ; cfgadm -al|grep "disk"
Ap_Id                          Type         Receptacle   Occupant     Condition
c4::dsk/c4t0d0                 disk         connected    configured   unknown
c4::dsk/c4t1d0                 disk         connected    configured   unknown
c4::dsk/c4t2d0                 disk         connected    configured   unknown
c4::dsk/c4t3d0                 disk         connected    configured   unknown
c4::dsk/c4t4d0                 disk         connected    configured   unknown
c4::dsk/c4t5d0                 disk         connected    configured   unknown
root@openindiana:~#
```

- Use the zpool command to see what drive is running the OS:
```
root@openindiana:~# zpool status
  pool: rpool2
state: ONLINE
  scan: none requested
config:

        NAME        STATE     READ WRITE CKSUM
        rpool2      ONLINE       0     0     0
          c4t0d0s0  ONLINE       0     0     0

errors: No known data errors
root@openindiana:~#
```

So we can now see that the OS is running on c4t0d0s0. 

**Step two, we will need to duplicate the data on the drive c4t0d0s0 to the other disk we want to bring into the mirror.**

- Duplicate the disk partition using fdisk like this:
```
root@openindiana:~# fdisk -W /var/tmp/rpool-fdisk /dev/rdsk/c4t0d0p0
root@openindiana:~# fdisk -F /var/tmp/rpool-fdisk /dev/rdsk/c4t1d0p0
```

- Then duplicate the disk label:
```
root@openindiana:~# prtvtoc /dev/rdsk/c4t0d0s0 | fmthard -s - /dev/rdsk/c4t1d0s0
fmthard:  New volume table of contents now in place.
root@openindiana:~#
```


**Step three, we will now want to create the new mirror in ZFS**

- create the mirror with zpool:

```
root@openindiana:~# zpool attach -f rpool2 c4t0d0s0 c4t1d0s0
Make sure to wait until resilver is done before rebooting.
root@openindiana:~#
```

- Checking the status of mirror as it starts to build:

```
root@openindiana:~# zpool status
  pool: rpool2
state: ONLINE
status: One or more devices is currently being resilvered.  The pool will
        continue to function, possibly in a degraded state.
action: Wait for the resilver to complete.
  scan: resilver in progress since Tue Apr 23 21:21:43 2013
    213M scanned out of 9.70G at 19.4M/s, 0h8m to go
    213M resilvered, 2.15% done
config:

        NAME          STATE     READ WRITE CKSUM
        rpool2        ONLINE       0     0     0
          mirror-0    ONLINE       0     0     0
            c4t0d0s0  ONLINE       0     0     0
            c4t1d0s0  ONLINE       0     0     0  (resilvering)

errors: No known data errors
root@openindiana:~#
```

- Check the status again to see if it has finished resilvering, now the mirror is built:

```
root@openindiana:~# zpool status
  pool: rpool2
state: ONLINE
  scan: resilvered 9.70G in 0h2m with 0 errors on Tue Apr 23 21:24:02 2013
config:

        NAME          STATE     READ WRITE CKSUM
        rpool2        ONLINE       0     0     0
          mirror-0    ONLINE       0     0     0
            c4t0d0s0  ONLINE       0     0     0
            c4t1d0s0  ONLINE       0     0     0

errors: No known data errors
root@openindiana:~#
```

**Step Four, make sure to put the boot loader on the new mirrored drive.**

- Add the boot loader using grub to the new mirror drive:

```
root@openindiana:~# installgrub /boot/grub/stage1 /boot/grub/stage2 /dev/rdsk/c4t1d0s0
stage2 written to partition 0, 277 sectors starting at 50 (abs 16115)
stage1 written to partition 0 sector 0 (abs 16065)
root@openindiana:~#
```

And there you have it. the newly installed[OpenIndiana](https://www.openindiana.org/)we are kicking the tires with now has a ZFS software raid mirrored OS.
