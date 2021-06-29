# Getch
A CLI tool to install Gentoo or Void Linux with default:
+ DNS over HTTPS (with [Quad9](https://www.quad9.net/)).
+ Vim | Nano installed.
+ Iptables installed (not configured).
+ Sudo installed (not configured).
+ No GUI installed.

Hardened System:
+ sysctl.conf with TCP/IP stack hardening  and more [Arch](https://wiki.archlinux.org/title/Sysctl)
+ Kernel parameters enforced (dmesg restricted, kexec disabled, etc)
+ Kernel source (Gentoo) patched with [bask](https://github.com/szorfein/bask).

**Note** about Void Linux, only fs `ext4` and `lvm` are working for now (encrypted or not), i'll add the rest later.

## Description
Actually, Getch support only the `x86_64` architecture and only with the following archives:
+ **Gentoo**: `stage3-amd64-systemd` [Gentoo](https://www.gentoo.org/downloads/).
+ **Void**: `rootfs glibc` [Void](https://voidlinux.org/download/).

Filesystem supported (with or without encryption)
+ Ext4
+ Lvm
+ ZFS

Boot Manager:
+ **Gentoo**: `BIOS` will use `Grub2` and `systemd-boot` for `UEFI`.
+ **Void**: use only Grub2, encryption for the root fs use luks1.

The ISO images i was able to test and that works:
+ [Archlinux](https://www.archlinux.org/download/)
+ [Archaeidae](https://github.com/szorfein/archaeidae): Custom Archiso that includes ZFS support.

## Dependencies
Getch is build without external libs, so it only require `ruby >= 2.5`.

## Install
Getch is cryptographically signed, so add my public key (if you haven’t already) as a trusted certificate.  
With `gem` installed:

    $ gem cert --add <(curl -Ls https://raw.githubusercontent.com/szorfein/getch/master/certs/szorfein.pem)
    $ gem install getch -P HighSecurity

If you want to try the master branch (can be unstable):

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

    # getch --format lvm --disk sdc

Encrypt your disk with LVM with a french keymap

    # getch --format lvm --encrypt --keymap fr

Encrypt with ext4 and create a new user `ninja`:

    # getch --format ext4 --encrypt --username ninja

With ZFS, if used with `--encrypt`, it use the native ZFS encryption:

    # getch --format zfs

With `Void Linux`:

    # getch --os void --encrypt -k fr

## Troubleshooting

#### LVM
Unless your old LVM volume group is also named `vg0`, `getch` may fail to partition your disk. You have to clean up your device before proceed with `vgremove` and `pvremove`. An short example how doing this with a volume group named `vg0`:

    # vgdisplay | grep vg0
    # vgremove -f vg0
    # pvremove -f /dev/sdb

#### Encryption enable on BIOS with ext4
To decrypt your disk on BIOS system, you have to enter your password twice. One time for Grub and another time for Genkernel. [post](https://wiki.archlinux.org/index.php/GRUB#Encrypted_/boot).  
Also with GRUB, only a `us` keymap is working.

#### ZFS
When Gentoo boot the first time, the pool may fail to start, it's happen when the pool has not been `export` to the ISO. So just `export` your pool from the genkernel shell:

The zpool name should be visible (rpool-150ed here), so enter in the Genkernel shell:

    > shell
    zpool import -f -N -R /tmp rpool-150ed

Import also the `bpool` if you have GRUB installed.

    zpool import -f -N -R /tmp bpool-150ed
    zpool export -a

Then, just reboot now, it's all.

*INFO*: To create the zpool, getch use the 5 fist characters from the `partuuid`, just replace `sdX` by your real device:

    # ls -l /dev/disk/by-partuuid/ | grep sdX4
    -> 150ed969...

The pool will be called `rpool-150ed`.

## Issues
If need more support for your hardware (network, sound card, ...), you can submit a [new issue](https://github.com/szorfein/getch/issues/new) and post the output of the following command:
+ lspci
+ cat /proc/modules

Any recommandations are welcome. 
