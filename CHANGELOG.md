* Support [Gentoo binary](https://www.gentoo.org/news/2023/12/29/Gentoo-binary.html), use `--binary`, it make the install of Gentoo faster for small system.

## 0.7.3, release 2024-10
Add a Workflow to build gem on Github

### Fix
- Voidlinux, remove 'base-container-full' instead of 'base-voidstrap'.
- Gentoo, use and configure 'sys-kernel/installkernel', sys-kernel/installkernel-systemd was removed from portage.

## 0.7.0, release 2023-12
* Add support for ssd disk `/dev/nvme*` #5
* System with systemd may need `systemd-machine-id-setup && systemctl restart systemd-networkd` after the first boot to make the dhcp works.
* Install of systemd/encrypt for Gentoo use GRUB instead of bootctl.
* Luks key if `--encrypt` are created earlier.
* Remove `noauto` and update arguments of fstab, this make futur system updates more easy.
* Correct lvm `OPTIONS[:lvm]`instead of the old `OPTIONS[:fs] == 'lvm'`.

## 0.5.0, release 2023-12
* Update Voidlinux url https://repo-default.voidlinux.org.
* Add global use="modules-sign" for Gentoo.
* makeopts on Gentoo use the value of `nproc`.
* Correct the install on Gentoo with systemd (kernel name and more).
* More rubocop style.

## 0.3.5, release 2022-11-21
* Tested on a live Ubuntu 22.10.
* Ensure `dracut.conf.d` exist before writing to it.
* Display the version with `-v`, `--version`.

## 0.3.4, release 2022-10-10
* Can work on a Live image of Voidlinux.

## 0.3.3, release 2022-10-01
* Support disk with a sector size of 512.
* Support vdx disk (disk on virtualization).

## 0.3.0, release 2022-02-17
* Gentoo with musl use an additional repo https://github.com/gentoo/musl.git.
* Gentoo use the kernel `sys-kernel/gentoo-kernel-bin` to install more quickly.
* No more need to enter password twice with Grub and encrypted system.
* Can restart the whole installation from scratch with the option `--restart`
* ZFS create pool with disk id `/dev/disk/by-id`.
* New option `--lvm` instead of `-f lvm`.
* Rename option `-z | --zoneinfo` for `-t | --timezone`. Default use `UTC`.
* Use a generic hostname `host` rather than '{os}-hatch-{randomID}'
* Musl can be installed with the `--musl` option.
* Use colors in the script, look better.

## 0.1.9, release 2022-01-26
* Gentoo use now the kernel `sys-kernel/gentoo-kernel` [project](https://wiki.gentoo.org/wiki/Project:Distribution_Kernel), updates are automatic.
* Correct the download of the `rootfs tarball` for VoidLinux.
* ZFS now import pool by ID.
* ZFS use the cmdline `zfs_arc_max` to limit the max Memory used.
* Gentoo and Void use `Dracut`, remove `Genkernel`.
* Gentoo use PAM sha512 with `libpwquality` for the authentication.
* Add the code linter Rubocop, correct around 1.5k lines of code.

## 0.1.6, release 2021-06-30
+ Getch can also install [Void Linux](https://voidlinux.org/).
+ New option `-o|--os NAME`, work only with NAME = gentoo | void.
+ ZFS write the hostid with `zgenhostid $(hostid)`
+ Add a systctl.conf to enforce TCP/IP stack hardened.
+ README improved.
+ More close of the community standard [github](https://github.com/szorfein/getch/community).

## 0.1.4, release 2021-06-20
* Install `iptables` by default.
* Control input for options `--disk`, `--format`, `--zoneinfo`, `--keymap`.
* Add a `/etc/portage/bashrc` to automatically signing kernel modules with `emerge`.
* Now clean properly another disk used with option `--separate-x DISK`.
* For ZFS, use `blockdev --getpbsz` to find correct bloc (sector) size.
* Populate `/etc/modules-load.d/` with modules found with `lsmod` (only few wifi's, flash usb related (ehci, ohci, xhci, etc)).
* Remove the package `dev-util/dwarves`.

## 0.1.3, release 2021-05-17
* LVM use the format /dev/vg_name/lv_name for mount/format/fstab.
* Stop using `euse` from `gentoolkit`, use native Ruby code here.
* Optimization on package installation, they shouln't be installed more than once.
* Regroup use flags under Getch::Gentoo::UseFlag.
* Upd Bask v0.5 (zstd compression, better support for wifi...)
* Config for systemd-resolved, enable DNS over TLS with Quad9 (9.9.9.9)
* Add configs for systemd-network with DHCP for wifi and ethernet.
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
