# Getch
A CLI tool to install Gentoo.

## Description
Actually, Getch support only the [AMD64 handbook](https://wiki.gentoo.org/wiki/Handbook:AMD64) and only with the last `stage3-amd64-systemd`.  
It also require a disk (only one for now) with a minimum of 20G.  

BIOS system will use Grub2 and UEFI, systemd-boot. Filesystem supported by Getch are for now:
+ ext4
+ lvm

I would also add disk encryption soon.

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

    $ getch -h

## Examples
For a french user:

    # getch --username ninja --zoneinfo "Europe/Paris" --language fr_FR --keymap fr

After an install by Getch, take a look on the [wiki](https://github.com/szorfein/getch/wiki).

Install Gentoo on LVM:

    # getch --format lvm --disk sda

## Troubleshooting

#### LVM
Unless than your older LVM volume group is named `vg0`, `getch` may fail to partition your disk, you have to clean your device before proceed with `vgremove` and `pvremove`.

## Issues
If need more support for your hardware (network, sound card, ...), you can submit a [new issue](https://github.com/szorfein/getch/issues/new) and post the output of the following command:
+ lspci
+ lsmod
