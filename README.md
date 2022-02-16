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
+ **Gentoo**: `BIOS` will use `Grub2` and `systemd-boot` for `UEFI`.
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

#### ZFS with Grub - mount the boot pool
By default, your /boot is empty because your boot pool is not mounted...

    # zpool status
    # zfs mount bpool/BOOT/void
    # ls /boot

You should see something in the boot (initramfs, vmlinuz).. Recreate the initramfs.

    # xbps-reconfigure -fa

And reboot, the `/boot` partition should be mounted automatically after that.

#### ZFS with and without encryption
Well, another weird issue with Dracut, the first time you boot on your encrypted pool, nothing append. Dracut try to mount inexistent device. Just wait for enter in the shell:

    # ls /lib/dracut/hooks/initqueue/finished/*
    # rm /lib/dracut/hooks/initqueue/finished/dev*
    # exit

Dracut should finally start `mount-zfs.sh` and ask for your password. After you first login, follow instructions above for recompile the initramfs and mount the boot pool and your good.

If it doesn't work, try to start script manually (always in the shell):

    # sh /lib/dracut/hooks/mount/98-mount-zsh.sh
    # sh /lib/dracut/hooks/mount/99-mount-root.sh
    # exit
