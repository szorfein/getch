require 'open-uri'
require 'open3'
require_relative 'gentoo/stage'
require_relative 'gentoo/config'
require_relative 'gentoo/chroot'

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
        @state.config
      end

      def chroot
        chroot = Getch::Gentoo::Chroot.new()
        chroot.update
        chroot.world
        chroot.systemd
        chroot.kernel
      end
    end
  end
end
