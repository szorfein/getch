require 'open-uri'
require 'open3'
require_relative 'gentoo/stage'
require_relative 'gentoo/config'
require_relative 'gentoo/chroot'
require_relative 'gentoo/sources'
require_relative 'gentoo/boot'

module Getch
  module Gentoo
    class << self
      def new
        @state = Getch::States.new()
      end

      def stage3
        return if STATES[:gentoo_base]
        new
        stage = Getch::Gentoo::Stage.new()
        stage.get_stage3
        stage.control_files
        stage.checksum
        @state.stage3
      end

      def config(options)
        return if STATES[:gentoo_config]
        new
        config = Getch::Gentoo::Config.new()
        config.portage
        config.portage_fs
        config.repo
        config.network
        config.systemd(options)
        config.hostname
        @state.config
      end

      def chroot
        chroot = Getch::Gentoo::Chroot.new()
        chroot.update
        chroot.systemd
        chroot.world
        return if STATES[:gentoo_kernel]
        chroot.kernel
        chroot.kernel_deps
        chroot.install_pkgs
      end

      def kernel
        return if STATES[:gentoo_kernel]
        source = Getch::Gentoo::Sources.new()
        new
        source.build_kspp
        source.init_config
        source.build_others
        source.make
        @state.kernel
      end

      def boot(options)
        boot = Getch::Gentoo::Boot.new(options)
        boot.start
      end
    end
  end
end
