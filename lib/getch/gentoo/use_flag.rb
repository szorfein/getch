# frozen_string_literal: true

module Getch
  module Gentoo
    class UseFlag
      def initialize
        x
      end

      protected

      def x
        dist_kernel
        systemd
        pam
        kmod
        grub
        zfs
        lvm
        cryptsetup
      end

      private

      # https://wiki.gentoo.org/wiki/Project:Distribution_Kernel#Trying_it_out
      def dist_kernel
        use = Getch::Gentoo::Use.new
        use.add_global('dist-kernel')
      end

      def systemd
        return unless Helpers.systemd?

        flags = []
        use = Getch::Gentoo::Use.new('sys-apps/systemd')
        flags << 'dns-over-tls'
        flags << 'gnuefi' if Helpers.efi?
        use.add(flags)
      end

      def pam
        flags = []
        use = Getch::Gentoo::Use.new('sys-auth/pambase')
        flags << 'sha512'
        use.add(flags)
      end

      def kmod
        use = Getch::Gentoo::Use.new('sys-apps/kmod')
        use.add('zstd', 'lzma')
      end

      def grub
        flags = []
        use = Getch::Gentoo::Use.new('sys-boot/grub')
        flags << '-grub_platforms_efi-64' unless Helpers.efi?
        flags << 'libzfs' if OPTIONS[:fs] == 'zfs'
        flags << 'device-mapper' if OPTIONS[:fs] == 'lvm' or OPTIONS[:encrypt]
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
end
