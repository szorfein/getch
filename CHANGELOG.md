* Add configs for systemd-network to have network after a reboot.
* Correct permissions (/home/[user] and /etc/portage)

## 0.1.2, release 2021-05-12
* DOCS update.
* Keep Nano for those who need :)
* ZFS use the last version >=2.0 with kernel stable =5.10
* ZFS create a Log device and Cache device if getch is used with `--separate-cache`.
* GRUB or Systemd-boot can now be installed on separate disk with `--separate-boot`.
* Adding flag for ZFS `-o autotrim=on` (used with `zpool create`).
* Encrypted swap use: `cipher=aes-xts-plain64:sha256,size=512` by default.
* In the make.conf: add `-fomit-frame-pointer`, designed to reduce generated code size.

## 0.1.1, release 2020-11-01
* Change mountpoint for the esp at /efi rather than /boot/efi
* Replace Garden by Bask https://github.com/szorfein/bask
* Correct option --username USERNAME, do not create a new partition.
* New set of options --separate-{boot,cache,home} to install them on another disk
* Refactor codes
* Add cpu name to COMMON_FLAGS
* Add cpuflags with app-portage/cpuid2cpuflags
+ Use the whole disk space available for / when option --username is unset

## 0.1.0, release 2020-10-15
* Add the (Zeta) filesystem ZFS
* `emerge --depclean` to save space.
* Add a message when getch have finish, keep /mnt/gentoo if you need to add something.
* Use systemd-detect-virt to detect a Virtual Guest.

## 0.0.9, release 2020-10-03
* Add encryption on ext4 and lvm (BIOS,UEFI)
* Correct KEYMAP="yes" with genkernel
* Renaming option keyboard with keymap
* GPG verification for ebuild

## 0.0.8, release 2020-09-30
* Adding LVM via the option fs, `--fs lvm`.
* Systemd-boot use the value of PARTUUID without initramfs.
* Include lib logger.
* Enhance functions to call program system Emerge, Make, ...

## 0.0.7, release 2020-09-22
* Correct fstab.
* Repair GRUB/fstab for BIOS system, add secure cmdline.
* Create a swap volume equal to the memory installed.
* Add vim and sudo

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
