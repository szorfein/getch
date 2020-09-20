## 0.0.6, release 2020-09-19
* Add support for QEMU guest with KVM and Virtio driver
* Kernel compilation, initialize a config file with `make localyesconfig`.
* More modular codes to start with encryption and other filesystems.
* Add the new option --verbose to display output of compilation, etc...

## 0.0.5, release 2020-09-17
* Generate a hostname
* Configure systemd-boot for UEFI system

## 0.0.4, release 2020-09-16
* Boot on a BIOS system with VirtualBox
* Install Grub
* Create user
* Create passwd for root and user
* Check lsmod to install deps (like wpa_supplicant) and patch the kernel

## 0.0.3, release 2020-09-14
* Add dhcpcd, gentoo-sources, linux-firmware
* Kernel build by using https://github.com/szorfein/garden
* Populate /etc/portage (/etc/portage/package.{use,unmask,accept_keywords}/zzz_via_autounmask)
* Download all the lastest ebuild via emerge-webrsync
* Update gentoo via emerge -uDN @world

## 0.0.2, release 2020-09-12
* Getch genere a file /tmp/install_gentoo to avoid to remake same task over and over
* Support for ext4
* Mount partition on /mnt/gentoo during the install
* Download, verify the checksum and decompress the last stage3-amd64-systemd

## 0.0.1, release 2020-09-10
* Partition disk (at least 15G required) with sgdisk (create /boot, /, /home, and swap)
* Support for one disk with -d|--disk
* Add few options for the CLI
* Add bin/setup.sh to install ruby when boot on a ISO file
* Init project
