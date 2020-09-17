# Getch
A CLI tool to install Gentoo.

## Description
Actually, Getch support only the [AMD64 handbook](https://wiki.gentoo.org/wiki/Handbook:AMD64) and only with the last `stage3-amd64-systemd`.  
It also require a disk (only one for now) with a minimum of 20G.  

Filesystem supported by Getch are: (the list will evolve...)
+ ext4 with GRUB2 for BIOS based system and soon systemd-boot for UEFI systems.

I would also add disk encryption soon.

## Install
Getch is cryptographically signed, so add my public key (if you haven’t already) as a trusted certificate.  
With `gem` installed:

    $ gem cert --add <(curl -Ls https://raw.githubusercontent.com/szorfein/getch/master/certs/szorfein.pem)

    $ gem install getch -P HighSecurity

When you boot from an `iso`, you can install `ruby`, `getch` and correct your `PATH=` directly with the `bin/setup.sh`:

    # curl https://raw.githubusercontent.com/szorfein/getch/master/bin/setup.sh | sh
    # source ~/.zshrc # or ~/.bashrc

## Usage

    $ getch -h

## Examples
For a french user:

    # getch --username ninja --zoneinfo "Europe/Paris" --language fr_FR --keyboard fr
