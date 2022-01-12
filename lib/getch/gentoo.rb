# frozen_string_literal: true

require_relative 'gentoo/stage'
require_relative 'gentoo/config'
require_relative 'gentoo/chroot'
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

      def stage3
        return if STATES[:gentoo_base]

        stage = Getch::Gentoo::Stage.new
        stage.get_stage3
        stage.control_files
        stage.checksum
        @state.stage3
      end

      def config
        return if STATES[:gentoo_config]

        config = Getch::Gentoo::Config.new
        config.portage
        config.portage_fs
        config.portage_bashrc
        config.repo
        config.network
        config.systemd
        config.hostname
        @state.config
      end

      def chroot
        chroot = Getch::Gentoo::Chroot.new
        chroot.update
        chroot.cpuflags
        chroot.systemd

        flags = Getch::Gentoo::UseFlag.new
        flags.apply

        chroot.world
        return if STATES[:gentoo_kernel]

        chroot.kernel
        chroot.kernel_deps
        chroot.install_pkgs
        chroot.kernel_link
      end

      def kernel
        return if STATES[:gentoo_kernel]

        source = Getch::Gentoo::Sources.new
        source.build_kspp
        source.build_others
        source.firewall
        source.make
        @state.kernel
      end

      def boot
        boot = Getch::Gentoo::Boot.new
        boot.start
      end
    end
  end
end
