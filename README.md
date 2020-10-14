# Getch
A CLI tool to install Gentoo.

## Description
Actually, Getch support only the [AMD64 handbook](https://wiki.gentoo.org/wiki/Handbook:AMD64) and only with the last `stage3-amd64-systemd`.  
It also require a disk (only one for now) with a minimum of 20G.  

BIOS system will use Grub2 and UEFI, systemd-boot. Filesystem supported by Getch are for now:
+ ext4
+ lvm

Encryption is also supported.

The ISO images i was able to test and that works:
+ [Archlinux](https://www.archlinux.org/download/)

## Install
Getch is cryptographically signed, so add my public key (if you haven’t already) as a trusted certificate.  
With `gem` installed:

    $ gem cert --add <(curl -Ls https://raw.githubusercontent.com/szorfein/getch/master/certs/szorfein.pem)

    $ gem install getch -P HighSecurity

When you boot from an `iso`, you can install `ruby`, `getch` and correct your `PATH=` directly with the `bin/setup.sh`:

    # sh <(curl -L https://raw.githubusercontent.com/szorfein/getch/master/bin/setup.sh)
    # source ~/.zshrc # or ~/.bashrc

## Usage
Just ensure than the script is run with a root account, not just sudo.

    # getch -h

After an install by Getch, take a look on the [wiki](https://github.com/szorfein/getch/wiki).

## Examples
For a french user:

    # getch --zoneinfo "Europe/Paris" --language fr_FR --keymap fr

Install Gentoo on LVM:

    # getch --format lvm --disk sda

Encrypt your disk with LVM with a french keymap

    # getch --format lvm --encrypt --keymap fr

Encrypt with ext4 and create a home directory /home/ninja

    # getch --format ext4 --encrypt --username ninja

## Troubleshooting

#### LVM
Unless your old LVM volume group is also named `vg0`, `getch` may fail to partition your disk. You have to clean up your device before proceed with `vgremove` and `pvremove`.

#### Encryption enable on BIOS with ext4
To decrypt your disk on BIOS system, you have to enter your password two times. One time for Grub and another time for the initramfs (Genkernel). [post](https://wiki.archlinux.org/index.php/GRUB#Encrypted_/boot).  
Also with GRUB, only a `us` keymap is working.

## Issues
If need more support for your hardware (network, sound card, ...), you can submit a [new issue](https://github.com/szorfein/getch/issues/new) and post the output of the following command:
+ lspci
+ lsmod
