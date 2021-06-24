require_relative 'void/stage'
require_relative 'void/config'
require_relative 'void/chroot'
require_relative 'void/sources'
require_relative 'void/boot'

module Getch
  module Void
    class Main
      def initialize
        @state = Getch::States.new()
      end

      def root_fs
        return if STATES[:gentoo_base]
        xbps = Getch::Void::RootFS.new
        xbps.search_archive
        xbps.download
        xbps.checksum
        @state.stage3
      end

      def config
        return if STATES[:gentoo_config]
        config = Getch::Void::Config.new
        config.network
        config.system
        config.locale
        config.fstab
        @state.config
      end

      def chroot
        chroot = Getch::Void::Chroot.new
        chroot.update
        return if STATES[:gentoo_kernel]
        chroot.install_grub
      end

      def kernel
        return if STATES[:gentoo_kernel]
        Getch::Void::Sources.new
        @state.kernel
      end

      def boot
        boot = Getch::Void::Boot.new
        boot.start
      end
    end
  end
end
