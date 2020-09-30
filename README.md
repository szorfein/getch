# Getch
A CLI tool to install Gentoo.

## Description
Actually, Getch support only the [AMD64 handbook](https://wiki.gentoo.org/wiki/Handbook:AMD64) and only with the last `stage3-amd64-systemd`.  
It also require a disk (only one for now) with a minimum of 20G.  

Filesystem supported by Getch are: (the list will evolve...)
+ ext4 with GRUB2 for BIOS based system and systemd-boot for UEFI systems.

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

    # getch --username ninja --zoneinfo "Europe/Paris" --language fr_FR --keyboard fr

After an install by Getch, take a look on the [wiki](https://github.com/szorfein/getch/wiki).

Install Gentoo on LVM:

    # getch --format lvm --disk sda

## Issues
If need more support for your hardware (network, sound card, ...), you can submit a [new issue](https://github.com/szorfein/getch/issues/new) and post the output of the following command:
+ lspci
+ lsmod
