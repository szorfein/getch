# frozen_string_literal: true

require_relative 'void/config'
require_relative 'void/chroot'
#require_relative 'void/sources'
require_relative 'void/boot'

module Getch
  module Void
    class Main
      def initialize
        @state = Getch::States.new
      end

      def config
        return if STATES[:gentoo_config]

        config = Getch::Void::Config.new
        config.host
        config.network
        config.system
        config.locale
        @state.config
      end

      def chroot
        return if STATES[:gentoo_kernel]

        chroot = Getch::Void::Chroot.new
        chroot.update
        chroot.fs
        chroot.extras
        chroot.install_pkgs
      end

      def kernel
        return if STATES[:gentoo_kernel]

        Getch::Void::Sources.new
        @state.kernel
      end

      def boot
        boot = Getch::Void::Boot.new
        boot.new_user
        boot.fstab
        boot.dracut
        boot.grub
        boot.initramfs
        boot.finish
      end
    end
  end
end

require_relative 'void/tarball'
