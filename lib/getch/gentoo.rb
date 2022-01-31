# frozen_string_literal: true

require_relative 'gentoo/chroot'
require_relative 'gentoo/bootloader'
require_relative 'gentoo/sources'
require_relative 'gentoo/boot'
require_relative 'gentoo/use'
require_relative 'gentoo/use_flag'

module Getch
  module Gentoo
    class Main
      def initialize
        @state = Getch::States.new
      end

      def config
        return if STATES[:gentoo_config]

        config = Getch::Gentoo::Config.new
        config.portage_bashrc
        config.systemd
        @state.config
      end

      def chroot
        return if STATES[:gentoo_update]

        chroot = Getch::Gentoo::Chroot.new
        chroot.update
        chroot.cpuflags
        chroot.systemd

        flags = Getch::Gentoo::UseFlag.new
        flags.apply

        chroot.world
        chroot.kernel_license
        chroot.install_pkgs
        @state.update
      end

      def bootloader
        return if STATES[:gentoo_bootloader]

        bootloader = Getch::Gentoo::Bootloader.new
        bootloader.start
        @state.bootloader
      end

      def kernel
        return if STATES[:gentoo_kernel]

        source = Getch::Gentoo::Sources.new
        source.bask
        source.configs
        source.make
        source.load_modules
        @state.kernel
      end

      def boot
        boot = Getch::Gentoo::Boot.new
        boot.start
      end
    end
  end
end

require_relative 'gentoo/tarball'
require_relative 'gentoo/pre_config'
require_relative 'gentoo/update'
require_relative 'gentoo/post_config'
