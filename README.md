# Getch

<div align="center">
<br/>

[![Gem Version](https://badge.fury.io/rb/getch.svg)](https://badge.fury.io/rb/getch)
![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/szorfein/getch/Rubocop/develop)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)
![GitHub](https://img.shields.io/github/license/szorfein/getch)

</div>

A CLI tool to install Gentoo or Void Linux with default:
+ DNS over HTTPS (with [Quad9](https://www.quad9.net/)).
+ Vim | Nano installed.
+ Iptables installed (not configured).
+ Sudo installed (not configured).
+ [iwd](https://iwd.wiki.kernel.org/) installed if wifi is detected.
+ No GUI installed.

Hardened System:
+ sysctl.conf with TCP/IP stack hardening and more [Arch](https://wiki.archlinux.org/title/Sysctl)
+ Kernel parameters enforced (dmesg restricted, kexec disabled, etc)
+ Kernel source (Gentoo) patched with [bask](https://github.com/szorfein/bask).
+ Musl optionnal

## Description
Actually, Getch support only the `x86_64` architecture with the following archives:
+ **Gentoo**: `stage3-amd64-systemd` or `stage3-amd64-musl` [Gentoo](https://www.gentoo.org/downloads/).
+ **Void**: `rootfs tarball glibc` or `rootfs tarball musl` [Void](https://voidlinux.org/download/).

Filesystem supported (with or without encryption)
+ Ext4
+ Lvm
+ ZFS

Boot Manager:
+ **Gentoo**: `BIOS` and `musl` will use `Grub2` and `systemd-boot` for `UEFI`.
+ **Void**: use only Grub2.

The ISO images i was able to test and that works:
+ [Archlinux](https://www.archlinux.org/download/)
+ [Archaeidae](https://github.com/szorfein/archaeidae): Custom Archiso that includes ZFS support.

You can also use your current `linux` host, just pay attention to the disk that will be used.  

## Dependencies
Getch is build without external libs, so it only require `ruby >= 2.5`.

## Install
Getch is cryptographically signed, so add my public key (if you haven’t already) as a trusted certificate.  
With `gem` installed:

    $ gem cert --add <(curl -Ls https://raw.githubusercontent.com/szorfein/getch/master/certs/szorfein.pem)
    $ gem install getch -P HighSecurity

If you want to try from the source:

    # git clone https://github.com/szorfein/getch
    # cd getch
    # ruby -I lib bin/getch -h

## Usage
Just ensure than the script is run with a root account.

    # getch -h

After an install by Getch, take a look on the [wiki](https://github.com/szorfein/getch/wiki).

## Examples
For a french user:

    # getch --zoneinfo "Europe/Paris" --language fr_FR --keymap fr

Install Gentoo on LVM and use a different root disk `/dev/sdc`

    # getch --format ext4 --lvm --disk sdc

Encrypt your disk with LVM with a french keymap

    # getch --format ext4 --lvm --encrypt --keymap fr

Encrypt with ext4 and create a new user `ninja`:

    # getch --format ext4 --encrypt --username ninja

With ZFS, if used with `--encrypt`, it use the native ZFS encryption:

    # getch --format zfs

With `Void Linux` and `Musl` enable:

    # getch --os void --encrypt -k fr --musl

## Troubleshooting

#### Old VG for LVM
If a old volume group exist, `getch` may fail to partition your disk. You have to clean up your device before proceed with `vgremove` and `pvremove`. An short example how doing this with a volume group named `vg0`:

    # vgdisplay | grep vg0
    # vgremove -f vg0
    # pvremove -f /dev/sdb

#### Encryption with GRUB
To decrypt your disk on GRUB, only the `us` keymap is working for now.

#### ZFS with Grub
By default, if you use ZFS with `musl` or `voidlinux` the `/boot` partition is not mounted automatically, so before an update, mout the partition.

    # zpool status
    # zfs mount bpool/BOOT/void
    # ls /boot

#### ZFS with and without encryption
First time on ZFS after 5min

```txt
dracut Warning: /dev/disk/by-uuid/<DISK> does not exist
```

Dracut try to mount inexistent device. Just wait for enter in the shell and remove the disk uuid from `/lib/dracut/hooks/initqueue/finished/`

    # ls /lib/dracut/hooks/initqueue/finished/*
    # rm /lib/dracut/hooks/initqueue/finished/dev*
    # exit

Dracut should finally start `mount-zfs.sh` and ask for a password if encrypted. After you first login, mount the `/boot` partition and recompile the initramfs and your good.

+ For Gentoo: `emerge --config sys-kernel/gentoo-kernel-bin`
+ For Voidlinux: `xbps-reconfigure -fa`

If it doesn't work, try to start script manually (always in the shell):

    # . /lib/dracut/hooks/mount/98-mount-zsh.sh
    # . /lib/dracut/hooks/mount/99-mount-root.sh
    # exit
