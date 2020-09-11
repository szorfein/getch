# Getch
A CLI tool to install Gentoo.

## Install
Getch is cryptographically signed, so add my public key (if you haven’t already) as a trusted certificate.  
With `gem` installed:

    $ gem cert --add <(curl -Ls https://raw.githubusercontent.com/szorfein/getch/master/certs/szorfein.pem)

    $ gem install getch -P HighSecurity

When you boot from an `iso`, you can install `ruby`, `getch` and correct your `PATH=` directly with the `bin/setup.sh`:

    # curl https://raw.githubusercontent.com/szorfein/getch/master/bin/setup.sh | sh

## Usage

    $ getch -h
