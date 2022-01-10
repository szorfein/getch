# lib/use_flag.rb

module Getch::Gentoo
  class UseFlag
    def initialize
      @efi = Helpers::efi?
    end

    def apply
      systemd
      pam
      kmod
      grub
      zfs
      lvm
      cryptsetup
    end

    private

    def systemd
      flags = []
      use = Getch::Gentoo::Use.new('sys-apps/systemd')
      flags << 'dns-over-tls'
      flags << 'gnuefi' if @efi
      use.add(flags)
    end

    def pam
      flags = []
      use = Getch::Gentoo::Use.new('sys-auth/pambase')
      flags << '-passwdqc'
      flags << 'pwquality'
      flags << 'sha512'
      use.add(flags)
    end

    def kmod
      use = Getch::Gentoo::Use.new('sys-apps/kmod')
      use.add('zstd', 'lzma')
    end

    def grub
      return if @efi
      flags = []
      use = Getch::Gentoo::Use.new('sys-boot/grub')
      flags << '-grub_platforms_efi-64'
      flags << 'libzfs' if Getch::OPTIONS[:fs] == 'zfs'
      flags << 'device-mapper' if Getch::OPTIONS[:fs] == 'lvm'
      use.add(flags)
    end

    def zfs
      return unless Getch::OPTIONS[:fs] == 'zfs'
      use = Getch::Gentoo::Use.new('sys-fs/zfs-kmod')
      use.add('rootfs')
      use = Getch::Gentoo::Use.new('sys-fs/zfs')
      use.add('rootfs')
    end

    def lvm
      return unless Getch::OPTIONS[:fs] == 'lvm'
      use = Getch::Gentoo::Use.new
      use.add_global('lvm', 'device-mapper')
    end

    def cryptsetup
      return unless Getch::OPTIONS[:encrypt]
      use = Getch::Gentoo::Use.new
      use.add_global('cryptsetup')
    end
  end
end
